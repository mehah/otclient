GemAtelier = {}  
  
function GemAtelier.show(container)  
    local gemUI = g_ui.loadUI('gem', container)  
    if gemUI then  
        gemUI:fill('parent')  
    end  
end