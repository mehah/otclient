/*
 * Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
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

#include "protocollogin.h"
#include <framework/net/outputmessage.h>
#include <framework/util/crypt.h>

void ProtocolLogin::sendLoginPacket() {
  if(Wrapper_ptr wrapper = getConnection()->getOutputWrapper()) {
    // Login packet has no XTEA Encryption
    wrapper->disableEncryption();
    wrapper->setProtocolType(protocolType);

    flatbuffers::FlatBufferBuilder &fbb = wrapper->Builder();
    auto account_name = fbb.CreateString(account);
    auto auth_token = fbb.CreateString(authToken);
    auto pass = fbb.CreateString(password);
    auto xtea_key = fbb.CreateVector(generateXteaKey());

    CanaryLib::LoginInfoBuilder login_info_builder(fbb);
    login_info_builder.add_account(account_name);
    login_info_builder.add_auth_token(auth_token);
    login_info_builder.add_password(pass);
    login_info_builder.add_xtea_key(xtea_key);
    fbb.Finish(login_info_builder.Finish());

    auto releasedMsg = fbb.Release();
    auto content_size = releasedMsg.size() + sizeof(uint8_t);

    uint8_t buffer[g_crypt.rsaGetSize()];
    uint8_t padding = g_crypt.rsaGetSize() - content_size;

    uint8_t byte = 0x00;
    memcpy(buffer, &byte, 1);
    memcpy(buffer + sizeof(uint8_t), releasedMsg.data(), releasedMsg.size());
    memcpy(buffer + content_size, &byte, padding);

    uint8_t final_size = content_size + padding;
    assert(final_size == g_crypt.rsaGetSize());
    g_crypt.rsaEncrypt(buffer, final_size);

    auto enc_buffer = fbb.CreateVector(buffer, final_size);

    auto login_data = CanaryLib::CreateLoginData(fbb, enc_buffer, CanaryLib::Client_t_CANARY);
    fbb.Finish(login_data);

    wrapper->add(login_data.Union(), CanaryLib::DataType_LoginData);

    getConnection()->onCanWrite();
  }
  recv();
}

void ProtocolLogin::parseCharacterList(const CanaryLib::CharactersListData *characters) {
  Protocol::parseCharacterList(characters);
  callLuaField("onMotd", characters->motd()->str());

  auto account = characters->account();
  callLuaField("onSessionKey", account->session_key()->str());

  std::vector<const CanaryLib::CharacterInfo *> charList;
  for (int i = 0; i < characters->characters()->size(); i++) {
    charList.emplace_back(characters->characters()->Get(i));
    auto c = characters->characters()->Get(i);
  }
  callLuaField("onCharacterList", charList, characters->world(), account);

  disconnect();
}

void ProtocolLogin::parseError(const CanaryLib::ErrorData *err) {
  callLuaField("onLoginError", err->message()->str());
  Protocol::parseError(err);
}

void ProtocolLogin::onConnect()
{
  Protocol::onConnect();
  sendLoginPacket();
}
