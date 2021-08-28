
while true do
	local timer_before_attack = mainmemory.read_u16_be(0xE636)
	local direction = "left"
	if mainmemory.read_u8(0xE63A) == 0 then
		direction = "right"
	end
	if timer_before_attack == 0 then
		direction = ""
	end
	gui.pixelText(10, 20, "Ohsat will go ... " .. direction)
	gui.pixelText(10, 30, "Ohsat will go in: " .. timer_before_attack)
	emu.frameadvance()
end
