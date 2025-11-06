-- Terminal color constants using ANSI escape codes

local COLORS = {
	Print = "",
	Info = "\27[36m", -- Cyan
	Warning = "\27[33m", -- Yellow
	Error = "\27[31m", -- Red
	Success = "\27[32m", -- Green
	Green = "\27[32m", -- Green
	Red = "\27[31m", -- Red
	Grey = "\27[90m", -- Grey/Dim
	Reset = "\27[0m",
}

return COLORS
