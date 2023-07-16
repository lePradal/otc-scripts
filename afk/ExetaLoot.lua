local MACRO_VERSION = "1.0.1"
print("Exeta loot v" .. MACRO_VERSION .. " loaded.")

local MACRO_TIME = 3000
local MIN_HP_PERCENT = 80
local MIN_MP_PERCENT = 50
local ICON_ID = 23721

UI.Separator()

exetaLootMacro = macro(MACRO_TIME, "Exeta Loot", function() 
    if hppercent() > MIN_HP_PERCENT and manapercent() > MIN_MP_PERCENT and not isInPz() then
        castSpell("exeta loot")
    end
 end)

addIcon("exetaLootIcon", { item= { id = ICON_ID } , text = "Loot", movable=true}, function(icon, isOn)
    exetaLootMacro.setOn(isOn) 
end)