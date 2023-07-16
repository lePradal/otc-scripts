local MACRO_VERSION = "1.0.2"
print("Always be mounted v" .. MACRO_VERSION .. " loaded.")

local MACRO_TIME = 2000
local ICON_ID = 999

UI.Separator()

local alwaysBeMountedMacro = macro(MACRO_TIME, "Always be mounted", function()
    if not isInPz() and not player:isMounted() then player:mount() end
 end)

addIcon("alwaysBeMountedIcon", { outfit = {mount = 392, type = 134, head = 97, body = 0, legs = 95, feet = 0, addons = 2} , text = "Mount", movable=true}, function(icon, isOn)
    alwaysBeMountedMacro.setOn(isOn) 
end)