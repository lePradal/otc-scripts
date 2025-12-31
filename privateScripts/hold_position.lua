setDefaultTab("Target")

UI.Separator()

local ICON_ITEM_ID = 10427
local CHECK_INTERVAL = 1000 -- in milliseconds
storage.maxDistanceToHold = storage.maxDistanceToHold or 5
storage.holdPosition = storage.holdPosition or nil

local function getCurrentPosition()
    local player = g_game.getLocalPlayer()
    if not player then return nil end

    return player:getPosition()
end

local function savePosition(pos)
    if not pos then return end
    storage.holdPosition = pos
end

local function disableTargetBot()
    TargetBot.setOff()
end

local function enableTargetBot()
    TargetBot.setOn()
end

local holdPositionMacro = macro(CHECK_INTERVAL, "Hold Position", function()
    if not storage.holdPosition then
        return
    end

    local distance = getDistanceBetween(getCurrentPosition(), storage.holdPosition)

    if distance <= storage.maxDistanceToHold then
        enableTargetBot()
        return
    end

    disableTargetBot()

    autoWalk(storage.holdPosition)
end)

UI.Label("Max distance to hold position:")
UI.TextEdit(storage.maxDistanceToHold, function(widget, text)    
  storage.maxDistanceToHold = tonumber(text)
end)

UI.Label("Position:")
local xLabel = UI.DualLabel("X:", (storage.holdPosition and storage.holdPosition.x or "N/A")).right
local yLabel = UI.DualLabel("Y:", (storage.holdPosition and storage.holdPosition.y or "N/A")).right
local zLabel = UI.DualLabel("Z:", (storage.holdPosition and storage.holdPosition.z or "N/A")).right

local holdPositionIcon = addIcon("holdPositionIcon", {text="Hold Position", item = {id = ICON_ITEM_ID, count = 1}, moveable=true}, holdPositionMacro)

holdPositionIcon:setSize({height=50,width=250})
holdPositionIcon:breakAnchors()
holdPositionIcon:move(80, 130)

local function updateUI()
    local pos = storage.holdPosition
    xLabel:setText(pos and pos.x or "N/A")
    yLabel:setText(pos and pos.y or "N/A")
    zLabel:setText(pos and pos.z or "N/A")
end

local function updatePosition()
    local pos = getCurrentPosition()
    savePosition(pos)
    updateUI()
end

UI.Button("Update position", function()  
    updatePosition()
end)