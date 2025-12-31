local infoTime = 0
local talkTime = 0
local maxLevel = 0
local minLevel = 0
local justForInfo = true
local canSeeInfo = true
local partyMembersCount = 0

local partyLeaderHuntWidget = macro(1000, "Lider de party", function()
  if not player:isPartyLeader() then
    justForInfo = true
    partyMembersCount = 0
    return
  end
  if justForInfo and canSeeInfo then
    sayChannel(getChannelId("party"), "!party info")
    return
  end
  if talkTime > 0 then
    talkTime = talkTime - 1
  end
  if player:getShield() == 10 then
    infoTime = infoTime + 1
    if infoTime >= 20 then
      sayChannel(getChannelId("party"), "!party info")
      infoTime = 0
    end
  else
    infoTime = 0
  end
end)

addLabel("maxLevel", "Max Level:")
addTextEdit("maxLevel", storage.maxLevel or "", function(widget, text)
  if tonumber(text) then
    maxLevel = tonumber(text)
  else
    sayChannel(getChannelId("party"), "!party info")
  end
  storage.maxLevel = tonumber(text)
end)

addLabel("minLevel", "Min Level:")
addTextEdit("minLevel", storage.minLevel or "", function(widget, text)
  if tonumber(text) then
    minLevel = tonumber(text)
  else
    sayChannel(getChannelId("party"), "!party info")
  end
  storage.minLevel = tonumber(text)
end)

onTalk(function(name, level, mode, text, channelId, pos)
  if partyLeaderHuntWidget:isOn() then
    if name == player:getName() then return end
    if text:lower():find("pt") or (text:lower():find("party") and not text:lower():find("!party")) then
      for _, spec in ipairs(getSpectators()) do
        if spec:getName() == name then
          if spec:isPartyMember() then return end
          if spec:getShield() == 2 then
            g_game.talkPrivate(5, name, name .. ", Ya te invite")
            return
          end
          if level > maxLevel or level < minLevel then
            g_game.talkPrivate(5, name, name .. ", el nivel minimo es " .. minLevel .. " y el nivel maximo es " .. maxLevel)
            return
          end
          if partyMembersCount >= 30 then
            g_game.talkPrivate(5, name, name .. ", ya estamos completos, son 30 maximo por party")
            return
          end
          g_game.partyInvite(spec:getId())
        end
      end
    end
  end
end)

onLoginAdvice(function(text)
  if partyLeaderHuntWidget:isOn() then
    local explode1 = string.explode(text, "*")
    local explode2 = string.explode(explode1[8], ":")[2]
    if not storage.maxLevel then
      maxLevel = math.ceil(tonumber(string.explode(explode1[4], ":")[2])*3/2)
    else
      maxLevel = storage.maxLevel
    end
    if not storage.minLevel then
      minLevel = math.ceil(tonumber(string.explode(explode1[3], ":")[2])*2/3)
    else
      minLevel = storage.minLevel
    end
    partyMembersCount = tonumber(string.explode(explode1[2], ":")[2])
    if justForInfo then
      justForInfo = false
      return
    end
    if explode2:find(",") then
      local names = string.explode(explode2, ",")
      for i = 1, #names do
        canSeeInfo = false
        schedule(1000 * i, function()
          if i == #names then
            canSeeInfo = true
          end
          sayChannel(getChannelId("party"), "!party kick," .. names[i])
        end)
      end
    elseif explode2 ~= "" then
      schedule(1000, function() sayChannel(getChannelId("party"), "!party kick," .. explode2) end)
    end
  end
end)

onCreatureAppear(function(creature)
  if partyLeaderHuntWidget:isOn() then
    if not creature:isPlayer() then return end
    if creature:isLocalPlayer() then return end
    if creature:getShield() == 2 then return end
    if creature:isPartyMember() then return end
    if talkTime == 0 and partyMembersCount < 30 then
      say("Si quieres unirte, solo tienes que decir 'pt' y acepta la solicitud de party")
      talkTime = 15
    end
  end
end)

onTextMessage(function(mode, text)
  if partyLeaderHuntWidget:isOn() then
    if text:lower():find("you are now the leader of the party.") or text:lower():find("has joined the party.") or (text:lower():find("has left the party.") and canSeeInfo) then
      justForInfo = true
    end
  end
end)
