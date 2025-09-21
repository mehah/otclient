HtmlSample = Controller:new()


local cores = {
    "red",
    "blue",
    "green",
    "darkorange",
    "purple",
    "darkred",
    "teal",
    "navy",
    "maroon",
    "darkgreen",
    "brown",
    "darkslategray",
    "crimson",
    "darkviolet",
    "firebrick",
    "midnightblue",
    "sienna",
    "darkolivegreen",
    "indigo",
    "darkslateblue",
}

function HtmlSample:onInit()
    self:loadHtml('htmlsample.html')

    for r = 1, 2 do
        for i = 1, #cores do
            local cor = cores[math.random(#cores)]
            local largura = math.random(10, 50)
            self.ui:append(string.format(
                '<div style="display: inline-block; width: %dpx; height: 50px; background-color: %s;"></div>',
                largura, cor
            ))
        end
    end



    local i = 0
    local sum = true
    self:cycleEvent(function()
        self.ui:setWidth(10 + i)
        if i == 1000 then
            sum = false
        elseif i == 100 then
            sum = true
        end

        if sum then
            i = i + 25
        else
            i = i - 25
        end
    end, 60)
end
