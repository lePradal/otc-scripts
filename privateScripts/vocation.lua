local vocations = {
    [0] = { base= "none", fullname= "No Vocation", name= "None", abbreviation= "N" },
    [1] = { base= "knight", fullname= "Knight", name= "Knight", abbreviation= "K" },
    [2] = { base= "paladin", fullname= "Paladin", name= "Paladin", abbreviation= "P" },
    [3] = { base= "sorcerer", fullname= "Sorcerer", name= "Sorcerer", abbreviation= "S" },
    [4] = { base= "druid", fullname= "Druid", name= "Druid", abbreviation= "D" },
    [5] = { base= "monk", fullname= "Monk", name= "Monk", abbreviation= "M" },
    [6] = { base= "knight", fullname= "Elite Knight", name= "E. Knight", abbreviation= "EK" },
    [7] = { base= "paladin", fullname= "Royal Paladin", name= "R. Paladin", abbreviation= "RP" },
    [8] = { base= "sorcerer", fullname= "Master Sorcerer", name= "M. Sorcerer", abbreviation= "MS" },
    [9] = { base= "druid", fullname= "Elder Druid", name= "E. Druid", abbreviation= "ED" },
    [10] = { base= "monk", fullname= "Exalted Monk", name= "E. Monk", abbreviation= "EM" }
}

local spellsByBase = {
    ["knight"]      = { familiar = "utevo gran res eq",  haste = "utani hur"      },
    ["paladin"]     = { familiar = "utevo gran res sac", haste = "utani hur"      },
    ["sorcerer"]    = { familiar = "utevo gran res ven", haste = "utani gran hur" },
    ["druid"]       = { familiar = "utevo gran res dru", haste = "utani gran hur" },
    ["monk"]        = { familiar = "utevo gran res tio", haste = "utani gran hur" }
}

function getVocationBase(vocationId)
    local voc = vocations[vocationId]
    return voc and voc.base or "none"
end

function getVocation(vocationId)
    return vocations[vocationId] or nil
end

function getVocationName(vocationId)
    return vocations[vocationId].name or nil
end

function getVocationFullName(vocationId)
    return vocations[vocationId].fullname or nil
end

function getVocationAbbreviation(vocationId)
    return vocations[vocationId].abbreviation or nil
end

function getVocationSpells(vocationId)
    local id = vocationId
    local base = getVocationBase(id)
    
    return spellsByBase[base] or spellsByBase["none"]
end

function getSpellByType(spellType, vocationId)
    local spells = getVocationSpells(vocationId)
    return spells[spellType] or nil
end

function getVocationFamiliarSummonSpell(vocationId)
    return getSpellByType("familiar", vocationId)
end

function getVocationHasteSpell(vocationId)
    return getSpellByType("haste", vocationId)
end