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

function ProtocolLogin:parseError(errorMessage)
  signalcall(self.onLoginError, self, errorMessage)
end

function ProtocolLogin:parseMotd(motd)
  signalcall(self.onMotd, self, motd)
end

function ProtocolLogin:parseSessionKey(msg)
  local sessionKey = msg:getString()
  signalcall(self.onSessionKey, self, sessionKey)
end

function ProtocolLogin:parseCharacterList(msg)
  local characters = {}

  local worlds = {}

  local worldsCount = msg:getU8()
  for i=1, worldsCount do
    local world = {}
    local worldId = msg:getU8()
    world.worldName = msg:getString()
    world.worldIp = msg:getString()
    world.worldPort = msg:getU16()
    world.previewState = msg:getU8()
    worlds[worldId] = world
  end

  local charactersCount = msg:getU8()
  for i=1, charactersCount do
    local character = {}
    local worldId = msg:getU8()
    character.name = msg:getString()
    character.worldName = worlds[worldId].worldName
    character.worldIp = worlds[worldId].worldIp
    character.worldPort = worlds[worldId].worldPort
    character.previewState = worlds[worldId].previewState
    characters[i] = character
  end

  local account = {}
  account.status = msg:getU8()
  account.subStatus = msg:getU8()

  account.premDays = msg:getU32()
  if account.premDays ~= 0 and account.premDays ~= 65535 then
    account.premDays = math.floor((account.premDays - os.time()) / 86400)
  end

  signalcall(self.onCharacterList, self, characters, account)
end

function ProtocolLogin:parseExtendedCharacterList(msg)
  local characters = msg:getTable()
  local account = msg:getTable()
  local otui = msg:getString()
  signalcall(self.onCharacterList, self, characters, account, otui)
end

function ProtocolLogin:parseOpcode(opcode, msg)
  signalcall(self.onOpcode, self, opcode, msg)
end

function ProtocolLogin:onError(msg, code)
  local text = translateNetworkError(code, self:isConnecting(), msg)
  signalcall(self.onLoginError, self, text)
end
