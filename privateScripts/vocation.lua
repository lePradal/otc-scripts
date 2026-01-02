local vocations = {
    [0] = { fullname= "No Vocation", name= "None", abbreviation= "N", familiarSummonSpell= nil },
    [1] = { fullname= "Knight", name= "Knight", abbreviation= "K", familiarSummonSpell= "eq" },
    [2] = { fullname= "Paladin", name= "Paladin", abbreviation= "P", familiarSummonSpell= "sac" },
    [3] = { fullname= "Sorcerer", name= "Sorcerer", abbreviation= "S", familiarSummonSpell= "ven" },
    [4] = { fullname= "Druid", name= "Druid", abbreviation= "D", familiarSummonSpell= "dru" },
    [5] = { fullname= "Monk", name= "Monk", abbreviation= "M", familiarSummonSpell= "tio"  },
    [6] = { fullname= "Elite Knight", name= "E. Knight", abbreviation= "EK", familiarSummonSpell= "eq" },
    [7] = { fullname= "Royal Paladin", name= "R. Paladin", abbreviation= "RP", familiarSummonSpell= "sac" },
    [8] = { fullname= "Master Sorcerer", name= "M. Sorcerer", abbreviation= "MS", familiarSummonSpell= "ven" },
    [9] = { fullname= "Elder Druid", name= "E. Druid", abbreviation= "ED", familiarSummonSpell= "dru" },
    [10] = { fullname= "Exalted Monk", name= "E. Monk", abbreviation= "EM", familiarSummonSpell= "tio" }
}

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

function getVocationFamiliarSummonSpell(vocationId)
    return vocations[vocationId].familiarSummonSpell or nil
end