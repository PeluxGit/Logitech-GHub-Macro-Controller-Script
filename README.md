# Logitech GHub Macro Controller Script (Lua)

A lightweight Lua script for Logitech GHub that ensures **only one macro runs at a time**,
with per-key toggle/hold modes and adds abort keys. Works seamlessly across mouse and keyboard G-keys.

## Features

- 🖱️ **Mouse G-buttons** & ⌨️ **Keyboard G-keys**
- 🔁 **Per-key modes**
  - `toggle`: press to start/stop; switches if another macro is running
  - `hold`: starts on press, stops on release (only if the same key started it)
- 🛑 **Abort keys** per device
- 🧠 **Debounce** for press events to prevent double-triggers
- 🔊 **Optional debug logging**
- 🧪 **Debug toggle** to discover key numbers and trace behavior

## Quick Start

1. Open Logitech **GHub** (or **LGS**) and select your device profile.
2. Go to **Scripting** → create a new Lua script.
3. Paste the contents of [`src/ghub_macro_controller.lua`](src/ghub_macro_controller.lua).
4. Edit the **CONFIG** section near the top:
   - Map your desired keys under `macros.mouse` and/or `macros.keyboard`.
   - Optionally set `abort_keys.mouse` / `abort_keys.keyboard`.
   - Adjust `debounce_ms` if needed.
   - **Optional:** turn on debug logging (see below).

### Example Configuration

```lua
-- Mouse examples:
-- [4] = { name = "MyMouseMacroA", mode = "toggle" },
-- [5] = { name = "MyMouseMacroB", mode = "hold"   },

-- Keyboard examples:
-- [1] = { name = "MyKeyboardMacroA", mode = "toggle" },
-- [2] = { name = "MyKeyboardMacroB", mode = "hold"   },

-- Abort keys (stop all macros):
-- abort_keys.mouse = { 6 }
-- abort_keys.keyboard = { 12 }

-- Debug toggles:
-- debug = {
--   log_events   = true,  -- prints each raw OnEvent (helps discover key numbers)
--   log_unmapped = true,  -- logs presses/releases for unmapped keys
--   log_macros   = true,  -- logs start/stop/switch decisions
-- }
```

> 💡 **Tip:** If you use just a string (e.g., `[4] = "MyMacro"`), it defaults to `mode = "toggle"`.

## How It Works

- Pressing a mapped key:
  - If nothing is running → starts that macro.
  - If the **same** macro is running → stops it (toggle off).
  - If a **different** macro is running → switches cleanly.
- **Hold mode:**
  - Starts on press and stops when that same key is released.
  - Releasing another key won’t stop it (ownership tracked).
- **Abort keys:**
  - Stop any running macro immediately and clear ownership.
- **Debounce:**
  - Filters duplicate `PRESS` events for the same key within a short window (default 120 ms).
- **Debug logging:**
  - `log_events` prints `Event=... Arg=...` for every GHUB/LGS event. Use this to **discover key numbers**.
  - `log_unmapped` prints when you press/release a key that isn’t configured.
  - `log_macros` prints internal decisions (play/stop/switch).

## Troubleshooting

- **I don’t know my key numbers (arg values):**  
  Set `CONFIG.debug.log_events = true`, then press your G-keys/buttons. Watch the log for lines like `Event=MOUSE_BUTTON_PRESSED Arg=4` or `Event=G_PRESSED Arg=1`. Use those numbers in your `macros` / `abort_keys` mappings. Turn it off afterward.
- **Nothing happens on press:** ensure the key is defined in `CONFIG.macros` and that the macro **name** matches the one you created in GHub/LGS.
- **Hold macro stops on the wrong release:** check for duplicate key IDs; ownership is per key.
- **Double start/stop in logs:** increase `debounce_ms` (150–180 ms) or set it to `0` to disable.
- **Abort doesn’t work:** verify abort key numbers match your device’s `arg` values. Debug logs help here.

## License

MIT © 2025 PeluxGit
