addIcon("loadIcone",{ text = "Reload", switchable = false}, reload)

local HOLE_ID = "385"
addIcon("caveBotIcon", { item= { id = HOLE_ID } , text = "Cavebot", movable=true}, function(icon, isOn)
    CaveBot.setOn(isOn)
end)

local MAGIC_SWORD_ID = "3288"
local C_UMB_CROSSBOW_ID = "20087"
local NAGA_WAND_ID = "39162"
local NAGA_ROD_ID = "39163"

local voc_data = { [1] = MAGIC_SWORD_ID, [2] = C_UMB_CROSSBOW_ID, [3] = NAGA_WAND_ID, [4] = NAGA_ROD_ID, }
local TARGET_BOT_ID = voc_data[player:getVocation()]

addIcon("targetBotIcon", { item= { id = TARGET_BOT_ID } , text = "Target", movable=true}, function(icon, isOn)
    TargetBot.setOn(isOn)
end)