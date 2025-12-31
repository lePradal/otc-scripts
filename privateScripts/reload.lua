local ICON_ITEM_ID = 6108 -- Backpack

local reloadIcon = addIcon("reloadIcon", { text="Reload", item = {id = ICON_ITEM_ID, count = 1}, switchable=false, moveable=true }, function()
    reload()
end)

reloadIcon:setSize({height=50,width=250})
reloadIcon:breakAnchors()
reloadIcon:move(80, 30)