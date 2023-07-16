local MACRO_VERSION = "1.0.0"
print("Auto accept party v" .. MACRO_VERSION .. " loaded.")

local MACRO_TIME = 500
local GRAY_SHIELD_ID = 11
local LEADER_INVITING_SHIELD_ID = 1
local BREAK_LINE = "\n"

if storage.invitingPartySentenceSnippets == nil or not storage.invitingPartySentenceSnippets then
  storage.invitingPartySentenceSnippets = "invite"
end

local autoAcceptPt = macro(MACRO_TIME, "Auto Accept Party",function(macro) 
  if player:isPartyMember() then macro.setOff() return end

  for s, spec in pairs(getSpectators(false)) do
    if spec:getShield() == LEADER_INVITING_SHIELD_ID then
      g_game.partyJoin(spec:getId())
      TargetBot.setOn(true)
      delay(1000)
    end
  end
end)


onTalk(function(name, level, mode, text, channelId, pos)
  local IS_YOURSELF = name == player:getName()
  if IS_YOURSELF then return end

  local isInviting = isInvitingToParty(text)
  local isAskingParty = text:lower():find("pt") or (text:lower():find("party") and not text:lower():find("!party"))
  
  if not isInviting and not isAskingParty then return end

  askPt()
end)

onCreatureAppear(function(creature)
  askPt()
end)

onTextMessage(function(mode, text)
  if text:lower():find("kicked you") or text:lower():find("been disbanded") then
    autoAcceptPt:setOn(true)
  end

  if text:lower():find("left the party") then
    autoAcceptPt:setOn(false)
  end
end)

function askPt()
  local MACRO_IS_DISABLED = not autoAcceptPt:isOn()
  if MACRO_IS_DISABLED then return end

  if not thereArePartyPlayersNearby() then return end
  if player:isPartyMember() then return end
  if player:getShield() == ALREADY_INVITED_SHIELD then return end

  say("pt")
  delay(3000)
end

function thereArePartyPlayersNearby()
  for _, spec in ipairs(getSpectators()) do
    if spec:isPlayer() and spec:getShield() == GRAY_SHIELD_ID then
      return true
    end
  end

  return false
end

function isInvitingToParty(text)
  if not storage.invitingPartySentenceSnippets then return false end
  local invitingSnippets = string.split(storage.invitingPartySentenceSnippets, BREAK_LINE)

  for i = 1, #invitingSnippets do
    if text:lower():find(invitingSnippets[i]:lower()) then
      return true
    end
  end
  return false
end