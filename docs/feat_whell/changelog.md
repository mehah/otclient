# 🌀 feat(wheel): implementação completa da Wheel of Destiny com compatibilidade Canary e Crystal (13.x–15.11)

## 🧩 Descrição Geral

Implementada a **Wheel of Destiny** totalmente funcional, integrando cliente OTClient 15.11 com servidores **Canary** e **Crystal** (protocolos 13.x a 15.11), incluindo todos os fluxos de comunicação, armazenamento e sincronização de dados entre C++, Lua e KV/DB.

---

## 🔗 Comunicação Cliente ↔ Servidor

- Implementados opcodes **0x61 (ClientOpenWheel)**, **0x62 (ClientSaveWheel)** e **0x5F (GameServerOpenWheelWindow)**.  
- Sincronização total de pacotes binários entre cliente e servidor, conforme padrões oficiais do protocolo Canary.  
- Logs e depuração aprimorados para envio e parsing de pacotes (`parseOpenWheel`, `parseSaveWheel`, `sendOpenWheelWindow`).

---

## ⚙️ Lado do Servidor (Canary/Core)

- Criação e integração da classe **`PlayerWheel`**, responsável por:
  - Gerenciar pontos investidos por slot, gemas, perks e scrolls.
  - Carregar/salvar dados da roda no banco de dados e KV store.
  - Enviar os dados completos da Wheel via `sendOpenWheelWindow`.
- Adicionados métodos auxiliares (`addPromotionScrolls`, `addGems`, `addGradeModifiers`, `saveSlotPointsOnPressSaveButton`) com compatibilidade de versão 13.x a 15.11.
- Integração dos bônus de combate e magia através de `PlayerWheelMethodsBonusData`.

---

## 💎 Sistema de Gemas (Wheel Gems)

- Implementado **`WheelModifierContext`** com padrão *Strategy Pattern*, incluindo:
  - `GemModifierResistanceStrategy`
  - `GemModifierStatStrategy`
  - `GemModifierRevelationStrategy`
  - `GemModifierSpellBonusStrategy`
- Lógica unificada para gemas *lesser, regular, greater e supreme* com multiplicadores de grade.
- Funções `WheelGemUtils` otimizadas para retornar valores de vocação dinâmicos (Health, Mana, Capacity).

---

## 🧙‍♂️ Sistema de Magias e Perks

- Estrutura de bônus encapsulada em `WheelSpells::Bonus` (heal, damage, cooldown, leech).
- Integração dos perks de vocação (Knight, Paladin, Druid, Sorcerer, Monk) no fluxo da roda.
- Controle de cooldowns e habilidades passivas via `PlayerWheel::checkAbilities()`.

---

## 🧩 Lado do Cliente (OTClient 15.11)

- Implementadas chamadas diretas em Lua:
  - `g_game.openWheel(playerId)`
  - `g_game.sendApplyWheelPoints(slotPoints, greenGem, redGem, acquaGem, purpleGem)`
- Adicionado parser `parseOpenWheelWindow` (C++) e callback Lua `WheelOfDestiny:onDestinyWheel()`.
- Interface integrada ao painel da Wheel e sincronizada com os dados do servidor.

---

## 🧾 Compatibilidade e Logs

- Compatível com versões **13.x, 14.x e 15.11** do protocolo Crystal/Canary.
- Adicionados logs detalhados no envio, parsing e gravação de pontos e gemas.
- Tratamento de bytes adicionais e variações de protocolo (scrollPoints, achievements, monkQuest).

---

## 🧱 Infraestrutura e Documentação

- Criado arquivo **`wheel_documentation.md`** documentando a implementação cliente ↔ servidor.
- Criado arquivo **`wheel_server_documentation.md`** com descrição completa da lógica interna do servidor.
- Código estruturado e comentado para manutenção futura e portabilidade entre forks.

---

## 📦 Resultado Final

Sistema **Wheel of Destiny** totalmente funcional, modular e compatível com as versões atuais do **Canary e Crystal**, com suporte a gemas, perks, scrolls e interface integrada no cliente OTClient 15.11.
