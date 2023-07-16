local MACRO_VERSION = "1.0.0"
print("Hold Position v" .. MACRO_VERSION .. " loaded.")

local MACRO_TIME = 500
local ICON_ID = 2025

UI.Separator()

local holdPositionMacro = macro(MACRO_TIME, "Hold Position", function()
    updateLabelsPositions()

    if TargetBot.isOn() and not isValidPosition() then
        TargetBot.setOff()
        return
    end

    if TargetBot.isOff() and isValidPosition() then
        TargetBot.setOn()
        return
    end
end)

UI.Button("Save position", function()
    if not tonumber(posx()) or not tonumber(posy()) then return end 

    storage.holdPositionX = posx()
    storage.holdPositionY = posy()
end)

local positionToHoldXLabel = UI.DualLabel("X:", storage.holdPositionX or "", {}).right
local positionToHoldYLabel = UI.DualLabel("Y:", storage.holdPositionY or "", {}).right

function isValidPosition()
    local holdX = tonumber(storage.holdPositionX)
    local holdY = tonumber(storage.holdPositionY)
    local range = tonumber(storage.holdPositionRange)

    if not holdX or not holdY or not range then return end

    local distance = math.abs(posx() - holdX) + math.abs(posy() - holdY)

    local distanceX = math.abs(posx() - holdX)
    local distanceY = math.abs(posy() - holdY)

    local valid = distanceX <= range and distanceY <= range
    return valid
end

UI.Label("Range [sqm]:")
addTextEdit("rangeSqm", storage.holdPositionRange or "1", function(widget, text)
  if not tonumber(text) then return end

  storage.holdPositionRange = text
end)

function updateLabelsPositions()
    if positionToHoldXLabel then positionToHoldXLabel:setText(storage.holdPositionX) end
    if positionToHoldYLabel then positionToHoldYLabel:setText(storage.holdPositionY) end
end

addIcon("holdPositionIcon", { item= { id = ICON_ID } , text = "Hold", movable=true}, function(icon, isOn)
    holdPositionMacro.setOn(isOn) 
end)