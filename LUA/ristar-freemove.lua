--[[
  Ristar Freemove, v1
  By @Sophira (Sophie Hamilton)

  To use this script:

  1. Open your Ristar ROM in BizHawk 2.9 or later.
     (This script should work on all known versions of Ristar.)
  2. Open TAStudio and the Lua Console from the Tools menu.
  3. In the Lua Console window, choose Script->Open Script.
  4. Find this script and load it in.
  5. During gameplay, press C to stop movement of all entities, and then use the
     D-pad to move Ristar.
  6. Press C again to stop freemove and restore normal movement.

  PLEASE NOTE:
  ============
  Only the game's "apply movement" logic is disabled during freemove, so most
  other game functions will still be active, including grabbing and Ristar
  getting hurt. This means you will not be able to move through walls, and that
  if Ristar "lands" on the ground you will need to press A to "jump" in order to
  be able to move vertically again!
]]--

local known_roms = {
  ["D887378BED61A5BE60664D3FE6559F78CC95D119"] = {
    -- Ristar Prototype (JP) - July 1, 1994
    apply_movement_func = 0x51ea,
  },
  ["85B82470E5395E96E01A7339C81B60832EA3AB1A"] = {
    -- Ristar Prototype (JP) - July 18, 1994
    apply_movement_func = 0x531c,
  },
  ["376F344F8EF5A4F8365867C9E94EFB3E"] = {
    -- Ristar (JP)
    apply_movement_func = 0x5406,
  },
  ["6F9DD62122960A412A52A398045EE3115569B8C9"] = {
    -- Ristar (JP) - Sega Forever/Genesis Mini 2/Nintendo Switch
    apply_movement_func = 0x5406,
  },

  -- ===== USA/Europe versions
  ["078846CD7A6F86C6FE71C95B1D13E89E66BD9B25"] = {
    -- Dexstar Prototype (UE) - August 12, 1994
    apply_movement_func = 0x53fc,
  },
  ["A54553FFA55FBDFC43CFB61AF10CA0A79683EC75"] = {
    -- Dexstar Prototype (UE) - August 26, 1994
    apply_movement_func = 0x53fc,
  },
  ["CF0215FEDDD38F19CD2D27BFA96DD4D742BA8BF7"] = {
    -- Ristar (UE) - August 1994
    apply_movement_func = 0x53fc,
  },
  ["8AA18CC6E35CC9F019509689491DC711702472E7"] = {
    -- Ristar (UE) - Sega Forever/Genesis Mini 2/Nintendo Switch
    apply_movement_func = 0x53fc,
  },
  ["ECF9D0BAC130FED7B6A54A67D7B27DF7"] = {
    -- Ristar (UE) - September 1994
    apply_movement_func = 0x5404,
  },
  ["811F18C256D40BAFBF933C136A6C77FAE5682664"] = {
    -- Ristar (UE) - September 1994 (PS2/PSP Sega Genesis Collection)
    apply_movement_func = 0x5404,
  },
}

function do_freemove()
  local x = mainmemory.read_s16_be(0xC020)
  local y = mainmemory.read_s16_be(0xC024)
  local buttons = joypad.get()
  if buttons["P1 Up"] == true then
    y = y - 4
  end
  if buttons["P1 Down"] == true then
    y = y + 4
  end
  if buttons["P1 Left"] == true then
    x = x - 4
  end
  if buttons["P1 Right"] == true then
    x = x + 4
  end
  mainmemory.write_s16_be(0xC020, x)
  mainmemory.write_s16_be(0xC024, y)
end

freemove_on = false
c_button_held = false

local romhash = gameinfo.getromhash()
local thisrom = known_roms[romhash]
if thisrom == nil then
  console.log("Ristar Freemove: Unsupported ROM detected, please reload the script when a Ristar ROM is loaded.")
  return
end

while true do
  if freemove_on == true then
    do_freemove()
  end

  local buttons = joypad.get()
	if c_button_held == false and buttons["P1 C"] == true then
    c_button_held = true
    if freemove_on == false then
      memory.write_u16_be(thisrom.apply_movement_func, 0x4e75, "MD CART")   -- bypass the apply_movement function
      freemove_on = true
    else
      memory.write_u16_be(thisrom.apply_movement_func, 0x3228, "MD CART")   -- reinstate the original code
      mainmemory.write_u32_be(0xc01c, 0x00000000)   -- reset Ristar's movement
      freemove_on = false
    end
  elseif c_button_held == true and buttons["P1 C"] == false then
    c_button_held = false
  end

	emu.frameadvance()
end
