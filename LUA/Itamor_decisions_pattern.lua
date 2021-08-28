function get_pattern_from_code(code)
	if code == 0x2 then
		return "grab."
	end
	if code == 0xD then
		return "grab?"
	end
	if code == 0x4 then
		return "blizz"
	end
	if code == 0x6 then
		return "SUCK!"
	end
	if code == 0x5 then
		return "throw"
	end
	if code == 0x7 then
		return "JUMP!"
	end
	if code == 0xFF then
		return "<<<<"
	end
	return "unknown pattern"
end

function get_next_attack_from_current_state(offset, array)
	return get_pattern_from_code(memory.read_u8(array + offset))
end

function get_next_attacks(attack_counter, array)
	local return_string = "<"
	local counter = attack_counter
	for i = 0, 3, 1 do
		local attack_type = get_next_attack_from_current_state(counter, array)
		if attack_type == "<<<<" then
			counter = 0
			attack_type = get_next_attack_from_current_state(counter, array)
		end
		if i == 0 then
			return_string = "<" .. attack_type
		else
			return_string = return_string .. ", "
				.. attack_type
		end
		counter = counter + 1
	end
	return_string = return_string .. ">"
	return return_string
end

while true do
	local attack_counter = mainmemory.read_u16_be(0xE65C)
	
	local phaseNumber = 1 + mainmemory.read_u8(0xE633)
	local array_of_attacks = 0x34D64
	gui.pixelText(10, 10, "Itamor's next attacks phase ".. phaseNumber ..": " .. get_next_attacks(attack_counter, array_of_attacks))
	gui.pixelText(10, 200, "Attack counter: " .. string.format("%x", attack_counter))
	emu.frameadvance()
end
