UI.Separator()

if type(storage.antiPushItens) ~= "table" then
    storage.antiPushItens = {3031, 3035}
end

local maxStackedItems = 10
local dropDelay = 600

gpAntiPushDrop = macro(dropDelay , "Anti-Push", function ()
  antiPush()
end)

onPlayerPositionChange(function()
    antiPush()
end)

function antiPush()
  if gpAntiPushDrop:isOff() then
    return
  end

  local tile = g_map.getTile(pos())
  if tile and tile:getThingCount() < maxStackedItems then
    local thing = tile:getTopThing()
    if thing and not thing:isNotMoveable() then
      for i, item in pairs(storage.antiPushItens) do
        if item.id ~= thing:getId() then
            local dropItem = findItem(item.id)
            if dropItem then
              g_game.move(dropItem, pos(), 1)
            end
        end
      end
    end
  end
end

local antiPushContainer = UI.Container(function(widget, items)
    storage.antiPushItens = items
end, true)
antiPushContainer:setHeight(35)
antiPushContainer:setItems(storage.antiPushItens)


UI.Separator()

gpPushEnabled = false
gpPushDelay = 600 -- safe value: 600ms

local switch = addSwitch("gpPushEnabled", "Push Redor p/ Baixo", function(widget)
    widget:setOn(not widget:isOn())
    gpPushEnabled = widget:isOn()
end, tab)

macro(gpPushDelay, function ()
    if gpPushEnabled then
        push(0, -1, 0)
        push(0, 1, 0)
        push(-1, -1, 0)
        push(-1, 0, 0)
        push(-1, 1, 0)
        push(1, -1, 0)
        push(1, 0, 0)
        push(1, 1, 0)
    end
end)

function push(x, y, z)
    local position = player:getPosition()
    position.x = position.x + x
    position.y = position.y + y
  
    local tile = g_map.getTile(position)
    local thing = tile:getTopThing()
    if thing and thing:isItem() then
      g_game.move(thing, player:getPosition(), thing:getCount())
    end
end