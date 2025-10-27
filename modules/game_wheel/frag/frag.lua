FragmentWorkshop = {}  
  
function FragmentWorkshop.show(container)  
    local fragUI = g_ui.loadUI('frag', container)  
    if fragUI then  
        fragUI:fill('parent')  
    end  
end