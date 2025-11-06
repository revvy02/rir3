export type ExecConnection = {
	ws: any,
	executionId: string,
	script: string,
	instancePath: string?,
	filterBits: number,
	filterMask: number,
	assignedStudio: string?,
	queuedAt: number,

	new: (ws: any, executionId: string, script: string, instancePath: string?, filterBits: number, filterMask: number) -> ExecConnection,
	send: (self: ExecConnection, data: string) -> (),
	close: (self: ExecConnection) -> (),
}

local ExecConnection = {}
ExecConnection.__index = ExecConnection

function ExecConnection.new(
	ws: any,
	executionId: string,
	script: string,
	instancePath: string?,
	filterBits: number,
	filterMask: number
): ExecConnection
	local self = setmetatable({}, ExecConnection)
	self.ws = ws
	self.executionId = executionId
	self.script = script
	self.instancePath = instancePath
	self.filterBits = filterBits
	self.filterMask = filterMask
	self.assignedStudio = nil
	self.queuedAt = os.time()
	return (self :: any) :: ExecConnection
end

function ExecConnection:send(data: string)
	pcall(function()
		self.ws:send(data)
	end)
end

function ExecConnection:close()
	pcall(function()
		self.ws:close()
	end)
end

return ExecConnection
