HtmlSample = Controller:new()
HtmlSample.showEqualizerEffect = true

function HtmlSample:onInit()
    self:loadHtml('htmlsample.html')
    self:equalizerEffect()

    self.players = {}
end

function HtmlSample:addPlayer(name)
    if not name or #name == 0 then
        return
    end

    table.insert(self.players, {
        name = name,
        lookType = self.lookType
    })

    self.playerName = ''
end

function HtmlSample:removePlayer(index)
    table.remove(self.players, index)
end

function HtmlSample:equalizerEffect()
    local widgets = self:findWidgets('.line')

    for _, widget in pairs(widgets) do
        local minV = math.random(0, 30)
        local maxV = math.random(70, 100)
        if minV > maxV then minV, maxV = maxV, minV end

        local range = maxV - minV
        local speed = math.max(1, math.floor(range / 20)) + math.random(0, 1)

        local value = math.random(minV, maxV)
        local dir   = (math.random(0, 1) == 0) and -1 or 1
        self:cycleEvent(function()
            if widget:isDestroyed() then
                return false
            end

            value = value + dir * speed
            if value >= maxV then
                value = maxV
                dir = -1
            elseif value <= minV then
                value = minV
                dir = 1
            end

            widget:setHeight(10 + value)
            widget:setTop(89 - value)
        end, 30)
    end
end
