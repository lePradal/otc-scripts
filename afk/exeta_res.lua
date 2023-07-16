local MACRO_VERSION = "1.0.3"
print("Exeta Res v" .. MACRO_VERSION .. " loaded.")

local KNIGHT_ID = 1
local MACRO_TIME = 3000
local MIN_MANA_PERCENT = 60

if storage.exetaResMinMobs == nil or not storage.exetaResMinMobs then storage.exetaResMinMobs = "2" end
if storage.exetaResChecked == nil then storage.exetaResChecked = false end
if storage.exetaAmpResChecked == nil then storage.exetaAmpResChecked = false end

UI.Separator()

function getNearbyPlayers(range)
    if not range then range = 10 end
    local specs = 0;
    for _, spec in pairs(getSpectators()) do
        if not spec:isLocalPlayer() and spec:isPlayer() and distanceFromPlayer(spec:getPosition()) <= range then
            specs = specs + 1
        end
    end
    return specs;
end

macro(MACRO_TIME, "Exeta Res", function()
    if isInPz() then return end
    if modules.game_cooldown.isGroupCooldownIconActive(3) then return end

    local enoughMana = manapercent() >= MIN_MANA_PERCENT
    if not enoughMana then return end

    castExetaAmpRes()
    castExetaRes()
end)

UI.Label("Min. mobs:")
UI.TextEdit(storage.exetaResMinMobs or "2", function(widget, text)
    storage.exetaResMinMobs = tonumber(text)
end)


local checkBox = {}
checkBox.exetaResCheck = setupUI([[
CheckBox
  id: exetaResCheck
  font: cipsoftFont
  text: Enable "exeta res"
  margin-top: 8
]])

checkBox.exetaAmpResCheck = setupUI([[
CheckBox
  id: exetaAmpResCheck
  font: cipsoftFont
  text: Enable "exeta amp res"
  margin-bottom: 8
]])

checkBox.exetaResCheck.onCheckChange = function(widget, checked)
    storage.exetaResChecked = checked
  end

checkBox.exetaAmpResCheck.onCheckChange = function(widget, checked)
    storage.exetaAmpResChecked = checked
  end

checkBox.exetaResCheck:setChecked(storage.exetaResChecked)
checkBox.exetaAmpResCheck:setChecked(storage.exetaAmpResChecked)

function castExetaRes()
    if not storage.exetaResChecked then return end

    local enoughMobs = getMonsters(1) >= storage.exetaResMinMobs
    if not enoughMobs then return end

    castSpell("exeta res")
end

function castExetaAmpRes()
    if not storage.exetaAmpResChecked then return end

    local totalMobs = getMonsters()
    local nearMobs = getMonsters(1)

    local enoughMobs = (totalMobs - nearMobs) >= storage.exetaResMinMobs
    if not enoughMobs then return end

    castSpell("exeta amp res")
end