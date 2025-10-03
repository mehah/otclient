-- Todo 
-- change to TypeScript
function showHistory()
  return forgeController:loadTab('history')
end

function forgeController:onHistoryPreviousPage()
  local state = self.historyState or {}
  local currentPage = tonumber(state.page) or 1

  if currentPage <= 1 then
    return
  end

  g_game.sendForgeBrowseHistoryRequest(currentPage - 1)
end

function forgeController:onHistoryNextPage()
  local state = self.historyState or {}
  local currentPage = tonumber(state.page) or 1
  local lastPage = tonumber(state.lastPage) or currentPage

  if currentPage >= lastPage then
    return
  end

  g_game.sendForgeBrowseHistoryRequest(currentPage + 1)
end
