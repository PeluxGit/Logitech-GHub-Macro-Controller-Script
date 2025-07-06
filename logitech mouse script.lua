local macros = {}
---------------------------------------------------------------
-- Edit this macro list like this
-- macro["G-KEY the macro should be assigned"] = "Macro name"
---------------------------------------------------------------
macros[4] = "numminus"
macros[5] = "numplus"
---------------------------------------------------------------
-- No need to touch here
---------------------------------------------------------------
local macroRunning = nil
function handleGKey(key)
    --OutputLogMessage("Key pressed: %s\n", key);
    if (key == 6) then
        OutputLogMessage("Stopping All Macros\n");
        macroRunning = nil
        AbortMacro()
    elseif (macros[key] ~= nil) then
        if (macroRunning == macros[key]) then
            OutputLogMessage("Stopping Macro: %s\n", macros[key]);
            macroRunning = nil
            AbortMacro()
        elseif (macroRunning == nil) then
            OutputLogMessage("Running Macro: %s\n", macros[key]);
            macroRunning = macros[key]
            PlayMacro(macros[key])
        elseif (macroRunning ~= nil) then
            OutputLogMessage("Stopping Macro: %s\n", macroRunning);
            AbortMacro()
            OutputLogMessage("Running Macro: %s\n", macros[key]);
            macroRunning = macros[key]
            PlayMacro(macros[key])            
        else
            OutputLogMessage("Another macro is running: %s\n", macroRunning);
        end
    end
end
function OnEvent(event, arg)
    if (event == "MOUSE_BUTTON_PRESSED") then
        OutputLogMessage("Mouse button pressed %s\n", arg);
        handleGKey(arg)
    end
end