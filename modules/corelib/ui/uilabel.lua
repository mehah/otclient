-- @docclass
UILabel = extends(UIWidget, 'UILabel')

function UILabel.create()
    local label = UILabel.internalCreate()
    label:setPhantom(true)
    label:setFocusable(false)
    label:setTextAlign(AlignLeft)
    return label
end

function UILabel:setValue(value)
    local scrollBar = self:recursiveGetChildById('valueBar')
    if scrollBar then
        scrollBar:setValue(value)
    end
end

function UILabel:setValue(value)
    local scrollBar = self:recursiveGetChildById('valueBar')
    if scrollBar then
        scrollBar:setValue(value)
    end
end