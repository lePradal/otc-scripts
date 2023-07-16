local MACRO_VERSION = "1.0.1"
print("Wheel of destiny v" .. MACRO_VERSION .. " loaded.")

if isInPz() and storage.destinyWheelCode then
    say(storage.destinyWheelCode)
    warn(":: Destiny whell called!")
end

UI.Separator()

UI.Label("Destiny Wheel code:")
UI.TextEdit(storage.destinyWheelCode or "", function(widget, text)
    storage.destinyWheelCode = text
  end)

UI.Label("Last level applied:")
UI.TextEdit(storage.destinyWheelLastLevel or "500", function(widget, text)
    storage.destinyWheelLastLevel = text
end)