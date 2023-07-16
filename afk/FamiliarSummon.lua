local MACRO_VERSION = "1.0.1"
print("Familiar Summon v" .. MACRO_VERSION .. " loaded.")

UI.Separator()

local MACRO_TIME = 10000
local ICON_ID = 33982

local familiarSummonMacro = macro(MACRO_TIME, "Familiar Summon", function()
    local enoughMana = manapercent() > storage.familiarSummonMinMana
    local voc_data = { [1] = "eq", [2] = "sac", [3] = "ven", [4] = "dru", }
    local spell_end = voc_data[player:getVocation()]
    if enoughMana and not isInPz() and spell_end then
        local spell = "utevo gran res " .. spell_end
        castSpell(spell)
    end
end)

UI.Label("Min. mana %:")
UI.TextEdit(storage.familiarSummonMinMana or "90", function(widget, text)
    storage.familiarSummonMinMana = tonumber(text)
  end)

addIcon("familiarSummonIcon", { item= { id = ICON_ID } , text = "Familiar", movable=true}, function(icon, isOn)
    familiarSummonMacro.setOn(isOn) 
end)