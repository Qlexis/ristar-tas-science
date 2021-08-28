function get_pattern_from_code(code)
	if code == 0x7 then
		return "tele"
	end
	if code == 0x6 then
		return "move"
	end
	if code == 0xF then
		return "...."
	end
	if code == 0x9 then
		return "BAD!"
	end
	if code == 0x15 then
		return "hole"
	end
	if code == 0x10 then
		return "...."
	end
	if code == 0x14 then
		return "tele"
	end
	if code == 0x11 then
		return "GO!!"
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

local number_of_frames = 0
while true do
	local attack_counter = mainmemory.read_u16_be(0xE634)
	
	local phaseNumber = 1 + mainmemory.read_u8(0xE633)
	local array_of_attacks = 0x3E516
	if phaseNumber == 2 then
		array_of_attacks = 0x3E524
	end
	local x_cam = mainmemory.read_s16_be(0xF030)
	local y_cam = 0
	local x = mainmemory.read_s16_be(0xC9E0) - x_cam
	local y = mainmemory.read_s16_be(0xC9E4)
	if mainmemory.read_u8(0xC9D6) == 0x6 then
		number_of_frames = 3
	end
	if number_of_frames > 0 then
		number_of_frames = number_of_frames - 1
		for i = 0, 40, 1 do
			local x_speed = memory.read_s16_be(0x53666 + 4 * i)
			local y_speed = memory.read_s16_be(0x53666 + 4 * i + 2)
			if x + x_cam < 0x100 then
				x_speed = -x_speed
			end
			if y + y_cam > 0x50 then
				y_speed = -y_speed
			end
			if i == 0 or i == 1 then
				gui.drawLine(x, y, x - x_speed * 100, y - y_speed * 100, 0xFFFFFF00)
			end
			gui.drawLine(x, y, x - x_speed, y - y_speed, 0xFF00FF00)
		end
	end
	gui.pixelText(10, 10, "Greedy's next attacks phase ".. phaseNumber ..": " .. get_next_attacks(attack_counter, array_of_attacks))
	gui.drawLine(0x100 - mainmemory.read_s16_be(0xF030), 20, 0x100 - mainmemory.read_s16_be(0xF030), 150, 0xFF5555FF)
	gui.drawLine(0x100 - mainmemory.read_s16_be(0xF030), 100, 0x100 - mainmemory.read_s16_be(0xF030), 200, 0xFFFFFFFF)
	gui.drawLine(0, 0x50, 300, 0x50, 0xFF5555FF)
	gui.drawLine(0, 32, 300, 32, 0xFFFF0000)
	gui.drawBox(x - 1, y + 1, x + 1, y - 1, 0xFFFFFFFF, 0x400000FF)
	gui.pixelText(10, 200, "Attack counter: " .. string.format("%x", attack_counter))
	emu.frameadvance()
end
