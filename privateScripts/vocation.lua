local vocations = {
    [0] = { fullname= "No Vocation", name= "None", abbreviation= "N" },
    [1] = { fullname= "Knight", name= "Knight", abbreviation= "K" },
    [2] = { fullname= "Paladin", name= "Paladin", abbreviation= "P" },
    [3] = { fullname= "Sorcerer", name= "Sorcerer", abbreviation= "S" },
    [4] = { fullname= "Druid", name= "Druid", abbreviation= "D" },
    [5] = { fullname= "Monk", name= "Monk", abbreviation= "M" },
    [6] = { fullname= "Elite Knight", name= "E. Knight", abbreviation= "EK" },
    [7] = { fullname= "Royal Paladin", name= "R. Paladin", abbreviation= "RP" },
    [8] = { fullname= "Master Sorcerer", name= "M. Sorcerer", abbreviation= "MS" },
    [9] = { fullname= "Elder Druid", name= "E. Druid", abbreviation= "ED" },
    [10] = { fullname= "Exalted Monk", name= "E. Monk", abbreviation= "EM" }
}
function getVocationName(vocationId)
    return vocations[vocationId].name or "Unknown Vocation"
end

function getVocationFullName(vocationId)
    return vocations[vocationId].fullname or "Unknown Vocation"
end

function getVocationAbbreviation(vocationId)
    return vocations[vocationId].abbreviation or "Unknown Vocation"
end