-- Output utilities for colored terminal printing

local COLORS = require("./colors")
local constants = require("./constants")
local stdio = require("@lune/stdio")

local function printColored(message: string, color: string?)
	if color then
		stdio.write(`{color}{message}{COLORS.Reset}\n`)
	else
		stdio.write(`{message}\n`)
	end
end

local function printError(message: string)
	printColored(`Error: {message}`, COLORS.Error)
end

local function printWarning(message: string)
	printColored(`Warning: {message}`, COLORS.Warning)
end

local function printInfo(message: string)
	printColored(message, COLORS.Info)
end

local function formatBitset(bitsetValue: number, filterMask: number?): string
	local parts = {}
	local contextOrder = {
		{ name = "studio", bit = constants.CONTEXT_BITS.isStudio },
		{ name = "server", bit = constants.CONTEXT_BITS.isServer },
		{ name = "client", bit = constants.CONTEXT_BITS.isClient },
		{ name = "edit", bit = constants.CONTEXT_BITS.isEdit },
		{ name = "running", bit = constants.CONTEXT_BITS.isRunning },
	}

	for _, context in ipairs(contextOrder) do
		local bitMask = bit32.lshift(1, context.bit)
		local isSet = bit32.band(bitsetValue, bitMask) ~= 0

		-- Only include if no filter mask, or if filter mask includes this bit
		if not filterMask or bit32.band(filterMask, bitMask) ~= 0 then
			local valueColor = isSet and COLORS.Green or COLORS.Red
			local bitValue = isSet and "1" or "0"
			table.insert(parts, `{COLORS.Grey}{context.name}:{COLORS.Reset} {valueColor}{bitValue}{COLORS.Reset}`)
		end
	end

	return table.concat(parts, ", ")
end

local function formatBitsetShort(bitset: number): string
	local bits = {
		bit32.band(bit32.rshift(bitset, constants.CONTEXT_BITS.isStudio), 1),
		bit32.band(bit32.rshift(bitset, constants.CONTEXT_BITS.isServer), 1),
		bit32.band(bit32.rshift(bitset, constants.CONTEXT_BITS.isClient), 1),
		bit32.band(bit32.rshift(bitset, constants.CONTEXT_BITS.isEdit), 1),
		bit32.band(bit32.rshift(bitset, constants.CONTEXT_BITS.isRunning), 1),
	}

	local parts = {}
	for _, bit in ipairs(bits) do
		local color = bit == 1 and COLORS.Green or COLORS.Red
		table.insert(parts, `{color}{bit}{COLORS.Reset}`)
	end

	return table.concat(parts, "")
end

local function formatShortLog(studioId: string, bitset: number, executionId: string?): string
	local shortId = studioId:sub(1, 8)
	local bitsetShort = formatBitsetShort(bitset)

	if executionId then
		local execShort = executionId:sub(6, 13) -- Skip "rir3-" prefix
		return `{COLORS.Grey}[id:{COLORS.Reset} {shortId}{COLORS.Grey}] [{COLORS.Reset}{bitsetShort}{COLORS.Grey}]{COLORS.Reset} {execShort}`
	else
		return `{COLORS.Grey}[id:{COLORS.Reset} {shortId}{COLORS.Grey}] [{COLORS.Reset}{bitsetShort}{COLORS.Grey}]{COLORS.Reset}`
	end
end

return {
	printColored = printColored,
	printError = printError,
	printWarning = printWarning,
	printInfo = printInfo,
	formatBitset = formatBitset,
	formatBitsetShort = formatBitsetShort,
	formatShortLog = formatShortLog,
}
