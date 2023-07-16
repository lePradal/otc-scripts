-- -- local sorcerer = 3
-- -- local druid = 4

-- local sorcerer = 2
-- local druid = 2
-- if player:getVocation() == sorcerer or player:getVocation() == druid then
--     UI.Separator()

--     macro(5000, "Summon Creature", function()
--         local enoughMana = manapercent() > storage.summonMinMana
--         local creature = storage.summonCreatureName
--         if enoughMana and not isInPz() and creature then
--             local spell = "utevo res \"" .. spell_end .. "\""
--             castSpell(spell)
--         end
--     end)

--     UI.Label("Creature:")
--     UI.TextEdit(storage.summonCreatureName or "fire elemental", function(widget, text)
--         storage.summonCreatureName = text
--       end)
    
--     UI.Label("Min. mana %:")
--     UI.TextEdit(storage.summonMinMana or "90", function(widget, text)
--         storage.summonMinMana = tonumber(text)
--       end)
-- end

-- ----------------------------------------------------

-- local sorcerer = 2
-- local druid = 2

-- local summonName = "Massive Water Elemental"

-- function isSummonOnScreen()
--     for _, spec in ipairs(getSpectators()) do
--         if not spec:isPlayer() and spec:getName() == summonName then
--      return true
--     end
--    end
-- end

-- macro(100, "Summon Creature", function()
--       if not isSummonOnScreen() then
--           say('utevo res "massive water elemental"')
--    end
-- end)


-- if player:getVocation() == sorcerer or player:getVocation() == druid then
--     UI.Separator()

--     macro(1000, "Summon Creature", function()
--         local enoughMana = manapercent() > storage.summonMinMana
--         local creature = storage.summonCreatureName
--         if enoughMana and not isInPz() and creature then
--             local spell = "utevo res \"" .. creature .. "\""
--             castSpell(spell)
--         end
--     end)

--     UI.Label("Creature:")
--     UI.TextEdit(storage.summonCreatureName or "fire elemental", function(widget, text)
--         storage.summonCreatureName = text
--       end)
    
--     UI.Label("Min. mana %:")
--     UI.TextEdit(storage.summonMinMana or "90", function(widget, text)
--         storage.summonMinMana = tonumber(text)
--       end)
-- end

-- ----------------------------------------


-- macro(1000, "Teste Espectadores", function()
--     for _, spec in ipairs(getSpectators()) do
--         if not spec:isPlayer() then
--             say(tostring(spec:getName()))
--             say(tostring(spec:isCreature()))
--         end
--     end
-- end)