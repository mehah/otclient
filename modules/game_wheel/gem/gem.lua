-- Não sobrescrever GemAtelier se já foi definido pelo mods/game_wheel
if not GemAtelier then
    GemAtelier = {}  
end

-- Função de fallback caso o módulo principal não esteja carregado
if not GemAtelier.show then
    function GemAtelier.show(container)  
        local gemUI = g_ui.loadUI('gem', container)  
        if gemUI then  
            gemUI:fill('parent')  
        end  
    end
end