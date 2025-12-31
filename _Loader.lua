-- load all otui files, order doesn't matter
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local folders = {"vBot", "privateScripts"}

local vBotFiles = {
  "main",
  "items",
  "vlib",
  "new_cavebot_lib",
  "configs", -- do not change this and above
  "extras",
  "cavebot",
  "playerlist",
  "BotServer",
  "alarms",
  "Conditions",
  "Equipper",
  "pushmax",
  "combo",
  "HealBot",
  "new_healer",
  "AttackBot", -- last of major modules
  "ingame_editor",
  "Dropper",
  "Containers",
  "quiver_manager",
  "quiver_label",
  "tools",
  "antiRs",
  "depot_withdraw",
  "eat_food",
  "equip",
  "exeta",
  "analyzer",
  "spy_level",
  "supplies",
  "depositer_config",
  "npc_talk",
  "xeno_menu",
  "hold_target",
  "cavebot_control_panel"
}

local privateScriptsFiles = {
  "exeta_loot",
  "hold_position",
  "reload",
  "auto_party_v2"
}

for _, folder in ipairs(folders) do
  local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/" .. folder, true, false)
  
  local function loadScript(name)
    return dofile("/" .. folder .. "/" .. name .. ".lua")
  end
  
  for i, file in ipairs(configFiles) do
    local ext = file:split(".")
    if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
      g_ui.importStyle(file)
    end
  end

  local luaFiles = {}

  if folder == "vBot" then
    luaFiles = vBotFiles
  else
    luaFiles = privateScriptsFiles
  end

  for i, file in ipairs(luaFiles) do
    loadScript(file)
  end
end

setDefaultTab("Main")
UI.Separator()
UI.Label("Private Scripts:")
UI.Separator()