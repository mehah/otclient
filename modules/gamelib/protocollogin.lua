-- @docclass
ProtocolLogin = extends(ProtocolLogin, "ProtocolLogin")

function ProtocolLogin:login(host, port, accountName, accountPassword, authenticatorToken, stayLogged)
  if string.len(host) == 0 or port == nil or port == 0 then
    signalcall(self.onLoginError, self, tr("You must enter a valid server address and port."))
    return
  end

  self:setAccount(accountName)
  self:setPassword(accountPassword)
  self:setAuthToken(authenticatorToken)
  self:setStayLogged(stayLogged)

  self:connect(host, port)
end

function ProtocolLogin:cancelLogin()
  self:disconnect()
end

function ProtocolLogin:onConnect()
  self.gotConnection = true
  self:sendLoginPacket()
  self.connectCallback = nil
end

function ProtocolLogin:parseCharacterList(characters, world, account)
  signalcall(self.onCharacterList, self, characters, world, account, otui)
end

function ProtocolLogin:parseMotd(motd)
  signalcall(self.onMotd, self, motd)
end

function ProtocolLogin:parseSessionKey(msg)
  local sessionKey = msg:getString()
  signalcall(self.onSessionKey, self, sessionKey)
end

function ProtocolLogin:parseOpcode(opcode, msg)
  signalcall(self.onOpcode, self, opcode, msg)
end

function ProtocolLogin:onError(msg, code)
  local text = translateNetworkError(code, self:isConnecting(), msg)
  signalcall(self.onLoginError, self, text)
end
