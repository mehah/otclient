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

function ProtocolLogin:onError(msg, code)
  local text = translateNetworkError(code, self:isConnecting(), msg)
  signalcall(self.onLoginError, self, text)
end
