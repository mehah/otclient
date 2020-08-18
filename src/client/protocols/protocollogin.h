/**
 * Canary Lib - Canary Project a free 2D game platform
 * Copyright (C) 2020  Lucas Grossi <lucas.ggrossi@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef PROTOCOLS_PROTOCOLLOGIN_H
#define PROTOCOLS_PROTOCOLLOGIN_H

#include <framework/net/protocol.h>
#include "../global.h"

class ProtocolLogin : public Protocol
{
  public:
    void setAccount(const std::string& accountName) {
      account = accountName;
    }
    void setPassword(const std::string& pass) {
      password = pass;
    }
    void setAuthToken(const std::string& token) {
      authToken = token;
    }
    void setStayLogged(bool logged) {
      stayLogged = logged;
    }
    void sendLoginPacket();
    void onRecv(const InputMessagePtr& inputMessage) override;
    virtual void onMessageError(const CanaryLib::ErrorData *err) override;
    
  private:
    std::string account;
    std::string password;
    std::string authToken;
    bool stayLogged;
};

#endif
