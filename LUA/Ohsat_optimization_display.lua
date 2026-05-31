local ohsat_base
local ohsat_coming_time = 0-0
local ohsat_was_coming = false
local ohsat_coming_time_gain = 0-0

local function find_handler_num_in_list(initial, handler_to_find)
	local found_objects = {}
	local entity_base = mainmemory.read_u16_be(initial)

	-- We don't want an infinite loop here, so we have a limit of 100 entities searched per list
	local entityLimit = 100
	local entityNum = 0
	local stopaddr = mainmemory.read_u16_be(0xDFFA)
	while entity_base ~= 0 and entityNum < entityLimit do
		entityNum = entityNum + 1

		local handler_num = mainmemory.read_u16_be(entity_base) & 0x7FFC
		if handler_num == handler_to_find then
			table.insert(found_objects, entity_base)
		end

		-- Get the address of the next entity to examine
		if entity_base == stopaddr then
			entity_base = mainmemory.read_u16_be(entity_base + 0x48)
		end
		entity_base = mainmemory.read_u16_be(entity_base + 0x46)
	end

	return found_objects
end

local function find_handler_num(handler_to_find)
	local base_addresses = {0xDFF0, 0xDFF2, 0xDFF4, 0xDFF6, 0xDFF8}
	local all_found_objects = {}
	for _, address in ipairs(base_addresses) do
		local found_in_list = find_handler_num_in_list(address, handler_to_find)
		for _, found in ipairs(found_in_list) do
			table.insert(all_found_objects, found)
		end
	end
	return all_found_objects
end

while true do
	local ohsat_addresses = find_handler_num(0x5B8)
	-- there should only ever be one, so...
	if #ohsat_addresses > 0 then
		local new_base = ohsat_addresses[1]   -- arrays in Lua begin at 1, not 0
		if ohsat_base ~= new_base then
			ohsat_coming_time = 0-0
			ohsat_was_coming = false
			ohsat_coming_time_gain = 0-0
			ohsat_base = new_base
		end
	else
		gui.pixelText(10, 20, "Ohsat not found.")
		ohsat_base = nil
	end

	if ohsat_base then
		local ohsat_attack_pattern = mainmemory.read_s8(ohsat_base + 0x16) % 128
		if ohsat_attack_pattern == 1 or ohsat_attack_pattern == 2 then
			if not ohsat_was_coming then
				ohsat_was_coming = true
				ohsat_coming_time = 0
			end
			ohsat_coming_time = ohsat_coming_time + 1
		else
			if ohsat_was_coming then
				ohsat_was_coming = false
				ohsat_coming_time_gain = ohsat_coming_time_gain + 80 - ohsat_coming_time
			end
		end
		gui.pixelText(10, 20, "time spent with Ohsat going to the center: " .. ohsat_coming_time)
		gui.pixelText(10, 30, "time gained from Ohsat centering: " .. ohsat_coming_time_gain)
	end
	emu.frameadvance()
end
