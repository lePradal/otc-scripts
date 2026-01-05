setDefaultTab("Target")

local MACRO_VERSION = "1.0.1"
print("Familiar Summon v" .. MACRO_VERSION .. " loaded.")

dofile("/privateScripts/vocation.lua")

if storage.familiarSummonMinMana == nil then
    storage.familiarSummonMinMana = 90
end

UI.Separator()

local MACRO_TIME = 10000
local ICON_ID = 33982

local familiarSummonMacro = macro(MACRO_TIME, "Familiar Summon", function()
    local enoughMana = manapercent() > storage.familiarSummonMinMana
    local spell = getVocationFamiliarSummonSpell(player:getVocation())
    if enoughMana and not isInPz() and spell then
        castSpell(spell)
    end
end)

UI.Label("Min. mana %:")
UI.TextEdit(storage.familiarSummonMinMana, function(widget, text)
    storage.familiarSummonMinMana = tonumber(text)
  end)

local familiarSummonIcon = addIcon("familiarSummonIcon", { item= { id = ICON_ID } , text = "Familiar", movable=true}, familiarSummonMacro)

familiarSummonIcon:setSize({
    height = 50,
    width = 250
})
familiarSummonIcon:breakAnchors()
familiarSummonIcon:move(80, 380)