UI.Separator()

local concentratedBloodId = 6558
macro(20000, "Exchange concentrated blood", function()
  local containers = g_game.getContainers()
  for index, container in pairs(containers) do
    if not container.lootContainer then
      for i, item in ipairs(container:getItems()) do
        if item:getCount() >= storage.minConcentratedBloodsToExchange then
            if item:getId() == concentratedBloodId then
              return g_game.use(item)            
            end
        end
      end
    end
  end
end)

UI.Label("Min. potions to exchange:")
UI.TextEdit(storage.minConcentratedBloodsToExchange or "3", function(widget, text)
    storage.minConcentratedBloodsToExchange = tonumber(text)
  end)