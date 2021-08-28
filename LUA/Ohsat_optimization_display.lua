local ohsat_coming_time = 0-0
local ohsat_was_coming = false
local ohsat_coming_time_gain = 0-0
while true do
	local ohsat_attack_pattern = mainmemory.read_s8(0xCAC6) % 128
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
	emu.frameadvance()
end
