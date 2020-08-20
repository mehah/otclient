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
  OutputMessagePtr msg = OutputMessagePtr(new OutputMessage);
  msg->writeByte(CanaryLib::ClientEnterAccount);

  // first RSA byte must be 0
  int offset = msg->getLength();
  msg->writeByte(0);

  std::vector<uint32_t> key = generateXteaKey();
  msg->write<uint32_t>(key[0]);
  msg->write<uint32_t>(key[1]);
  msg->write<uint32_t>(key[2]);
  msg->write<uint32_t>(key[3]);

  msg->writeString(account);
  msg->writeString(password);

  int paddingBytes = g_crypt.rsaGetSize() - (msg->getLength() - offset);
  msg->writePaddingBytes(paddingBytes);
  msg->encryptRsa();

spdlog::critical("{}", msg->getLength());
  send(msg, true);
  recv();
}

void ProtocolLogin::onRecv(const InputMessagePtr& msg) {}

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
