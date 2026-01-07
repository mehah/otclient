-- Não sobrescrever FragmentWorkshop se já foi definido pelo mods/game_wheel
if not FragmentWorkshop then
    FragmentWorkshop = {}
end

-- Função de fallback caso o módulo principal não esteja carregado
if not FragmentWorkshop.show then
    function FragmentWorkshop.show(container)  
        local fragUI = g_ui.loadUI('frag', container)  
        if fragUI then  
            fragUI:fill('parent')  
        end  
    end
end