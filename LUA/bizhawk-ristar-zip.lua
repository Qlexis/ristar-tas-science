function main()
	if (emu.framecount() % 10) == 0 then
		local x = mainmemory.read_s16_be(0xC020)
		local y = mainmemory.read_s16_be(0xC024)
		local buttons = joypad.get()
		if buttons["P2 Up"] == true then
			y = y - 100
		end
		if buttons["P2 Down"] == true then
			y = y + 100
		end
		if buttons["P2 Left"] == true then
			x = x - 100
		end
		if buttons["P2 Right"] == true then
			x = x + 100
		end
		mainmemory.write_s16_be(0xC020, x)
		mainmemory.write_s16_be(0xC024, y)
	end
end

while true do
	main()
	emu.frameadvance()
end
