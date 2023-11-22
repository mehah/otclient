CaveBot.Extensions.Tasker = {}

local dataValidationFailed = function()
    print("CaveBot[Tasker]: data validation failed! incorrect data, check cavebot/tasker for more info")
    return false
end

-- miniconfig
local talkDelay = storage.extras.talkDelay
if not storage.caveBotTasker then
    storage.caveBotTasker = {
        inProgress = false,
        monster = "",
        taskName = "",
        count = 0,
        max = 0
    }
end

local resetTaskData = function()
    storage.caveBotTasker.inProgress = false
    storage.caveBotTasker.monster = ""
    storage.caveBotTasker.monster2 = ""
    storage.caveBotTasker.taskName = ""
    storage.caveBotTasker.count = 0
    storage.caveBotTasker.max = 0
end

CaveBot.Extensions.Tasker.setup = function()
  CaveBot.registerAction("Tasker", "#FF0090", function(value, retries)
    local taskName = ""
    local monster = ""
    local monster2 = ""
    local count = 0
    local label1 = ""
    local label2 = ""
    local task

    local data = string.split(value, ",")
    if not data or #data < 1 then
        dataValidationFailed()
    end
    local marker = tonumber(data[1])

    if not marker then
        dataValidationFailed()
        resetTaskData()
    elseif marker == 1 then
        if getNpcs(3) == 0 then
            print("CaveBot[Tasker]: no NPC found in range! skipping")
            return false
        end
        if #data ~= 4 and #data ~= 5 then
            dataValidationFailed()
            resetTaskData()
        else
            taskName = data[2]:lower():trim()
            count = tonumber(data[3]:trim())
            monster = data[4]:lower():trim()
            if #data == 5 then
                monster2 = data[5]:lower():trim()
            end
        end
    elseif marker == 2 then
        if #data ~= 3 then
            dataValidationFailed()
        else
            label1 = data[2]:lower():trim()
            label2 = data[3]:lower():trim()
        end
    elseif marker == 3 then
        if getNpcs(3) == 0 then
            print("CaveBot[Tasker]: no NPC found in range! skipping")
            return false
        end
        if #data ~= 1 then
            dataValidationFailed()
        end
    end
    
    -- let's cover markers now
    if marker == 1 then -- starting task
        CaveBot.Conversation("hi", "task", taskName, "yes")
        delay(talkDelay*4)

        storage.caveBotTasker.monster = monster
        if monster2 then storage.caveBotTasker.monster2 = monster2 end
        storage.caveBotTasker.taskName = taskName
        storage.caveBotTasker.inProgress = true
        storage.caveBotTasker.max = count
        storage.caveBotTasker.count = 0

        print("CaveBot[Tasker]: taken task for: " .. monster .. " x" .. count)
        return true
    elseif marker == 2 then -- only checking
        if not storage.caveBotTasker.inProgress then
            CaveBot.gotoLabel(label2)
            print("CaveBot[Tasker]: there is no task in progress so going to take one.")
            return true
        end

        local max = storage.caveBotTasker.max
        local count = storage.caveBotTasker.count

        if count >= max then
            CaveBot.gotoLabel(label2)
            print("CaveBot[Tasker]: task completed: " .. storage.caveBotTasker.taskName)
            return true
        else
            CaveBot.gotoLabel(label1)
            print("CaveBot[Tasker]: task in progress, left: " .. max - count .. " " .. storage.caveBotTasker.taskName)
            return true
        end


    elseif marker == 3 then -- reporting task
        CaveBot.Conversation("hi", "report", "task")
        delay(talkDelay*3)

        resetTaskData()
        print("CaveBot[Tasker]: task reported, done")
        return true
    end

  end)

 CaveBot.Editor.registerAction("tasker", "tasker", {
  value=[[     There is 3 scenarios for this extension, as example we will use medusa:

  1. start task,
      parameters:
      - scenario for extension: 1
      - task name in gryzzly adams: medusae
      - monster count: 500
      - monster name to track: medusa
      - optional, monster name 2: 
  2. check status, 
      to be used on refill to decide whether to go back or spawn or go give task back
      parameters:
      - scenario for extension: 2
      - label if task in progress: skipTask
      - label if task done: taskDone  
  3. report task,
      parameters:
      - scenario for extension: 3
  
  Strong suggestion, almost mandatory - USE POS CHECK to verify position! this module will only check if there is ANY npc in range!

  when begin remove all the text and leave just a single string of parameters
  some examples:

  2, skipReport, goReport
  3
  1, drakens, 500, draken warmaster, draken spellweaver
  1, medusae, 500, medusa]],
  title="Tasker",
  multiline = true
 })
end

local regex = "Loot of ([a-z])* ([a-z A-Z]*):"
local regex2 = "Loot of ([a-z A-Z]*):"
onTextMessage(function(mode, text)
   -- if CaveBot.isOff() then return end
    if not text:lower():find("loot of") then return end
    if #regexMatch(text, regex) == 1 and #regexMatch(text, regex)[1] == 3 then
        monster = regexMatch(text, regex)[1][3]
    elseif #regexMatch(text, regex2) == 1 and #regexMatch(text, regex2)[1] == 2 then
        monster = regexMatch(text, regex2)[1][2]
    end

    local m1 = storage.caveBotTasker.monster
    local m2 = storage.caveBotTasker.monster2

    if monster == m1 or monster == m2 and storage.caveBotTasker.count then
        storage.caveBotTasker.count = storage.caveBotTasker.count + 1
    end
end)
