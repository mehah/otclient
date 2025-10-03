-- Todo 
-- change to TypeScript
local function configurePaginationButton(button)
  if not button or button.__historyPaginationHandlers then
    return
  end

  button.__historyPaginationHandlers = true

  connect(button, {
    onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton ~= MouseLeftButton then
        return false
      end

      widget.__historyOriginalColor = widget:getColor()
      widget:setColor('#ff0000')
      return false
    end,
    onMouseRelease = function(widget, mousePos, mouseButton)
      if mouseButton ~= MouseLeftButton then
        return false
      end

      local originalColor = widget.__historyOriginalColor
      if originalColor then
        widget:setColor(originalColor)
      else
        widget:setColor('#ffffff')
      end
      return false
    end
  })
end

local function configureHistoryPaginationButtons(historyPanel)
  if not historyPanel then
    return
  end

  configurePaginationButton(historyPanel.previousPageButton or historyPanel:getChildById('previousPageButton'))
  configurePaginationButton(historyPanel.nextPageButton or historyPanel:getChildById('nextPageButton'))
end

function showHistory()
  local historyPanel = forgeController:loadTab('history')
  configureHistoryPaginationButtons(historyPanel)
  return historyPanel
end

function forgeController:onHistoryPreviousPage()
  local state = self.historyState or {}
  local currentPage = tonumber(state.page) or 1

  if currentPage <= 1 then
    return
  end

  local historyPanel = self:loadTab('history')
  configureHistoryPaginationButtons(historyPanel)

  g_game.sendForgeBrowseHistoryRequest(currentPage - 1)
end

function forgeController:onHistoryNextPage()
  local state = self.historyState or {}
  local currentPage = tonumber(state.page) or 1
  local lastPage = tonumber(state.lastPage) or currentPage

  if currentPage >= lastPage then
    return
  end

  local historyPanel = self:loadTab('history')
  configureHistoryPaginationButtons(historyPanel)

  g_game.sendForgeBrowseHistoryRequest(currentPage + 1)
end
