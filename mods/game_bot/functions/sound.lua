local context = G.botContext

context.getSoundChannel = function()
  if not g_sounds then
    return
  end
  return g_sounds.getChannel(SoundChannels.Bot)
end

context.playSound = function(file)
  local botSoundChannel = context.getSoundChannel()
  if not botSoundChannel then
    return
  end
  botSoundChannel:setEnabled(true)
  botSoundChannel:stop(0)
  botSoundChannel:play(file, 0, 1.0)
  return botSoundChannel
end

context.stopSound = function()
  local botSoundChannel = context.getSoundChannel()
  if not botSoundChannel then
    return
  end
  botSoundChannel:stop()
end

context.playAlarm = function()
  return context.playSound("/sounds/alarm.ogg")
end
