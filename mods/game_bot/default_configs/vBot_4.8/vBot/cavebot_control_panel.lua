setDefaultTab("Cave")

g_ui.loadUIFromString([[
CaveBotControlPanel < Panel
  margin-top: 5
  layout:
    type: verticalBox
    fit-children: true

  HorizontalSeparator
  
  Label
    text-align: center
    text: CaveBot Control Panel
    font: verdana-11px-rounded
    margin-top: 3

  HorizontalSeparator
    
  Panel
    id: buttons
    margin-top: 2
    layout:
      type: grid
      cell-size: 86 20
      cell-spacing: 1
      flow: true
      fit-children: true

  HorizontalSeparator
    margin-top: 3
]])

local panel = UI.createWidget("CaveBotControlPanel")

storage.caveBot = {
  forceRefill = false,
  backStop = false,
  backTrainers = false,
  backOffline = false
}

-- [[ B U T T O N S ]] --

local forceRefill = UI.Button("Force Refill", function(widget)
    storage.caveBot.forceRefill = true
    print("[CaveBot] Going back on refill on next supply check.")
end, panel.buttons)

local backStop = UI.Button("Back & Stop", function(widget)
    storage.caveBot.backStop = true
    print("[CaveBot] Going back to city on next supply check and turning off CaveBot on depositer action.")
end, panel.buttons)

local backTrainers = UI.Button("To Trainers", function(widget)
    storage.caveBot.backTrainers = true
    print("[CaveBot] Going back to city on next supply check and going to label 'toTrainers' on depositer action.")
end, panel.buttons)

local backOffline = UI.Button("Offline", function(widget)
    storage.caveBot.backOffline = true
    print("[CaveBot] Going back to city on next supply check and going to label 'toOfflineTraining' on depositer action.")
end, panel.buttons)