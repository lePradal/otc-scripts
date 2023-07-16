local version = "4.8"
local currentVersion
local available = false

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

UI.Separator()

local color = '#10DD29'
local labelname = UI.DualLabel("Name:", "", {maxWidth = 100}).right
labelname:setText(player:getName())
labelname:setColor(color)

local labelVocation = UI.DualLabel("Vocation:", "", {maxWidth = 100}).right
local voc_data = { [1] = "Elite Knight", [2] = "Royal Paladin", [3] = "Master Sorcerer", [4] = "Elder Druid", }
local vocation =  voc_data[player:getVocation()]
labelVocation:setText(vocation)
labelVocation:setColor(color)

local labellevel = UI.DualLabel("Level:", "", {maxWidth = 100}).right
labellevel:setText(player:getLevel())
labellevel:setColor(color)

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