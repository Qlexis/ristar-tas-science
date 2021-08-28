function get_offset_from_health(awwwawawawaowoaueck_health)
	local health_offset = 0
	if awwwawawawaowoaueck_health > 2 then
		health_offset = 8
	end
	if awwwawawawaowoaueck_health > 4 then
		health_offset = 16
	end
	if awwwawawawaowoaueck_health > 6 then
		health_offset = 24
	end
	return health_offset
end

function get_pattern_from_code(code)
	if code == 0x0F then
		return "dive"
	end
	if code == 0x15 then
		return "...."
	end
	if code == 0x14 then
		return "BAD!"
	end
	if code == 0x16 then
		return "fall"
	end
	return "unknown pattern"
end

function get_next_attack_from_current_state(offset, array)
	return get_pattern_from_code(memory.read_u8(array + offset))
end

function get_next_attacks(health_offset, attack_counter, array)
	local return_string = "<"
	local counter = attack_counter
	for i = 0, 3, 1 do
		if i == 0 then
			return_string = "<" ..get_next_attack_from_current_state(health_offset + counter, array)
		else
			return_string = return_string .. ", "
				.. get_next_attack_from_current_state(health_offset + counter, array)
		end
		counter = counter + 1
		if counter == 8 then
			counter = 0
		end
	end
	return_string = return_string .. ">"
	return return_string
end

while true do
	local attack_counter = mainmemory.read_u16_be(0xE62E)
	local awwwawawawaowoaueck_health = mainmemory.read_u8(0xC906)
	local health_offset = get_offset_from_health(awwwawawawaowoaueck_health)
	
	gui.pixelText(10, 10, "Awaueck's next close attacks: " .. get_next_attacks(health_offset, attack_counter, 0x31584))
	gui.pixelText(10, 20, "Awaueck's next far attacks:   " .. get_next_attacks(health_offset, attack_counter, 0x315A4))
	
	gui.pixelText(10, 200, "Attack counter: " .. string.format("%x", attack_counter))
	emu.frameadvance()
end
