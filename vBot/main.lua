local version = "4.8"
local currentVersion
local available = false

dofile("/privateScripts/vocation.lua")

storage.checkVersion = storage.checkVersion or 0

-- check max once per 12hours
if os.time() > storage.checkVersion + (12 * 60 * 60) then

    storage.checkVersion = os.time()
    
    HTTP.get("https://raw.githubusercontent.com/Vithrax/vBot/main/vBot/version.txt", function(data, err)
        if err then
          warn("[vBot updater]: Unable to check version:\n" .. err)
          return
        end

        currentVersion = data
        available = true
    end)

end

local playername = g_game.getCharacterName() or "Unknown"
local player = g_game.getLocalPlayer()
local vocationId = player:getVocation()
local vocationName = getVocationName(vocationId)

UI.DualLabel("Name:", playername)
UI.DualLabel("Vocation:", vocationName)
UI.DualLabel("Level:", tostring(player:getLevel()))

UI.Separator()

schedule(5000, function()

    if not available then return end
    if currentVersion ~= version then
        
        UI.Separator()
        UI.Label("New vBot is available for download! v"..currentVersion)
        UI.Button("Go to vBot GitHub Page", function() g_platform.openUrl("https://github.com/Vithrax/vBot") end)
        UI.Separator()
        
    end

end)