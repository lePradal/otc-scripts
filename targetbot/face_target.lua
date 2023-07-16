local MACRO_VERSION = "1.0.0"
print("Face target v" .. MACRO_VERSION .. " loaded.")

local MACRO_TIME = 200

macro(MACRO_TIME, function()
    local target = g_game.getAttackingCreature()
    if not target then return end

    local position = target:getPosition()
    if not position then return end

    local xDiff = position.x > posx()
    local yDiff = position.y > posy()
    local isXBigger = math.abs(position.x - posx()) > math.abs(position.y - posy())

    local dir = player:getDirection()
    if xDiff and isXBigger then  
        if dir ~= 1 then turn(1) end
        return
    elseif not xDiff and isXBigger then 
        if dir ~= 3 then turn(3) end
        return
    elseif yDiff and not isXBigger then  
        if dir ~= 2 then turn(2) end
        return
    elseif not yDiff and not isXBigger  then 
        if dir ~= 0 then turn(0) end
        return
    end
end)