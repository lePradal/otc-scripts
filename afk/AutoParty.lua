local MACRO_VERSION = "1.0.6"
print("Autoparty v" .. MACRO_VERSION .. " loaded.")
-- Last release:
--  - checkboxes to customize which private messages should be sent
--  - fix: experience calculation when starting the hunt

-- Variables
local infoTime = 0
local talkTime = 0
local maxLevel = 0
local minLevel = 0
local justForInfo = true
local canSeeInfo = true
local partyMembersCount = 0
local currentBonus = "0%"
local expPerHour = 0

-- Constants
local MAX_PLAYERS = 30
local ALREADY_INVITED_SHIELD = 2
local VALUE_PART_INDEX = 2
local MEMBERS_COUNT_INDEX = 2
local HIGHER_LEVEL_INDEX = 3
local LOWER_LEVEL_INDEX = 4
local CURRENT_BONUS_INDEX = 6
local INACTIVE_PLAYERS_INDEX = 8
local TALK_TIME = 15
local CYCLE_TIME = 20
local MACRO_TIME = 1000
local CALL_MEMBERS_TIME = 30000
local PARTY_INFO_TEXT = "!party info"
local BREAK_LINE = "\n"
local ICON_ID = 28722

if storage.callMembersInChatChecked == nil then storage.callMembersInChatChecked = false end
if storage.inviteMessage == nil or not storage.inviteMessage then storage.inviteMessage = "" end

if storage.maxLevel == nil or not storage.maxLevel then storage.maxLevel = "500" end
if storage.minLevel == nil or not storage.minLevel then storage.minLevel = "400" end
if storage.partyBlockedPlayers == nil or not storage.partyBlockedPlayers then storage.partyBlockedPlayers = "" end

if storage.sendWhenPlayerAlreadyInvitedChecked == nil then storage.sendWhenPlayerAlreadyInvitedChecked = false end
if storage.sendWhenLevelNotAllowedChecked == nil then storage.sendWhenLevelNotAllowedChecked = false end
if storage.sendWhenPtFullChecked == nil then storage.sendWhenPtFullChecked = false end
if storage.sendWhenPlayerBlockedChecked == nil then storage.sendWhenPlayerBlockedChecked = false end

if storage.membersInMessageInfoChecked == nil then storage.membersInMessageInfoChecked = false end
if storage.experienceInMessageInfoChecked == nil then storage.experienceInMessageInfoChecked = false end
if storage.bonusInMessageInfoChecked == nil then storage.bonusInMessageInfoChecked = false end
if storage.maxAndMinLevelInMessageInfoChecked == nil then storage.maxAndMinLevelInMessageInfoChecked = false end

UI.Separator()

-- Macro
local partyLeaderHuntWidget = macro(MACRO_TIME, "Auto Party", function()
  setExpPerHour()

  sendMessageInWorldChat()

  if not player:isPartyLeader() then
    justForInfo = true
    partyMembersCount = 0
    return
  end

  if justForInfo and canSeeInfo then
    sayChannel(getChannelId("party"), PARTY_INFO_TEXT)
    return
  end

  if talkTime > 0 then
    talkTime = talkTime - 1
  end

  if player:getShield() == 10 then
    infoTime = infoTime + 1
    if infoTime >= CYCLE_TIME then
      sayChannel(getChannelId("party"), PARTY_INFO_TEXT)
      infoTime = 0
    end
  else
    infoTime = 0
  end

end)

-- UI
addLabel("maxLevel", "Max Level:")
addTextEdit("maxLevel", storage.maxLevel or "", function(widget, text)
  if tonumber(text) then
    maxLevel = tonumber(text)
  else
    sayChannel(getChannelId("party"), PARTY_INFO_TEXT)
  end
  storage.maxLevel = tonumber(text)
end)

addLabel("minLevel", "Min Level:")
addTextEdit("minLevel", storage.minLevel or "", function(widget, text)
  if tonumber(text) then
    minLevel = tonumber(text)
  else
    sayChannel(getChannelId("party"), PARTY_INFO_TEXT)
  end
  storage.minLevel = tonumber(text)
end)

UI.Button("Block Players", function(newText) 
  UI.MultilineEditorWindow(storage.partyBlockedPlayers or "", { title="Blocked Players List", description="Add the name of the players to be blocked from the party.\nExample:\nPlayer 1\nPlayer 2\nPlayer 3", width=250, height=200 }, function(text)
    storage.partyBlockedPlayers = text
    reload()
  end)
end)

addLabel("sendPrivateMessageLabel", "Send private message when:")
local checkBox = {}

checkBox.playerAlreadyInvitedCheck = setupUI([[
CheckBox
  id: playerAlreadyInvitedCheck
  font: cipsoftFont
  text: Player already invited
  margin-top: 8
]])

checkBox.levelNotAllowedCheck = setupUI([[
CheckBox
  id: levelNotAllowedCheck
  font: cipsoftFont
  text: Level not allowed
]])

checkBox.ptFullCheck = setupUI([[
CheckBox
  id: ptFullCheck
  font: cipsoftFont
  text: Full pt
]])

checkBox.playerBlockedCheck = setupUI([[
CheckBox
  id: playerBlockedCheck
  font: cipsoftFont
  text: Player blocked
  margin-bottom: 8
]])

checkBox.playerAlreadyInvitedCheck.onCheckChange = function(widget, checked)
  storage.sendWhenPlayerAlreadyInvitedChecked = checked
end

checkBox.levelNotAllowedCheck.onCheckChange = function(widget, checked)
  storage.sendWhenLevelNotAllowedChecked = checked
end

checkBox.ptFullCheck.onCheckChange = function(widget, checked)
  storage.sendWhenPtFullChecked = checked
end

checkBox.playerBlockedCheck.onCheckChange = function(widget, checked)
  storage.sendWhenPlayerBlockedChecked = checked
end

checkBox.playerAlreadyInvitedCheck:setChecked(storage.sendWhenPlayerAlreadyInvitedChecked)
checkBox.levelNotAllowedCheck:setChecked(storage.sendWhenLevelNotAllowedChecked)
checkBox.ptFullCheck:setChecked(storage.sendWhenPtFullChecked)
checkBox.playerBlockedCheck:setChecked(storage.sendWhenPlayerBlockedChecked)

addLabel("customMessageInfoLabel", "Message settings:")
local checkBox = {}

checkBox.callMembersInChatCheck = setupUI([[
CheckBox
  id: callMembersInChatCheck
  font: cipsoftFont
  text: Send invite in World chat
  margin-top: 8
]])

checkBox.membersInMessageInfoCheck = setupUI([[
CheckBox
  id: membersInMessageInfoCheck
  font: cipsoftFont
  text: Members
  margin-top: 8
]])

checkBox.experienceInMessageInfoCheck = setupUI([[
CheckBox
  id: experienceInMessageInfoCheck
  font: cipsoftFont
  text: Experience per hour
]])

checkBox.bonusInMessageInfoCheck = setupUI([[
CheckBox
  id: bonusInMessageInfoCheck
  font: cipsoftFont
  text: Bonus
]])

checkBox.maxAndMinLevelInMessageInfoCheck = setupUI([[
CheckBox
  id: maxAndMinLevelInMessageInfoCheck
  font: cipsoftFont
  text: Max and min levels
  margin-bottom: 8
]])

checkBox.callMembersInChatCheck.onCheckChange = function(widget, checked)
  storage.callMembersInChatChecked = checked
end

checkBox.membersInMessageInfoCheck.onCheckChange = function(widget, checked)
  storage.membersInMessageInfoChecked = checked
end

checkBox.experienceInMessageInfoCheck.onCheckChange = function(widget, checked)
  storage.experienceInMessageInfoChecked = checked
end

checkBox.bonusInMessageInfoCheck.onCheckChange = function(widget, checked)
  storage.bonusInMessageInfoChecked = checked
end

checkBox.maxAndMinLevelInMessageInfoCheck.onCheckChange = function(widget, checked)
  storage.maxAndMinLevelInMessageInfoChecked = checked
end

checkBox.callMembersInChatCheck:setChecked(storage.callMembersInChatChecked)
checkBox.membersInMessageInfoCheck:setChecked(storage.membersInMessageInfoChecked)
checkBox.experienceInMessageInfoCheck:setChecked(storage.experienceInMessageInfoChecked)
checkBox.bonusInMessageInfoCheck:setChecked(storage.bonusInMessageInfoChecked)
checkBox.maxAndMinLevelInMessageInfoCheck:setChecked(storage.maxAndMinLevelInMessageInfoChecked)

addLabel("inviteMessage", "Invite message:")
addTextEdit("inviteMessage", storage.inviteMessage or "", function(widget, text)
  storage.inviteMessage = text
end)

addIcon("Auto Party", { item= { id = ICON_ID } , text = "AutoPt", movable=true}, function(icon, isOn)
  partyLeaderHuntWidget.setOn(isOn) 
end)

-- Functions
onTalk(function(name, level, mode, text, channelId, pos)
  local MACRO_IS_DISABLED = not partyLeaderHuntWidget:isOn()
  if MACRO_IS_DISABLED then return end

  local IS_YOURSELF = name == player:getName()
  if IS_YOURSELF then return end

  local IS_ASKING_PARTY = text:lower():find("pt") or (text:lower():find("party") and not text:lower():find("!party"))
  if not IS_ASKING_PARTY then return end

  local isBlocked = isPlayerInBlacklist(name)
  if isBlocked then

    if storage.sendWhenPlayerBlockedChecked then
      g_game.talkPrivate(5, name, name .. ", you are blocked for this party. Send a private message to " .. player:getName() .. " to resolve the situation.")
    end

    return
  end

  for _, spec in ipairs(getSpectators()) do

    if not spec or not spec.getName or not spec.isPartyMember then goto continue end

    local PLAYERS_IS_NEXT = spec:getName() == name
    if not PLAYERS_IS_NEXT then goto continue end
        
    local IS_ALREADY_PARTY_MEMBER = spec:isPartyMember()
    if IS_ALREADY_PARTY_MEMBER then goto continue end

    if spec:getShield() == ALREADY_INVITED_SHIELD then
      if storage.sendWhenPlayerAlreadyInvitedChecked then
        g_game.talkPrivate(5, name, name .. ", I already invited you")
      end
      return
    end

    if level > maxLevel or level < minLevel then
      if storage.sendWhenLevelNotAllowedChecked then
        g_game.talkPrivate(5, name, name .. ", the minimum level is " .. minLevel .. " and the maximum is " .. maxLevel)
      end
      return
    end

    if partyMembersCount >= MAX_PLAYERS then
      if storage.sendWhenPtFullChecked then
        g_game.talkPrivate(5, name, name .. ", the party already has " .. MAX_PLAYERS .. " players for a better use of the shared experience.")
      end
      return
    end

    g_game.partyInvite(spec:getId())

    if not player:isPartySharedExperienceActive() then g_game.partyShareExperience(true) end

    ::continue::
  end

end)

onLoginAdvice(function(text)
  local MACRO_IS_DISABLED = not partyLeaderHuntWidget:isOn()
  if MACRO_IS_DISABLED then return end
  
  setCurrentBonus(text)
  setPartyMembersCount(text)  
  setLevels(text)

  if justForInfo then justForInfo = false return end

  kickInactivePlayers(text)
end)

onCreatureAppear(function(creature)
  local MACRO_IS_DISABLED = not partyLeaderHuntWidget:isOn()
  if MACRO_IS_DISABLED then return end

  if player:isPartyMember() and not player:isPartyLeader() then return end

  if not creature:isPlayer() then return end

  if creature:isLocalPlayer() then return end

  if creature:getShield() == ALREADY_INVITED_SHIELD then return end

  if creature:isPartyMember() then return end

  local localMessage = "If you want to join the party, say 'pt' so I can invite you"

  if storage.membersInMessageInfoChecked  then
    localMessage = localMessage  .. " - Members: " .. partyMembersCount .. "/" .. MAX_PLAYERS
  end

  if storage.experienceInMessageInfoChecked then
    localMessage = localMessage  .. " - Exp/h: " .. expPerHour .. "kk"
  end

  if storage.bonusInMessageInfoChecked then
    localMessage = localMessage  .. " - Bonus: " .. currentBonus
  end

  if storage.maxAndMinLevelInMessageInfoChecked then
    localMessage = localMessage  .. " - Min level: " .. minLevel .. " - Max level: " .. maxLevel
  end

  if talkTime == 0 and partyMembersCount < MAX_PLAYERS then
    say(localMessage)
    talkTime = TALK_TIME
  end

end)

onTextMessage(function(mode, text)
  local MACRO_IS_DISABLED = not partyLeaderHuntWidget:isOn()
  if MACRO_IS_DISABLED then return end

  if text:lower():find("you are now the leader of the party.") or text:lower():find("has joined the party.") or (text:lower():find("has left the party.") and canSeeInfo) then
    justForInfo = true
  end
end)

-- Aux. functions
function setCurrentBonus(text)
  local explode = string.explode(text, "*")
  local valuePart = string.explode(explode[CURRENT_BONUS_INDEX], ":")[VALUE_PART_INDEX]
  currentBonus = valuePart:trim()
end

function setPartyMembersCount(text)
  local explode = string.explode(text, "*")
  local valuePart = string.explode(explode[MEMBERS_COUNT_INDEX], ":")[VALUE_PART_INDEX]
  partyMembersCount = tonumber(valuePart:trim())
end

function setLevels(text)
  minLevel = not storage.minLevel and getMinLevel(text) or storage.minLevel
  maxLevel = not storage.maxLevel and getMaxLevel(text) or storage.maxLevel
end

function getMinLevel(text)
  local explode = string.explode(text, "*")
  return math.ceil(tonumber(string.explode(explode[HIGHER_LEVEL_INDEX], ":")[VALUE_PART_INDEX])*2/3)
end

function getMaxLevel(text)
  local explode = string.explode(text, "*")
  return math.ceil(tonumber(string.explode(explode[LOWER_LEVEL_INDEX], ":")[VALUE_PART_INDEX])*3/2)
end

function getInactivePlayersNames(text)
  local explode = string.explode(text, "*")
  local inactivePlayersNames = string.explode(explode[INACTIVE_PLAYERS_INDEX], ":")[VALUE_PART_INDEX]

  return inactivePlayersNames
end

function kickInactivePlayers(text)
  local inactivePlayersNames = getInactivePlayersNames(text)
  
  if inactivePlayersNames:find(",") then
    local names = string.explode(inactivePlayersNames, ",")
    for i = 1, #names do
      canSeeInfo = false
      schedule(1000 * i, function()
        if i == #names then
          canSeeInfo = true
        end
        sayChannel(getChannelId("party"), "!party kick," .. names[i])
      end)
    end
  elseif inactivePlayersNames ~= "" then
    schedule(1000, function() sayChannel(getChannelId("party"), "!party kick," .. inactivePlayersNames) end)
  end
end

function isPlayerInBlacklist(playerName)
  if not storage.partyBlockedPlayers then return false end

  local blacklist = string.split(storage.partyBlockedPlayers, BREAK_LINE)

  for i = 1, #blacklist do
    if blacklist[i] == playerName then
      return true
    end
  end
  return false
end

function setExpPerHour()
  if g_game.getLocalPlayer().expSpeed == nil or not g_game.getLocalPlayer().expSpeed or g_game.getLocalPlayer().expSpeed == 0 then return 0 end
  local expPerHourLoc = math.floor(g_game.getLocalPlayer().expSpeed * 3600)
  local expPerHourConv = string.format("%.1f", expPerHourLoc / 1000000)
  expPerHour = expPerHourConv
end

function sendMessageInWorldChat()
  local MACRO_IS_DISABLED = not partyLeaderHuntWidget:isOn()
  if MACRO_IS_DISABLED then return end

  if not storage.callMembersInChatChecked then return end

  if partyMembersCount >= MAX_PLAYERS then return end

  if player:isPartyMember() and not player:isPartyLeader() then return end

  local chat = getChannelId("World Chat")
  if not chat then
    info("Chat not found.")
    return
  end
  
  if not storage.inviteMessage and not storage.inviteMessage:len() > 0 then
    warn("You must input the hunting location of the party.")
    return
  end

  local chatMessage = storage.inviteMessage:upper()

  if storage.membersInMessageInfoChecked  then
    chatMessage = chatMessage  .. "   |   MEMBERS: " .. partyMembersCount .. "/" .. MAX_PLAYERS
  end

  if storage.experienceInMessageInfoChecked then
    chatMessage = chatMessage  .. "   |   EXP/H: " .. expPerHour .. "kk"
  end

  if storage.bonusInMessageInfoChecked then
    chatMessage = chatMessage  .. "   |   BONUS: " .. currentBonus
  end

  if storage.maxAndMinLevelInMessageInfoChecked then
    chatMessage = chatMessage  .. "   |   MIN LEVEL: " .. minLevel .. " - MAX LEVEL: " .. maxLevel
  end

  sayChannel(chat, chatMessage)
end