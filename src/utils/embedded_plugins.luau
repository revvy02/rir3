-- Embedded plugin utilities
-- Handles writing embedded plugin binaries to Studio plugin directory

local fs = require("@lune/fs")

local function writeEmbeddedPlugin(binaryData: string, targetPath: string)
	-- Ensure parent directory exists
	local parentDir = targetPath:match("(.+)/[^/]+$")
	if parentDir and not fs.isDir(parentDir) then
		fs.writeDir(parentDir)
	end

	-- Write the plugin file directly (raw binary string)
	fs.writeFile(targetPath, binaryData)
end

local function writeOncePlugin(targetPath: string)
	writeEmbeddedPlugin(_G.RODEO_ONCE_PLUGIN, targetPath)
end

local function writeServePlugin(targetPath: string)
	writeEmbeddedPlugin(_G.RODEO_SERVE_PLUGIN, targetPath)
end

return {
	writeOncePlugin = writeOncePlugin,
	writeServePlugin = writeServePlugin,
}
