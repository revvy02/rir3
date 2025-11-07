-- Status command: Check if rir3 serve is running

local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")

local COLORS = require("../utils/colors")
local constants = require("../utils/constants")
local output = require("../utils/output")

local function checkServerStatus(port: number): (boolean, any?)
	local success, response = pcall(function()
		return net.request({
			url = `http://localhost:{port}/health`,
			method = "GET",
		})
	end)

	if not success then
		return false, nil
	end

	if not response.ok then
		return false, nil
	end

	local healthData = serde.decode("json", response.body)
	return true, healthData
end

local function formatStatus(healthData: any)
	output.printColored("rir3 serve is running", COLORS.Green)
	output.printInfo(`Port: {constants.SERVE_PORT}`)
	output.printInfo(`Total VMs: {healthData.totalVms}`)
	output.printInfo(`Total Queued: {healthData.totalQueued}`)
	output.printInfo(`Context Groups: {healthData.contextCount}`)

	if healthData.contextCount > 0 then
		print("")
		output.printInfo("Connected Studios:")
		for _, context in ipairs(healthData.contexts) do
			local bitsetFormatted = output.formatBitsetShort(context.bitset)
			output.printColored(`  Context [{bitsetFormatted}]: {context.vmCount} VM(s), {context.totalQueued} queued`, COLORS.Grey)

			for _, vm in ipairs(context.vms) do
				local studioIdShort = vm.studioId:sub(1, 8)
				local idleStatus = vm.isIdle and "idle" or "busy"
				local idleColor = vm.isIdle and COLORS.Green or COLORS.Yellow
				output.printColored(`    - {studioIdShort}: {vm.queueLength} in queue, {idleColor}{idleStatus}{COLORS.Reset}`, COLORS.Grey)
			end
		end
	end
end

local function main(args: any)
	local isRunning, healthData = checkServerStatus(constants.SERVE_PORT)

	if not isRunning then
		output.printError(`rir3 serve is not running on port {constants.SERVE_PORT}`)
		process.exit(1)
	end

	formatStatus(healthData)
	process.exit(0)
end

return main
