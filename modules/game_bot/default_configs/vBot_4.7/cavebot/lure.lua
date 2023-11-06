CaveBot.Extensions.Lure = {}

CaveBot.Extensions.Lure.setup = function()
  CaveBot.registerAction("lure", "#FF0090", function(value, retries)
    value = value:lower()
    if value == "start" then
        TargetBot.setOff()
    elseif value == "stop" then
        TargetBot.setOn()
    elseif value == "toggle" then
      if TargetBot.isOn() then
        TargetBot.setOff()
      else
        TargetBot.setOn()
      end
    else
      warn("incorrect lure value!")
    end
    return true
  end)

  CaveBot.Editor.registerAction("lure", "lure", {
    value="toggle",
    title="Lure",
    description="TargetBot: start, stop, toggle",
    multiline=false,
    validation=[[(start|stop|toggle)$]]
})
end