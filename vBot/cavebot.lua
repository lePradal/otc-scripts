-- Cavebot by otclient@otclient.ovh
-- visit http://bot.otclient.ovh/

local cavebotTab = "Cave"
local targetingTab = storage.extras.joinBot and "Cave" or "Target"
local afkTab = "AFK"

local KNIGHT = 1
local PALADIN = 2
local SORCERER = 3
local DRUID = 4

setDefaultTab(cavebotTab)
CaveBot.Extensions = {}
importStyle("/cavebot/cavebot.otui")
importStyle("/cavebot/config.otui")
importStyle("/cavebot/editor.otui")
dofile("/cavebot/actions.lua")
dofile("/cavebot/config.lua")
dofile("/cavebot/editor.lua")
dofile("/cavebot/example_functions.lua")
dofile("/cavebot/recorder.lua")
dofile("/cavebot/walking.lua")
dofile("/cavebot/minimap.lua")
-- in this section you can add extensions, check extension_template.lua
--dofile("/cavebot/extension_template.lua")
dofile("/cavebot/sell_all.lua")
dofile("/cavebot/depositor.lua")
dofile("/cavebot/buy_supplies.lua")
dofile("/cavebot/d_withdraw.lua")
dofile("/cavebot/supply_check.lua")
dofile("/cavebot/travel.lua")
dofile("/cavebot/doors.lua")
dofile("/cavebot/pos_check.lua")
dofile("/cavebot/withdraw.lua")
dofile("/cavebot/inbox_withdraw.lua")
dofile("/cavebot/lure.lua")
dofile("/cavebot/bank.lua")
dofile("/cavebot/clear_tile.lua")
dofile("/cavebot/tasker.lua")
dofile("/cavebot/imbuing.lua")
dofile("/cavebot/stand_lure.lua")
-- main cavebot file, must be last
dofile("/cavebot/cavebot.lua")

setDefaultTab(targetingTab)
if storage.extras.joinBot then UI.Label("-- [[ TargetBot ]] --") end
TargetBot = {} -- global namespace
importStyle("/targetbot/looting.otui")
importStyle("/targetbot/target.otui")
importStyle("/targetbot/creature_editor.otui")
dofile("/targetbot/creature.lua")
dofile("/targetbot/creature_attack.lua")
dofile("/targetbot/creature_editor.lua")
dofile("/targetbot/creature_priority.lua")
dofile("/targetbot/looting.lua")
dofile("/targetbot/walking.lua")
-- main targetbot file, must be last
dofile("/targetbot/target.lua")
dofile("/targetbot/hold_position.lua")

if player:getVocation() == KNIGHT then
    dofile("/targetbot/face_target.lua")
    dofile("/afk/exeta_res.lua")
end

setDefaultTab(afkTab)
AfkBot = {} -- global namespace
dofile("/afk/auto_accept_party.lua")
dofile("/afk/AutoParty.lua")
dofile("/afk/ExetaLoot.lua")
dofile("/afk/always_be_mounted.lua")
dofile("/afk/ExchangeConcentratedBlood.lua")
dofile("/afk/AntiPush.lua")

dofile("/afk/FamiliarSummon.lua")

if player:getVocation() == SORCERER or player:getVocation() == DRUID then
    dofile("/afk/SummonCreature.lua")
end

-- No tabs scripts
dofile("/on_load/wheel_of_destiny.lua")
dofile("/on_load/cast_on.lua")

-- Load icons
dofile("/vBot/icons.lua")