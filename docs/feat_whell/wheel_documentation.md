# 📘 Wheel of Destiny – Integração C++ ↔ Lua

Este documento resume todas as implementações feitas no **cliente (OTClient 15.11)** e a comunicação com o **servidor (Canary)** para o sistema **Wheel of Destiny** incluindo **ações de gemas**.

---

## 🔗 Binds Criados

### 1. `g_game.openWheel(playerId)`

* **Direção:** Cliente → Servidor
* **Opcode enviado:** `0x61` (`ClientOpenWheel = 97`)
* **Função C++ (game.cpp):**

```cpp
void Game::openWheel(uint32_t playerId)
{
    if (m_protocolGame)
        m_protocolGame->sendOpenWheel(playerId);
}
```

* **Função C++ (protocolgamesend.cpp):**

```cpp
void ProtocolGame::sendOpenWheel(uint32_t playerId) {  
    const auto& msg = std::make_shared<OutputMessage>();  
    msg->addU8(Proto::ClientOpenWheel); // 0x61  
    msg->addU32(playerId); // Adicionar o ID do jogador  
    send(msg);  
}
```

* **Uso no Lua: wheel.lua**

```lua
function show()
  g_game.openWheel(g_game.getLocalPlayer():getId())
end
show()
```

Solicita ao servidor a abertura da roda.

---

### 2. `g_game.sendApplyWheelPoints(slotPoints, greenGem, redGem, acquaGem, purpleGem)`

* **Direção:** Cliente → Servidor
* **Opcode enviado:** `0x62` (`ClientSaveWheel = 98`)
* **Função C++ (game.cpp):**

```cpp
void Game::sendApplyWheelPoints(const std::vector<uint16_t>& slotPoints,
                     uint16_t greenGem,
                     uint16_t redGem,
                     uint16_t acquaGem,
                     uint16_t purpleGem) {
    if (m_protocolGame)
        m_protocolGame->sendApplyWheelPoints(slotPoints, greenGem, redGem, acquaGem, purpleGem);
}
```

* **Função C++ (protocolgamesend.cpp):**

```cpp
void ProtocolGame::sendApplyWheelPoints(const std::vector<uint16_t>& slotPoints,
                                        uint16_t greenGem, uint16_t redGem,
                                        uint16_t acquaGem, uint16_t purpleGem)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientSaveWheel); // 0x62 (ClientSaveWheel)
    g_logger.debug("[Wheel C++ Send] sendApplyWheelPoints iniciado");


    // Envia pontos por slot (36 slots válidos)
    for (int i = 0; i < 36; ++i) {
        uint16_t value = (i < static_cast<int>(slotPoints.size())) ? slotPoints[i] : 0;
        msg->addU16(value);
        g_logger.debug(fmt::format("  [Slot {:02d}] pontos={}", i, value));
    }

    // Gem Green
    msg->addU8(greenGem != UINT16_MAX ? 1 : 0);
    if (greenGem != UINT16_MAX) msg->addU16(greenGem);
    g_logger.debug(fmt::format("[Gem Green C++] hasGem={} gemId={}", greenGem != UINT16_MAX, greenGem));

    // Gem Red
    msg->addU8(redGem != UINT16_MAX ? 1 : 0);
    if (redGem != UINT16_MAX) msg->addU16(redGem);
    g_logger.debug(fmt::format("[Gem Red C++] hasGem={} gemId={}", redGem != UINT16_MAX, redGem));

    // Gem Acqua
    msg->addU8(acquaGem != UINT16_MAX ? 1 : 0);
    if (acquaGem != UINT16_MAX) msg->addU16(acquaGem);
    g_logger.debug(fmt::format("[Gem Acqua C++] hasGem={} gemId={}", acquaGem != UINT16_MAX, acquaGem));

    // Gem Purple
    msg->addU8(purpleGem != UINT16_MAX ? 1 : 0);
    if (purpleGem != UINT16_MAX) msg->addU16(purpleGem);
    g_logger.debug(fmt::format("[Gem Purple C++] hasGem={} gemId={}", purpleGem != UINT16_MAX, purpleGem));
    
    msg->addU8(0);
    g_logger.debug(fmt::format(
        "[Wheel C++ Send] Enviando apply: {} slots, gems(G={} R={} A={} P={})",
        slotPoints.size(), greenGem, redGem, acquaGem, purpleGem));

    g_logger.debug("[Wheel C++ Send] Enviando pacote de ApplyWheelPoints...");
    std::ostringstream oss;
    const auto& buffer = msg->getBuffer();
    const size_t length = msg->getMessageSize(); // ✅ usa o método existente
    for (size_t i = 0; i < length; ++i) {
        oss << fmt::format("{:02X} ", static_cast<uint8_t>(buffer[i]));
    }
    g_logger.debug(fmt::format("[WheelDebugHex] Pacote completo ({} bytes): {}", length, oss.str()));
    send(msg);
    g_logger.debug("[Wheel C++ Send] Pacote enviado com sucesso.");
}
```

* **Uso no Lua: wheelclass.lua**

```lua
function onWheelOfDestinyApply(close, ignoreprotocol)
  local struct = getGemStruct()
  g_logger.debug("[WheelApply] Executado onWheelOfDestinyApply")

  if not ignoreprotocol then
    local g = struct[GemDomains.GREEN].gemID or 0
    local r = struct[GemDomains.RED].gemID or 0
    local a = struct[GemDomains.ACQUA].gemID or 0
    local p = struct[GemDomains.PURPLE].gemID or 0
  
    WheelOfDestiny.currentPreset.equipedGems = struct
  
    g_logger.debug(string.format(
      "[WheelApply] Enviando gems -> GREEN:%d  RED:%d  ACQUA:%d  PURPLE:%d",
      g, r, a, p))
  
    g_game.sendApplyWheelPoints(WheelOfDestiny.pointInvested, g, r, a, p)
  end

  if close then
    scheduleEvent(function()
      wheelWindow:hide()
      wheelWindow:ungrabMouse()
      wheelWindow:ungrabKeyboard()
    end, 100)
  end
```

📌 **Resumo:** O cliente sempre envia os **37 slots** com pontos investidos e as **4 gemas ativas**.

---

### 3. `g_game.onDestinyWheel(playerId, canView, changeState, vocationId, points, scrollPoints, pointInvested, usedPromotionScrolls, equipedGems, atelierGems, basicUpgraded, supremeUpgraded, earnedFromAchievements)`

* **Direção:** Servidor → Cliente
* **Opcode recebido:** `0x5F` (`GameServerOpenWheelWindow = 95`)
* **Função C++ (protocolgameparse.cpp):**

```cpp

// 0x5F - parse destiny wheel window
void ProtocolGame::parseOpenWheelWindow(const InputMessagePtr& msg)
{
    // Player ID
    uint32_t playerId = msg->getU32();
    g_logger.debug(fmt::format("[Wheel C++ Parse] parseOpenWheelWindow -> playerId={}", playerId));

    // CanView
    uint8_t canView = msg->getU8();
    g_logger.debug(fmt::format("[Wheel C++ Parse] canView={}", static_cast<int>(canView)));

    // Se não pode visualizar, encerra e dispara callback "vazio"
    if (!canView) {
        g_logger.debug("[Wheel C++ Parse] Player não pode abrir a Wheel of Destiny.");
        g_lua.callGlobalField("WheelOfDestiny", "onDestinyWheel",
            playerId, canView, 0, 0, 0, 0,
            std::vector<uint16_t>(), std::vector<uint16_t>(),
            std::vector<uint16_t>(), std::vector<GemData>(),
            std::map<uint8_t, uint8_t>(), std::map<uint8_t, uint8_t>(), 0);
        return;
    }

    // Estado de mudança + vocation
    uint8_t changeState = msg->getU8();
    uint8_t vocationId = msg->getU8();
    g_logger.debug(fmt::format("[Wheel C++ Parse] changeState={} vocationId={}",
        static_cast<int>(changeState), static_cast<int>(vocationId)));

    // Pontos
    uint16_t points = msg->getU16();
    uint16_t extraPoints = msg->getU16();

    g_logger.debug(fmt::format("[Wheel C++ Parse] points={} extraPoints={}",
        static_cast<int>(points),
        static_cast<int>(extraPoints)));

    // Points por slot (37 slots fixos, igual ao servidor de 0 a 36)
    std::vector<uint16_t> pointInvested;
    pointInvested.reserve(36);

    for (int i = 0; i < 36; ++i) {
        uint16_t slotPoints = msg->getU16();
        pointInvested.push_back(slotPoints);
    }

    g_logger.debug(fmt::format("[Wheel C++ Parse] pointInvested ({} slots)", static_cast<int>(pointInvested.size())));

    // Log detalhado de cada slot
    for (int i = 0; i < static_cast<int>(pointInvested.size()); ++i) {
        g_logger.debug(fmt::format("  [Slot {:>2}] points={}", i, pointInvested[i]));
    }

    // Promotion scrolls
    std::vector<uint16_t> usedPromotionScrolls;
    uint16_t scrollCount = msg->getU16();
    g_logger.debug(fmt::format("[Wheel C++ Parse] scrollCount={}", static_cast<int>(scrollCount)));

    for (uint16_t i = 0; i < scrollCount; ++i) {
        uint16_t itemId = msg->getU16();
        // Em protocolos 1500+ o servidor envia 1 byte extra (extraPoints)
        uint8_t extraPoints = 0;
        if (g_game.getProtocolVersion() >= 1500 && msg->getUnreadSize() > 0) {
            extraPoints = msg->getU8();
        }
        usedPromotionScrolls.push_back(itemId);

        g_logger.debug(fmt::format("  [Scroll {}] id={} extraPoints={}",
            static_cast<int>(i),
            static_cast<int>(itemId),
            static_cast<int>(extraPoints)));
    }

    uint8_t hasMonkQuest = 0;
    if (g_game.getProtocolVersion() >= 1500 && msg->getUnreadSize() > 0) {
        hasMonkQuest = msg->getU8();
        g_logger.debug(fmt::format("[Wheel C++ Parse] hasMonkQuest lido (valor={})", static_cast<int>(hasMonkQuest)));
    }

    // Gems ativas (equipadas)
    std::vector<uint16_t> equipedGems;
    uint8_t activeGemCount = msg->getU8();
    g_logger.debug(fmt::format("[Wheel C++ Parse] activeGemCount={}", static_cast<int>(activeGemCount)));
    for (uint8_t i = 0; i < activeGemCount; ++i) {
        uint16_t gemIndex = msg->getU16();
        equipedGems.push_back(gemIndex);
        g_logger.debug(fmt::format("  [ActiveGem {}] index={}", static_cast<int>(i), static_cast<int>(gemIndex)));
    }

    // Gems reveladas (atelier)
    std::vector<GemData> atelierGems;
    uint16_t revealedCount = msg->getU16();
    g_logger.debug(fmt::format("[Wheel C++ Parse] revealedGemCount={}", static_cast<int>(revealedCount)));

    for (uint16_t i = 0; i < revealedCount; ++i) {
        GemData gem;
        gem.gemID = msg->getU16();          // ID único da gema
        gem.locked = msg->getU8();          // Status bloqueada/desbloqueada
        gem.gemDomain = msg->getU8();       // Afinidade elemental
        gem.gemType = msg->getU8();         // Qualidade (Lesser, Regular, Greater, Supreme)
        gem.lesserBonus = msg->getU8();     // Primeiro modificador

        if (gem.gemType >= Otc::WheelGemQuality_Regular)
            gem.regularBonus = msg->getU8();
        if (gem.gemType >= Otc::WheelGemQuality_Greater)
            gem.supremeBonus = msg->getU8();

        atelierGems.push_back(gem);

        g_logger.debug(fmt::format(
            "  [RevealedGem {:02}] id={} locked={} domain={} type={} lesser={} regular={} supreme={}",
            static_cast<int>(i),
            static_cast<int>(gem.gemID),
            static_cast<int>(gem.locked),
            static_cast<int>(gem.gemDomain),
            static_cast<int>(gem.gemType),
            static_cast<int>(gem.lesserBonus),
            static_cast<int>(gem.regularBonus),
            static_cast<int>(gem.supremeBonus)
        ));
    }

    // Basic upgrades
    std::map<uint8_t, uint8_t> basicUpgraded;
    uint8_t basicCount = msg->getU8(); // geralmente 0x2E (46)
    g_logger.debug(fmt::format("[Wheel C++ Parse] basicUpgraded count={}", static_cast<int>(basicCount)));
    for (uint8_t i = 0; i < basicCount; ++i) {
        uint8_t pos = msg->getU8();
        uint8_t val = msg->getU8();
        basicUpgraded[pos] = val;
        g_logger.debug(fmt::format("  [BasicUpgrade {}] pos={} val={}",
            static_cast<int>(i), static_cast<int>(pos), static_cast<int>(val)));
    }

    // Supreme upgrades
    std::map<uint8_t, uint8_t> supremeUpgraded;
    uint8_t supCount = msg->getU8(); // geralmente 0x17 (23)
    g_logger.debug(fmt::format("[Wheel C++ Parse] supremeUpgraded count={}", static_cast<int>(supCount)));
    for (uint8_t i = 0; i < supCount; ++i) {
        uint8_t pos = msg->getU8();
        uint8_t val = msg->getU8();
        supremeUpgraded[pos] = val;
        g_logger.debug(fmt::format("  [SupremeUpgrade {}] pos={} val={}",
            static_cast<int>(i), static_cast<int>(pos), static_cast<int>(val)));
    }

    // Campo adicional (desde Canary 15.10+)
    if (g_game.getProtocolVersion() >= 1510 && msg->getUnreadSize() >= 1) {
        uint8_t earnedFromAchievements = msg->getU8();
        g_logger.debug(fmt::format("[Wheel C++ Parse] earnedFromAchievements={}", static_cast<int>(earnedFromAchievements)));
    }

    // Verifica se sobraram bytes após o parse
    const uint16_t unread = msg->getUnreadSize();
    if (unread > 0) {
        std::ostringstream hexDump;
        hexDump << std::hex << std::setfill('0');
        std::vector<uint8_t> leftover;

        // Lê os bytes restantes sem estourar o buffer
        for (uint16_t i = 0; i < unread; ++i) {
            uint8_t b = msg->getU8();
            leftover.push_back(b);
            hexDump << std::setw(2) << static_cast<int>(b) << " ";
        }

        // Log detalhado
        g_logger.warning(fmt::format("[Wheel C++ Parse] Restaram {} bytes após parseOpenWheelWindow (descartados).", unread));
        g_logger.warning(fmt::format("[Wheel C++ Parse] Bytes extras (hex): {}", hexDump.str()));
    }

    // Callback Lua
    g_lua.callGlobalField("g_game", "onDestinyWheel",
        playerId, canView, changeState, vocationId,
        points, extraPoints, pointInvested,
        usedPromotionScrolls, equipedGems, atelierGems,
        basicUpgraded, supremeUpgraded, 0 // earnedFromAchievements placeholder
    );
}
```

* **Uso no Lua: wheel.lua**

```lua
function WheelOfDestiny.onDestinyWheel(playerId, canView, changeState, vocationId, points, scrollPoints, pointInvested, usedPromotionScrolls, equipedGems, atelierGems, basicUpgraded, supremeUpgraded, earnedFromAchievements)
  if not table.isIn({1, 2, 3, 4, 5}, vocationId) then
    wheelWindow:ungrabMouse()
    wheelWindow:ungrabKeyboard()
    local cancelFunc = function()
      if openWheel then
        openWheel:destroy()
        openWheel = nil
      end
    end

    if not openWheel then
      openWheel = displayGeneralBox(tr('Info'), tr("To be able to use the Wheel of Destiny, a character must be at leat level 51, be promoted and have active\nPremium Time."),
      { { text=tr('Ok'), callback=cancelFunc }}, cancelFunc)
      wheelWindow:hide()
      wheelWindow:ungrabMouse()
      wheelWindow:ungrabKeyboard()
    end
    return
  end

  if not canView then
    wheelWindow:hide()
    wheelWindow:ungrabMouse()
    wheelWindow:ungrabKeyboard()
    return
  end

  if not wheelWindow:isVisible() then
    wheelWindow:show()
    WheelOfDestiny.resetPassiveFocus()
    wheelWindow:grabMouse()
    wheelWindow:grabKeyboard()
  end

  -- reset a config anterior
  resetWheel(true)

  local player = g_game.getLocalPlayer()
  local bankMoney = player:getResourceBalance(ResourceTypes.BANK_BALANCE)
  local characterMoney = player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED)
  local lesserFragment = player:getResourceBalance(ResourceTypes.LESSER_FRAGMENTS)
  local greaterFragment = player:getResourceBalance(ResourceTypes.GREATER_FRAGMENTS)

  local value = bankMoney + characterMoney
  wheelWindow.moneyPanel.gold:setText(formatMoney(value, ','))
  wheelWindow.lesserFragmentPanel.gold:setText(lesserFragment)
  wheelWindow.greaterFragmentPanel.gold:setText(greaterFragment)

  WheelOfDestiny.create(playerId, canView, changeState, vocationId, points, scrollPoints, pointInvested, usedPromotionScrolls, equipedGems, atelierGems, basicUpgraded, supremeUpgraded, earnedFromAchievements)

  wheelPanel.onMouseRelease = WheelOfDestiny.onMouseRelease

  local presetEnabled = (changeState == 1)
  local managePresetsButton = wheelWindow.mainPanel.wheelMenu.info.presetTabBar:getChildById('managePresetsButton')
  if not presetEnabled then
    toggleTabBarButtons('informationButton')
  end

  managePresetsButton:setEnabled(presetEnabled)

  if vocationId == 1 then
    wheelPanel.vocationWheel:setImageSource('/images/game/wheel/wheel-vocations/backdrop_skillwheel_knight')
    wheelPanel:recursiveGetChildById("perkIconTopLeft"):setImageClip("0 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconTopRight"):setImageClip("34 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomLeft"):setImageClip("68 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomRight"):setImageClip("102 0 34 34")
  elseif vocationId == 2 then
    wheelPanel.vocationWheel:setImageSource('/images/game/wheel/wheel-vocations/backdrop_skillwheel_paladin')
    wheelPanel:recursiveGetChildById("perkIconTopLeft"):setImageClip("0 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconTopRight"):setImageClip("136 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomLeft"):setImageClip("170 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomRight"):setImageClip("204 0 34 34")
  elseif vocationId == 3 then
    wheelPanel.vocationWheel:setImageSource('/images/game/wheel/wheel-vocations/backdrop_skillwheel_sorcerer')
    wheelPanel:recursiveGetChildById("perkIconTopLeft"):setImageClip("0 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconTopRight"):setImageClip("238 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomLeft"):setImageClip("272 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomRight"):setImageClip("306 0 34 34")
  elseif vocationId == 4 then
    wheelPanel.vocationWheel:setImageSource('/images/game/wheel/wheel-vocations/backdrop_skillwheel_druid')
    wheelPanel:recursiveGetChildById("perkIconTopLeft"):setImageClip("0 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconTopRight"):setImageClip("374 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomLeft"):setImageClip("340 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomRight"):setImageClip("408 0 34 34")
  elseif vocationId == 5 then
    wheelPanel.vocationWheel:setImageSource('/images/game/wheel/wheel-vocations/backdrop_skillwheel_monk')
    wheelPanel:recursiveGetChildById("perkIconTopLeft"):setImageClip("0 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconTopRight"):setImageClip("442 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomLeft"):setImageClip("476 0 34 34")
    wheelPanel:recursiveGetChildById("perkIconBottomRight"):setImageClip("510 0 34 34")
  end
	
  if WheelOfDestiny.changeState == 1 then
    wheelWindow.reset:setEnabled(true)
    wheelWindow.apply:setEnabled(true)
    wheelWindow.ok:setEnabled(true)
  elseif WheelOfDestiny.changeState == 2 then
    wheelWindow.reset:setEnabled(false)
    wheelWindow.apply:setEnabled(true)
    wheelWindow.ok:setEnabled(true)
  else
    wheelWindow.reset:setEnabled(false)
    wheelWindow.apply:setEnabled(false)
    wheelWindow.ok:setEnabled(false)
  end

	WheelOfDestiny.onCreate(vocationId)
	WheelOfDestiny.checkApplyButton()

	WheelOfDestiny.determinateCurrentPreset()
	WheelOfDestiny.updateCurrentPreset()
    WheelOfDestiny.configureVessels()
end
```

Callback chamado quando o servidor envia os dados da roda para chegar na interface lua.

---

### 4. `sendgemAction(actionType, param, pos)`

* **Direção:** Cliente → Servidor
* **Opcode enviado:** `0xE7` (`ClientWheelGemAction = 231`)
* **Função C++ (game.cpp):**


```cpp
void Game::gemAction(const uint8_t actionType, const uint8_t param, const uint8_t pos) {
    if (!canPerformGameAction())
        return;
    m_protocolGame->sendWheelGemAction(actionType, param, pos);
}
```

* **Função C++ (protocolgamesend.cpp):**

```cpp
void ProtocolGame::sendWheelGemAction(uint8_t actionType, uint8_t param, uint8_t pos)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWheelGemAction); // 0xE7
    msg->addU8(actionType);
    msg->addU8(param);

    // Apenas "ImproveGrade" (actionType == 4) envia o byte extra
    if (actionType == 4)
        msg->addU8(pos);

    send(msg);

    // 🔍 Log de envio bem-sucedido
    g_logger.debug(fmt::format(
        "[Client Gem Action] sendWheelGemAction enviado com sucesso -> actionType={} param={} pos={}",
        static_cast<int>(actionType),
        static_cast<int>(param),
        static_cast<int>(pos)
    ));
}
```

* **Uso no Lua: gematelier.lua e workshop.lua**

```lua

function sendgemAction(actionType, param, pos)
	param = param or 0
	pos = pos or 0

	g_logger.debug(string.format("[GemAtelier] Enviando ação -> type=%d param=%d pos=%d", actionType, param, pos))
	g_game.gemAction(actionType, param, pos)

	if actionType == 3 then
		-- Toggle Lock local após breve delay (até servidor retornar)
		scheduleEvent(function()
			local gem = GemAtelier.getGemDataById(param)
			if not gem then
				g_logger.warning(string.format("[GemAtelier] Falha ao alternar lock: gem id=%d não encontrada.", param))
				return
			end

			-- Inverte corretamente (0 = unlocked, 1 = locked)
			gem.locked = gem.locked == 1 and 0 or 1
			g_logger.debug(string.format("[GemAtelier] Alternado lock local da gem id=%d -> %s", 
				param, gem.locked == 1 and "locked" or "unlocked"))

			-- Atualiza visual do botão se visível
			if lastSelectedGem and lastSelectedGem.locker then
				lastSelectedGem.locker:setChecked(gem.locked == 1)
			end

			-- Recarrega lista mantendo o foco atual
			local lastIndex = lastSelectedGem and lastSelectedGem.gemIndex or 1
			GemAtelier.showGems(false, lastIndex)
		end, 300)
	end
end

-- 0 = Destroy, param = índice da gema
sendgemAction(0, 5, 0)

-- 1 = Reveal, param = qualidade da gema (ex: 2)
sendgemAction(1, 2, 0)

-- 2 = SwitchDomain, param = índice da gema
sendgemAction(2, 3, 0)

-- 3 = ToggleLock, param = índice da gema
sendgemAction(3, 7, 0)

-- 4 = ImproveGrade, param = tipo de fragmento, pos = posição
sendgemAction(4, 1, 2)
```

Envia ao servidor a ação realizada em uma gema, de acordo com os enums `WheelGemAction_t`.

---

## ⚙️ Estrutura da Mensagem de Gem Action

O `parseWheelGemAction` no servidor lê os seguintes campos:

1. **action** (1 byte) – Tipo da ação (`WheelGemAction_t`)
2. **param** (1 byte) – Parâmetro específico da ação
3. **pos** (1 byte) – Usado apenas em `ImproveGrade`

---

## 🎯 Enum `WheelGemAction_t` (declarado no servidor)

Valores prováveis (incrementais a partir de 0):

| Valor | Enum         | Param                                     | Posição extra |
| ----- | ------------ | ----------------------------------------- | ------------- |
| 0     | Destroy      | Índice da gema                            | –             |
| 1     | Reveal       | Qualidade da gema (`WheelGemQuality_t`)   | –             |
| 2     | SwitchDomain | Índice da gema                            | –             |
| 3     | ToggleLock   | Índice da gema                            | –             |
| 4     | ImproveGrade | Tipo de fragmento (`WheelFragmentType_t`) | Sim (`pos`)   |

---

## 🔐 Regras de Validação no Servidor

* Verifica se o jogador está em **UI Exhausted** antes de processar.
* Se ação inválida → gera log de erro e ignora.
* Necessário `TOGGLE_WHEELSYSTEM` estar habilitado no config.
* Para **SwitchDomain**: requer gold para rotacionar domínio da gema.
* Para **ToggleLock**: alterna entre bloqueado e desbloqueado.

---

## 🏗️ Estrutura `GemData`

Definida em `game.h`, usada em parseOpenWheelWindow e sendSaveWheel.

```cpp
struct GemData {
    uint16_t index = 0;
    uint8_t locked = 0;
    uint8_t affinity = 0;
    uint8_t quality = 0;
    uint8_t basicModifier1 = 0;
    uint8_t basicModifier2 = 0;
    uint8_t supremeModifier = 0;
};
```

**Representação Lua:**

```lua
data = {
    presetId = 1,
    vocationId = 2,
    unlockedMajorWheels = 3,
    unlockedMinorWheels = 5,
    availablePoints = 10,
    spentPoints = 20,
    nodes = {101, 102, 103}
}
```

---

## 📌 Resumo dos Opcodes

| Direção            | Opcode | Constante (Proto)                | Função                     | Bind Lua                   |
| ------------------ | ------ | -------------------------------- | -------------------------- | -------------------------- |
| Cliente → Servidor | 0x61   | `ClientOpenWheel = 97`           | `sendOpenWheel()`          | `g_game.openWheel()`       |
| Cliente → Servidor | 0x62   | `ClientSaveWheel = 98`           | `sendSaveWheel(WheelData)` | `g_game.saveWheel(data)`   |
| Servidor → Cliente | 0x5F   | `GameServerOpenWheelWindow = 95` | `parseOpenWheelWindow()`   | `g_game.onOpenWheel(data)` |
| Cliente → Servidor | 0xE7   | `ClientWheelGemAction = 231`     | `sendWheelGemAction()`     | `sendgemAction(...)`    |

---

✅ Agora o fluxo está **completo e bidirecional** para abrir a roda, salvar presets e manipular gemas, com o bind atualizado para `gemAction` e exemplos reais de uso no Lua seguindo o que o servidor espera.
