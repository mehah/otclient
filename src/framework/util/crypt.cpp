/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "crypt.h"
#include "framework/core/application.h"
#include <framework/core/logger.h>
#include <framework/core/resourcemanager.h>
#include <framework/platform/platform.h>
#include <framework/stdext/math.h>

#ifndef USE_GMP
#include <openssl/bn.h>
#include <openssl/err.h>
#include <openssl/rsa.h>
#endif
#include <zlib.h>

#include <algorithm>

#include "framework/core/graphicalapplication.h"
#include <openssl/sha.h>

static constexpr std::string_view base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static inline bool is_base64(const uint8_t c) { return (isalnum(c) || (c == '+') || (c == '/')); }

Crypt g_crypt;

Crypt::Crypt()
{
#ifdef USE_GMP
    mpz_init(m_p);
    mpz_init(m_q);
    mpz_init(m_d);
    mpz_init(m_e);
    mpz_init(m_n);
#else
    m_rsa = RSA_new();
#endif
}

Crypt::~Crypt()
{
#ifdef USE_GMP
    mpz_clear(m_p);
    mpz_clear(m_q);
    mpz_clear(m_n);
    mpz_clear(m_d);
    mpz_clear(m_e);
#else
    RSA_free(m_rsa);
#endif
}

std::string Crypt::base64Encode(const std::string& decoded_string) {
    size_t encoded_size = 4 * ((decoded_string.size() + 2) / 3);
    std::string ret;
    ret.reserve(encoded_size);

    int val = 0, valb = -6;
    for (uint8_t c : decoded_string) {
        val = (val << 8) + c;
        valb += 8;
        while (valb >= 0) {
            ret.push_back(base64_chars[(val >> valb) & 0x3F]);
            valb -= 6;
        }
    }

    while (valb > -6) {
        ret.push_back(base64_chars[((val << 8) >> (valb + 8)) & 0x3F]);
        valb -= 6;
    }

    while (ret.size() % 4) ret.push_back('=');
    return ret;
}

std::string Crypt::base64Decode(const std::string_view& encoded_string) {
    std::vector<int> T(256, -1);
    for (int i = 0; i < 64; i++) T[base64_chars[i]] = i;

    std::string ret;
    ret.reserve(encoded_string.size() * 3 / 4);

    int val = 0, valb = -8;
    for (uint8_t c : encoded_string) {
        if (T[c] == -1) break;
        val = (val << 6) + T[c];
        valb += 6;
        if (valb >= 0) {
            ret.push_back((val >> valb) & 0xFF);
            valb -= 8;
        }
    }
    return ret;
}

std::string Crypt::xorCrypt(const std::string& buffer, const std::string& key) {
    if (key.empty()) return buffer;

    std::string out(buffer);
    size_t keySize = key.size();

    std::transform(out.begin(), out.end(), out.begin(),
                   [&](char c) { return c ^ key[(&c - &out[0]) % keySize]; });

    return out;
}

std::string Crypt::genUUID() {
    return uuids::to_string(uuids::uuid_random_generator{ stdext::random_gen() }());
}

bool Crypt::setMachineUUID(std::string uuidstr)
{
    if (uuidstr.empty())
        return false;

    uuidstr = _decrypt(uuidstr, false);

    if (uuidstr.length() != 36)
        return false;

    m_machineUUID = uuids::uuid::from_string(uuidstr).value();

    return true;
}

std::string Crypt::getMachineUUID()
{
    if (m_machineUUID.is_nil()) {
        m_machineUUID = uuids::uuid_random_generator{ stdext::random_gen() }();
    }
    return _encrypt(uuids::to_string(m_machineUUID), false);
}

std::string Crypt::getCryptKey(const bool useMachineUUID) const
{
    static const uuids::uuid default_uuid{};
    const uuids::uuid& uuid = useMachineUUID ? m_machineUUID : default_uuid;

    const uuids::uuid u = uuids::uuid_name_generator(uuid)(
        g_app.getCompactName() + g_platform.getCPUName() + g_platform.getOSName() + g_resources.getUserDir()
    );

    const std::size_t hash = std::hash<uuids::uuid>{}(u);

    return std::string(reinterpret_cast<const char*>(&hash), sizeof(hash));
}

std::string Crypt::_encrypt(const std::string& decrypted_string, const bool useMachineUUID)
{
    uint32_t sum = stdext::adler32(reinterpret_cast<const uint8_t*>(decrypted_string.data()), decrypted_string.size());

    std::string tmp;
    tmp.reserve(4 + decrypted_string.size());

    tmp.append(4, '\0'); 
    tmp.append(decrypted_string);

    stdext::writeULE32(reinterpret_cast<uint8_t*>(&tmp[0]), sum);

    return base64Encode(xorCrypt(tmp, getCryptKey(useMachineUUID)));
}

std::string Crypt::_decrypt(const std::string& encrypted_string, const bool useMachineUUID)
{
    std::string decoded = base64Decode(encrypted_string);
    std::string tmp = xorCrypt(decoded, getCryptKey(useMachineUUID));

    if (tmp.size() < 4)
        return {};

    uint32_t readsum = stdext::readULE32(reinterpret_cast<const uint8_t*>(tmp.data()));

    std::string decrypted_string = tmp.substr(4);

    uint32_t sum = stdext::adler32(reinterpret_cast<const uint8_t*>(decrypted_string.data()), decrypted_string.size());

    return (readsum == sum) ? decrypted_string : std::string();
}

void Crypt::rsaSetPublicKey(const std::string& n, const std::string& e)
{
#ifdef USE_GMP
    mpz_set_str(m_n, n.c_str(), 10);
    mpz_set_str(m_e, e.c_str(), 10);
#else
    BIGNUM* bn = nullptr, * be = nullptr;
    BN_dec2bn(&bn, n.c_str());
    BN_dec2bn(&be, e.c_str());
    RSA_set0_key(m_rsa, bn, be, nullptr);
#endif
}

void Crypt::rsaSetPrivateKey(const std::string& p, const std::string& q, const std::string& d)
{
#ifdef USE_GMP
    mpz_set_str(m_p, p, 10);
    mpz_set_str(m_q, q, 10);
    mpz_set_str(m_d, d, 10);

    // n = p * q
    mpz_mul(m_n, m_p, m_q);
#else
#if OPENSSL_VERSION_NUMBER < 0x10100005L
    BN_dec2bn(&m_rsa->p, p);
    BN_dec2bn(&m_rsa->q, q);
    BN_dec2bn(&m_rsa->d, d);
    // clear rsa cache
    if (m_rsa->_method_mod_p) {
        BN_MONT_CTX_free(m_rsa->_method_mod_p);
        m_rsa->_method_mod_p = nullptr;
    }
    if (m_rsa->_method_mod_q) {
        BN_MONT_CTX_free(m_rsa->_method_mod_q);
        m_rsa->_method_mod_q = nullptr;
    }
#else
    BIGNUM* bp = nullptr, * bq = nullptr, * bd = nullptr;
    BN_dec2bn(&bp, p.c_str());
    BN_dec2bn(&bq, q.c_str());
    BN_dec2bn(&bd, d.c_str());
    RSA_set0_key(m_rsa, nullptr, nullptr, bd);
    RSA_set0_factors(m_rsa, bp, bq);
#endif
#endif
}

bool Crypt::rsaEncrypt(uint8_t* msg, int size)
{
    if (size != rsaGetSize())
        return false;

#ifdef USE_GMP
    mpz_t c, m;
    mpz_init(c);
    mpz_init(m);
    mpz_import(m, size, 1, 1, 0, 0, msg);

    // c = m^e mod n
    mpz_powm(c, m, m_e, m_n);

    size_t count = (mpz_sizeinbase(m, 2) + 7) / 8;
    memset((char*)msg, 0, size - count);
    mpz_export((char*)msg + (size - count), nullptr, 1, 1, 0, 0, c);

    mpz_clear(c);
    mpz_clear(m);

    return true;
#else
    return RSA_public_encrypt(size, msg, msg, m_rsa, RSA_NO_PADDING) != -1;
#endif
}

bool Crypt::rsaDecrypt(uint8_t* msg, int size)
{
    if (size != rsaGetSize())
        return false;

#ifdef USE_GMP
    mpz_t c, m;
    mpz_init(c);
    mpz_init(m);
    mpz_import(c, size, 1, 1, 0, 0, msg);

    // m = c^d mod n
    mpz_powm(m, c, m_d, m_n);

    size_t count = (mpz_sizeinbase(m, 2) + 7) / 8;
    memset((char*)msg, 0, size - count);
    mpz_export((char*)msg + (size - count), nullptr, 1, 1, 0, 0, m);

    mpz_clear(c);
    mpz_clear(m);

    return true;
#else
    return RSA_private_decrypt(size, msg, msg, m_rsa, RSA_NO_PADDING) != -1;
#endif
}

int Crypt::rsaGetSize()
{
#ifdef USE_GMP
    size_t count = (mpz_sizeinbase(m_n, 2) + 7) / 8;
    return ((int)count / 128) * 128;
#else
    return RSA_size(m_rsa);
#endif
}

std::string Crypt::crc32(const std::string& decoded_string, const bool upperCase)
{
    uint32_t crc = ::crc32(0, nullptr, 0);
    crc = ::crc32(crc, (const Bytef*)decoded_string.c_str(), decoded_string.size());
    std::string result = stdext::dec_to_hex(crc);
    if (upperCase)
        std::ranges::transform(result, result.begin(), toupper);
    else
        std::ranges::transform(result, result.begin(), tolower);
    return result;
}

// NOSONAR - Intentional use of SHA-1 as there is no security impact in this context
std::string Crypt::sha1Encrypt(const std::string& input) {
    unsigned char hash[SHA_DIGEST_LENGTH];
    SHA1(reinterpret_cast<const unsigned char*>(input.data()), input.size(), hash);

    std::ostringstream oss;
    for (unsigned char byte : hash)
        oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(byte);

    return oss.str();
}

void Crypt::sha1Block(const uint8_t* block, uint32_t* H)
{
    uint32_t W[80];
    for (int i = 0; i < 16; ++i) {
        const size_t offset = i << 2;
        W[i] = block[offset] << 24 | block[offset + 1] << 16 | block[offset + 2] << 8 | block[offset + 3];
    }

    for (int i = 16; i < 80; ++i) {
        W[i] = stdext::circularShift(1, W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16]);
    }

    uint32_t A = H[0], B = H[1], C = H[2], D = H[3], E = H[4];

    for (int i = 0; i < 20; ++i) {
        const uint32_t tmp = stdext::circularShift(5, A) + ((B & C) | ((~B) & D)) + E + W[i] + 0x5A827999;
        E = D; D = C; C = stdext::circularShift(30, B); B = A; A = tmp;
    }

    for (int i = 20; i < 40; ++i) {
        const uint32_t tmp = stdext::circularShift(5, A) + (B ^ C ^ D) + E + W[i] + 0x6ED9EBA1;
        E = D; D = C; C = stdext::circularShift(30, B); B = A; A = tmp;
    }

    for (int i = 40; i < 60; ++i) {
        const uint32_t tmp = stdext::circularShift(5, A) + ((B & C) | (B & D) | (C & D)) + E + W[i] + 0x8F1BBCDC;
        E = D; D = C; C = stdext::circularShift(30, B); B = A; A = tmp;
    }

    for (int i = 60; i < 80; ++i) {
        const uint32_t tmp = stdext::circularShift(5, A) + (B ^ C ^ D) + E + W[i] + 0xCA62C1D6;
        E = D; D = C; C = stdext::circularShift(30, B); B = A; A = tmp;
    }

    H[0] += A;
    H[1] += B;
    H[2] += C;
    H[3] += D;
    H[4] += E;
}