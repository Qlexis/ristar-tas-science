--[[
  Ristar Hitbox Viewer, v5
  By @Sophira (Sophie Hamilton)

  To use this script:

  1. Open your Ristar ROM in BizHawk. (This script supports all known publically-available versions.)
  2. Go to the Tools->Lua Console menu item.
  3. From the resulting window, choose Script->Open Script.
  4. Find this script and load it in.
  6. Enjoy seeing your hitboxes!

  PLEASE NOTE:
  ============
  For hitboxes to display correctly, this script requires data from the
  frame before the one being displayed. Therefore, if the emulator is
  paused when loading this script, hitboxes won't display immediately;
  you'll need to advance to the next frame before they'll show up.

  This may also cause issues if you routinely switch between
  non-consecutive frames (such as during TAS creation) as the script may
  show data from the location you were previously at. Always make sure
  you advance to the next frame for accurate hitbox displays!
]]--

-- ===== You can change these variables if you like.
local ristarHitBoxColor = 0x0000FF
local crossSize = 5
local hitboxTransparency = 128   -- 0 = fully transparent, 255 = fully opaque

-- This script will show the entity handler address in ROM (which is
-- called every frame) associated with any entity whose hitbox you hold
-- the left mouse button on with the mouse.
--
-- In addition, you can have this script dump information about all the
-- entities in a particular list, which includes entity positions in
-- addition to the information you get when holding the mouse button
-- down.  If you want to do this, set debugEnabled to true and set
-- debugList to the appropriate list you want to debug. (See all the
-- "loop_over_entities" lines near the bottom of the script to see what
-- lists are what.)
--
-- Entities are displayed in the order they are encountered when
-- traversing the list.
--
-- Note that the positions displayed will be the delayed positions that
-- correspond to what is being shown this frame, rather than the
-- positions in RAM at that moment. This means that the positions may be
-- incorrect if you switch between non-consecutive frames; see the
-- "PLEASE NOTE" comment above for more information.
local debugEnabled = false
local debugList = 0xDFF2
-- ===== End of changeable variables.

local delayed_ristar = {}
local delayed_entity_positions = {}
local delayed_camera_position = nil

local camera = nil

local hitboxes = {}

local entities_seen_this_frame = {}

local known_roms = {
  -- This table lists all the known versions of Ristar indexed by their
  -- hash, as returned from gameinfo.getromhash() - which annoyingly is
  -- sometimes the MD5 hash and sometimes the SHA-1 hash, depending on
  -- what BizHawk's database has for the game.

  -- Japanese versions
  ["D887378BED61A5BE60664D3FE6559F78CC95D119"] = {
    name = "Ristar Prototype (JP) - July 1, 1994",
    ristar_hitbox_data_addr = 0x1D636,
    handler_base = 0x3A12,
  },
  ["85B82470E5395E96E01A7339C81B60832EA3AB1A"] = {
    name = "Ristar Prototype (JP) - July 18, 1994",
    ristar_hitbox_data_addr = 0x1E7A8,
    handler_base = 0x3B3C,
  },
  ["376F344F8EF5A4F8365867C9E94EFB3E"] = {
    name = "Ristar (JP)",
    ristar_hitbox_data_addr = 0x1E90A,
    handler_base = 0x3C1E,
  },
  ["6F9DD62122960A412A52A398045EE3115569B8C9"] = {
    name = "Ristar (JP) - Sega Forever/Genesis Mini 2/Nintendo Switch",
    ristar_hitbox_data_addr = 0x1E90A,
    handler_base = 0x3C1E,
  },

  -- USA/Europe versions
  ["078846CD7A6F86C6FE71C95B1D13E89E66BD9B25"] = {
    name = "Dexstar Prototype (UE) - August 12, 1994",
    ristar_hitbox_data_addr = 0x1F318,
    handler_base = 0x3B84,
  },
  ["A54553FFA55FBDFC43CFB61AF10CA0A79683EC75"] = {
    name = "Dexstar Prototype (UE) - August 26, 1994",
    ristar_hitbox_data_addr = 0x1F38A,
    handler_base = 0x3B84,
  },
  ["CF0215FEDDD38F19CD2D27BFA96DD4D742BA8BF7"] = {
    name = "Ristar (UE) - August 1994",
    ristar_hitbox_data_addr = 0x1F38A,
    handler_base = 0x3B84,
  },
  ["8AA18CC6E35CC9F019509689491DC711702472E7"] = {
    name = "Ristar (UE) - Sega Forever/Genesis Mini 2/Nintendo Switch",
    ristar_hitbox_data_addr = 0x1F38A,
    handler_base = 0x3B84,
  },
  ["ECF9D0BAC130FED7B6A54A67D7B27DF7"] = {
    name = "Ristar (UE) - September 1994",
    ristar_hitbox_data_addr = 0x1F392,
    handler_base = 0x3B84,
  },
}
local thisrom = nil

-- Ristar's hitbox data is stored in ROM, so we only need to read it once per ROM load; it'll never change.
local ristar_hitbox = {}
local function populate_hitbox_data()
  local ristar_hitbox_base = thisrom.ristar_hitbox_data_addr
  for sprite = 0,31 do
    ristar_hitbox[sprite] = {
      x_offset = memory.read_s8(ristar_hitbox_base + (sprite * 4)),
      y_offset = memory.read_s8(ristar_hitbox_base + (sprite * 4) + 1),
      w_half   = memory.read_s8(ristar_hitbox_base + (sprite * 4) + 2),
      h_half   = memory.read_s8(ristar_hitbox_base + (sprite * 4) + 3)
    }
  end
end

local function draw_hitbox(x, y, w_half, h_half, color, debuginfo)
  if camera ~= nil then   -- all hitboxes have a delayed camera position and we might not have one yet
    local window_x = x - camera.x
    local window_y = y - camera.y

    local origin_x = window_x - w_half + 1
    local origin_y = window_y - h_half + 1
    local width    = w_half * 2 - 2
    local height   = h_half * 2 - 2

    gui.drawLine(window_x - crossSize, window_y,
                 window_x + crossSize, window_y,
                 color | 0xFF000000)
    gui.drawLine(window_x, window_y - crossSize,
                 window_x, window_y + crossSize,
                 color | 0xFF000000)
    gui.drawRectangle(origin_x, origin_y, width, height,
                      color | 0xFF000000, color | (hitboxTransparency << 24))

    table.insert(hitboxes, { origin_x = origin_x,
                             origin_y = origin_y,
                             width = width,
                             height = height,
                             debuginfo = debuginfo })
  end
end

local function delay_camera()
  -- Camera position
  local cam_x = mainmemory.read_s16_be(0xF020)
  local cam_y = mainmemory.read_s16_be(0xF024)

  local result = nil
  if delayed_camera_position ~= nil then
    result = delayed_camera_position
  end
  delayed_camera_position = { x = cam_x, y = cam_y }
  return result
end

local function delay_ristar()
  -- Ristar's information is always stored at 0xC000.
  local ristar_base = 0xC000

  -- Ristar's X/Y position
  local ristar_x = mainmemory.read_s16_be(ristar_base + 0x20)
  local ristar_y = mainmemory.read_s16_be(ristar_base + 0x24)

  local result_pos = nil
  if delayed_ristar.position ~= nil then
    result_pos = delayed_ristar.position
  end
  delayed_ristar.position = { x = ristar_x, y = ristar_y }

  -- Ristar's sprite number
  local ristar_sprite = mainmemory.read_u8(ristar_base + 0x4)

  local result_sprite = nil
  if delayed_ristar.sprite ~= nil then
    result_sprite = delayed_ristar.sprite
  end
  delayed_ristar.sprite = ristar_sprite

  -- Ristar's direction
  local ristar_bitfield = mainmemory.read_u8(ristar_base + 0x2)
  local ristar_direction
  if ristar_bitfield & 0x80 ~= 0 then
    ristar_direction = 1   -- left
  else
    ristar_direction = 0   -- right
  end

  local result_direction = nil
  if delayed_ristar.direction ~= nil then
    result_direction = delayed_ristar.direction
  end
  delayed_ristar.direction = ristar_direction

  return { pos = result_pos, sprite = result_sprite, direction = result_direction }
end

local function delay_entity_pos(entity_base)
  -- Entity's X/Y position
  local entity_x = mainmemory.read_s16_be(entity_base + 0x20)
  local entity_y = mainmemory.read_s16_be(entity_base + 0x24)

  local result = nil
  local delayed_position = delayed_entity_positions[entity_base]
  if delayed_position ~= nil then
    result = delayed_position
  end
  delayed_entity_positions[entity_base] = { x = entity_x, y = entity_y }
  return result
end

local function loop_over_entities(initial, color)
  local entity_base = mainmemory.read_u16_be(initial)

  -- We don't want an infinite loop here, so we have a limit of 100 entities
  local entityLimit = 100
  local entityNum = 0
  while entity_base ~= 0 and entityNum < entityLimit do
    entityNum = entityNum + 1
    entities_seen_this_frame[entity_base] = true

    -- X/Y values are unfortunately delayed a frame from our perspective, so we need to store these and use the previous frame's ones instead.
    -- Note that we don't need to delay width/height values; those are up-to-date.
    -- The camera position is also delayed, but we deal with that in delay_camera.
    local entity_pos = delay_entity_pos(entity_base)

    local handler_index = mainmemory.read_u16_be(entity_base) & 0x7FFC
    local handler_addr  = memory.read_u32_be(thisrom.handler_base + handler_index)

    if entity_pos ~= nil and (entity_pos.x ~= 0 or entity_pos.y ~= 0) then
      -- read the width and height of the entity's hitbox
      local entity_hitbox_w_half = mainmemory.read_s8(entity_base + 0x12)
      local entity_hitbox_h_half = mainmemory.read_s8(entity_base + 0x13)

      -- draw the entity's hitbox cross/rectangle
      draw_hitbox(entity_pos.x, entity_pos.y, entity_hitbox_w_half, entity_hitbox_h_half, color,
                  { initial = initial,
                    entity_base = entity_base,
                    entity_pos = entity_pos,
                    handler_index = handler_index,
                    handler_addr = handler_addr })
    end

    -- Get the address of the next entity to examine; this is not as simple as I'd like.
    -- Note that the 0xDFFA read is from RAM, not ROM, even though BizHawk's disassembly
    -- makes it look like it's from ROM.
    if entity_base == mainmemory.read_u16_be(0xDFFA) then
      entity_base = mainmemory.read_u16_be(entity_base + 0x48)
    end
    entity_base = mainmemory.read_u16_be(entity_base + 0x46)
  end

  if entityNum >= entityLimit then
    gui.text(0, 0, "Ristar Hitbox Viewer: Too many entities! This might be a bug, please let Sophira know.")
  end
end

local function show_debug_info()
  local mouse = input.getmouse()
  local aspectx = (client.screenwidth() - (client.borderwidth() * 2)) / client.bufferwidth()
  local aspecty = (client.screenheight() - (client.borderheight() * 2)) / client.bufferheight()
  local scaled_mousex = mouse.X * aspectx
  local scaled_mousey = mouse.Y * aspecty

  local rel_mousex = mouse.X / client.bufferwidth()

  gui.cleartext()

  local entityNum = 0
  local entities_touched = {}
  local entities_touched_num = 0
  for i, hitbox in ipairs(hitboxes) do
    local info = hitbox.debuginfo
    if info then
      if debugEnabled then
        if debugList == info.initial and info.entity_pos ~= nil then
          entityNum = entityNum + 1
          gui.text(0, entityNum * 15, string.format("%04X: <%d, %d> :: handler %04X -> &%08X", info.entity_base, info.entity_pos.x, info.entity_pos.y, info.handler_index, info.handler_addr))
        end
      end

      -- if the mouse is within the hitbox and being clicked, show debug information
      if (mouse.Left and
          (mouse.X >= hitbox.origin_x) and
          (mouse.X <= hitbox.origin_x + hitbox.width) and
          (mouse.Y >= hitbox.origin_y) and
          (mouse.Y <= hitbox.origin_y + hitbox.height)) then
        table.insert(entities_touched, string.format("(%04X) %04X: handler %04X -> &%08X", info.initial, info.entity_base, info.handler_index, info.handler_addr))
        entities_touched_num = entities_touched_num + 1
      end
    end
  end
  if entities_touched_num > 0 then
    gui.text(client.borderwidth() + scaled_mousex - (rel_mousex * 380),
             client.borderheight() + scaled_mousey - (entities_touched_num * 15) - 1,
             table.concat(entities_touched, "\n")
            )
  end
end

--- ############################
--- # MAIN EXECUTION
--- ############################

local romhash = nil
local lastframe = nil

while true do
  local newhash = gameinfo.getromhash()
  if newhash ~= romhash and newhash ~= nil then
    -- set things up for the newly-detected ROM
    romhash = newhash
    thisrom = known_roms[romhash]
    if thisrom ~= nil then
      console.log("Ristar Hitbox Viewer: detected ROM '" .. thisrom.name .. "'!")
      memory.usememorydomain("MD CART")
      populate_hitbox_data()
    else
      console.log("Ristar Hitbox Viewer: Unsupported ROM detected.")
    end
  end

  local thisframe = emu.framecount()
  if thisframe ~= lastframe then
    -- clear the hitboxes we currently have
    hitboxes = {}

    -- check to see if we have a valid ROM loaded
    if thisrom == nil then
      gui.clearGraphics()
      gui.cleartext()
      gui.text(0, 0, "Ristar Hitbox Viewer error:")
      gui.text(0, 15, "This ROM is not a recognised Ristar ROM variant, and")
      gui.text(0, 30, "this script doesn't currently work with it.")
      gui.text(0, 45, "Please let Sophira know so she can add support!")
    else
      camera = delay_camera()

      -- ##################
      -- Step 1: We plot Ristar's hitbox. This turns out to be quite involved;
      --         most of the work here is done by the populate_hitbox_data and
      --         delay_ristar functions.

      -- get Ristar's delayed position, sprite and direction from the previous frame
      local ristar = delay_ristar()

      if ristar.pos ~= nil then
        -- get the correct hitbox data for the sprite in use; this was already
        -- read by populate_hitbox_data earlier
        local hitbox = ristar_hitbox[ristar.sprite]
        -- Technically, no intersections happen when the sprite index is 0,
        -- but the hitbox data for sprite 0 is all 0s anyway, so whatever.
        -- It's still useful to see Ristar's X/Y positions.

        -- if Ristar is facing left, we need to negate the hitbox X offset
        local xoffset = hitbox.x_offset   -- duplicate the value so that we
                                          -- don't alter the original
        if ristar.direction == 1 then   -- left
          xoffset = -xoffset
        end

        -- draw Ristar's hitbox cross/rectangle
        draw_hitbox(ristar.pos.x + xoffset,
                    ristar.pos.y + hitbox.y_offset,
                    hitbox.w_half,
                    hitbox.h_half,
                    ristarHitBoxColor)
      end

      -- ##################
      -- Step 2: Do the same for each entity that has an X/Y position (not <0,0>).
      -- This is less complex in some ways, but (due to the way we loop) more complex in others.

      -- We keep track of which entities we've seen, so that we can clear out old
      -- delayed entity positions.
      entities_seen_this_frame = {}

      -- There are several lists, as it turns out!
      loop_over_entities(0xDFF2, 0xFF0000)   -- red (mostly enemies)
      loop_over_entities(0xDFF0, 0x00FF00)   -- green (particles, set pieces)
      -- loop_over_entities(0xDFF6, 0xFF00FF)   -- purple (possibly HUD elements?)
      loop_over_entities(0xDFF4, 0x00FFFF)   -- cyan (not seen any of these yet...)
      loop_over_entities(0xDFF8, 0xFFFF00)   -- yellow (mostly secret walls, background elements)

      for addr, _ in pairs(delayed_entity_positions) do
        if not entities_seen_this_frame[addr] then
          -- It's apparently safe to delete keys while you're iterating over them in Lua. The more you know.
          delayed_entity_positions[addr] = nil
        end
      end
      lastframe = thisframe
    end
  end

  if thisrom ~= nil then
    show_debug_info()
  end

  emu.yield()
end

