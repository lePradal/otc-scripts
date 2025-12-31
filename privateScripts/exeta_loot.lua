setDefaultTab("Target")

UI.Separator()

local ICON_ITEM_ID = 2854 -- Backpack
local CHECK_INTERVAL = 10000 -- in milliseconds

local exetaLootMacro = macro(CHECK_INTERVAL, "Exeta Loot", function()
    if isInPz() then return false end

    say("exeta loot")
end)

local exetaLootIcon = addIcon("exetaLootIcon", { text="Exeta Loot", item = {id = ICON_ITEM_ID, count = 1}, moveable=true }, exetaLootMacro)

exetaLootIcon:setSize({height=50,width=250})
exetaLootIcon:breakAnchors()
exetaLootIcon:move(80, 80)