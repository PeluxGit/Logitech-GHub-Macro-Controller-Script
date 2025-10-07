--[[
Logitech GHub Macro Controller Script (Lua)
Ensures only one macro runs at a time across mouse and keyboard G-keys.
Per-key modes: "toggle" and "hold". Dynamic abort keys. Press debouncing.
Includes optional DEBUG logging to help discover key arg values and trace behavior.
]] --

---------------------
-- CONFIG (edit me)
---------------------
local CONFIG       = {
  macros = {
    -- Map: key -> entry; entry can be:
    --   { name = "MacroName", mode = "toggle" | "hold" }
    --   OR just "MacroName" (defaults to "toggle")
    mouse = {
      -- [4] = { name = "MyMouseMacroA", mode = "toggle" },
      -- [5] = { name = "MyMouseMacroB", mode = "hold"   },
    },
    keyboard = {
      -- [1] = { name = "MyKeyboardMacroA", mode = "toggle" },
      -- [2] = { name = "MyKeyboardMacroB", mode = "hold"   },
    }
  },

  -- Any of these keys will abort the running macro (per device).
  abort_keys = {
    mouse = {
      -- 6,  -- e.g., mouse G6
    },
    keyboard = {
      -- 12, -- e.g., keyboard G12
    },
  },

  -- Debounce (ms) for PRESS events of the same key (0 disables).
  debounce_ms = 120,

  -- DEBUG controls: turn these on to help identify keys and trace behavior.
  debug = {
    -- When true, log every raw GHUB/LGS event as it arrives (OnEvent).
    log_events   = false,
    -- When true, log presses/releases for keys that are NOT mapped.
    log_unmapped = false,
    -- When true, log internal state transitions (play/stop/switch).
    log_macros   = false,
  }
}

---------------------
-- INTERNAL STATE
---------------------
local macroRunning = nil -- macro name currently running (or nil)
local lastPressAt  = { mouse = 0, keyboard = 0 }
local lastKey      = { mouse = -1, keyboard = -1 }

-- Tracks which key "owns" the running macro when mode == "hold"
local holdOwner    = { device = nil, key = nil, name = nil }

---------------------
-- UTILITIES
---------------------
local function dprint(enabled, fmt, ...)
  if enabled then OutputLogMessage(fmt, ...) end
end

local function toSet(list)
  local s = {}
  for _, v in ipairs(list or {}) do s[v] = true end
  return s
end

local ABORT_SET = {
  mouse = toSet(CONFIG.abort_keys.mouse),
  keyboard = toSet(CONFIG.abort_keys.keyboard),
}

local function now() return GetRunningTime() end

local function isDebounced(device, key)
  local db = CONFIG.debounce_ms or 0
  if db <= 0 then return false end
  local t = now()
  if key == lastKey[device] and (t - lastPressAt[device]) < db then
    return true
  end
  lastKey[device] = key
  lastPressAt[device] = t
  return false
end

local function normalizeEntry(entry)
  if type(entry) == "string" then
    return { name = entry, mode = "toggle" }
  elseif type(entry) == "table" then
    return { name = entry.name, mode = entry.mode or "toggle" }
  else
    return nil
  end
end

local function stopAll(reason)
  if macroRunning ~= nil then
    dprint(CONFIG.debug.log_macros, "Stopping Macro: %s (%s)\n", macroRunning, reason or "n/a")
  else
    dprint(CONFIG.debug.log_macros, "No macro to stop. (%s)\n", reason or "n/a")
  end
  macroRunning = nil
  holdOwner.device, holdOwner.key, holdOwner.name = nil, nil, nil
  AbortMacro()
end

local function play(name, device, key, mode)
  dprint(CONFIG.debug.log_macros, "Running Macro: %s [%s/%s] (%s)\n", name, device, tostring(key), mode)
  macroRunning = name
  if mode == "hold" then
    holdOwner.device, holdOwner.key, holdOwner.name = device, key, name
  else
    holdOwner.device, holdOwner.key, holdOwner.name = nil, nil, nil
  end
  PlayMacro(name)
end

---------------------
-- CORE HANDLERS
---------------------
local function handlePress(device, key)
  if isDebounced(device, key) then return end

  -- Abort keys take priority
  if ABORT_SET[device] and ABORT_SET[device][key] then
    dprint(CONFIG.debug.log_macros, "[Abort] %s key %d\n", device, key)
    stopAll("abort-key")
    return
  end

  local map   = CONFIG.macros[device] or {}
  local entry = normalizeEntry(map[key])
  if not entry or not entry.name then
    dprint(CONFIG.debug.log_unmapped, "[UNMAPPED PRESS] %s key %d\n", device, key)
    return
  end

  local name, mode = entry.name, entry.mode

  if mode == "hold" then
    if macroRunning == name then
      -- Already running; ignore repeated press.
      return
    end
    if macroRunning ~= nil then
      dprint(CONFIG.debug.log_macros, "Switching (press) from %s to %s\n", macroRunning, name)
      AbortMacro()
    end
    play(name, device, key, mode)
    return
  end

  -- toggle behavior
  if macroRunning == name then
    dprint(CONFIG.debug.log_macros, "Toggling OFF: %s\n", name)
    stopAll("toggle-off")
  elseif macroRunning == nil then
    play(name, device, key, mode)
  else
    dprint(CONFIG.debug.log_macros, "Switching (press) from %s to %s\n", macroRunning, name)
    AbortMacro()
    play(name, device, key, mode)
  end
end

local function handleRelease(device, key)
  local map   = CONFIG.macros[device] or {}
  local entry = normalizeEntry(map[key])
  if not entry then
    dprint(CONFIG.debug.log_unmapped, "[UNMAPPED RELEASE] %s key %d\n", device, key)
    return
  end
  if entry.mode ~= "hold" then return end

  if holdOwner.device == device and holdOwner.key == key and macroRunning == holdOwner.name then
    dprint(CONFIG.debug.log_macros, "Releasing %s/%d -> stopping %s\n", device, key, holdOwner.name)
    stopAll("hold-release")
  end
end

---------------------
-- EVENT ROUTER
---------------------
function OnEvent(event, arg)
  dprint(CONFIG.debug.log_events, "Event=%s Arg=%s\n", tostring(event), tostring(arg))

  if event == "PROFILE_ACTIVATED" then
    macroRunning = nil
    holdOwner.device, holdOwner.key, holdOwner.name = nil, nil, nil
    return
  end

  -- Mouse
  if event == "MOUSE_BUTTON_PRESSED" then
    handlePress("mouse", arg); return
  elseif event == "MOUSE_BUTTON_RELEASED" then
    handleRelease("mouse", arg); return
  end

  -- Keyboard G-keys
  if event == "G_PRESSED" then
    handlePress("keyboard", arg); return
  elseif event == "G_RELEASED" then
    handleRelease("keyboard", arg); return
  end
end
