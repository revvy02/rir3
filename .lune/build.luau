-- Build script for creating self-contained rodeo binaries
-- Embeds plugin binaries as global variables in the bundled code

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

-- Platform targets for cross-compilation
local TARGETS = {
	{ os = "macos", arch = "aarch64", ext = "" },
	{ os = "macos", arch = "x86_64", ext = "" },
	{ os = "linux", arch = "x86_64", ext = "" },
	{ os = "windows", arch = "x86_64", ext = ".exe" },
}

local function log(message: string)
	stdio.write(`[build] {message}\n`)
end

local function runCommand(command: string, args: { string }, description: string): boolean
	log(description)
	local result = process.exec(command, args)

	if not result.ok then
		stdio.ewrite(`Error: {description} failed\n`)
		if result.stderr and #result.stderr > 0 then
			stdio.ewrite(`{result.stderr}\n`)
		end
		return false
	end

	return true
end

local function ensureDir(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function main()
	log("Starting rodeo binary build process...")

	-- Step 1: Build plugins with Rojo
	log("Step 1/5: Building plugins with Rojo")

	ensureDir("build")

	local oncePluginSuccess = runCommand("rojo", { "build", "plugins/once/plugin.project.json", "-o", "build/once.rbxmx" }, "Building once plugin")

	if not oncePluginSuccess then
		process.exit(1)
	end

	local servePluginSuccess = runCommand("rojo", { "build", "plugins/serve/plugin.project.json", "-o", "build/serve.rbxmx" }, "Building serve plugin")

	if not servePluginSuccess then
		process.exit(1)
	end

	-- Step 2: Read plugin binaries as raw strings
	log("Step 2/5: Reading plugin binaries")

	local oncePluginBinary = fs.readFile("build/once.rbxmx")
	local servePluginBinary = fs.readFile("build/serve.rbxmx")

	log(`  Once plugin: {#oncePluginBinary} bytes`)
	log(`  Serve plugin: {#servePluginBinary} bytes`)

	-- Step 3: Patch darklua config with injected globals
	log("Step 3/5: Patching darklua config with embedded plugins")

	local templateConfig = fs.readFile(".lune/bundle.darklua.json")
	local config = serde.decode("json", templateConfig)

	-- Add inject_global_value rules with raw binary strings
	table.insert(config.rules, {
		rule = "inject_global_value",
		identifier = "RODEO_ONCE_PLUGIN",
		value = oncePluginBinary,
	})

	table.insert(config.rules, {
		rule = "inject_global_value",
		identifier = "RODEO_SERVE_PLUGIN",
		value = servePluginBinary,
	})

	-- Write patched config
	local patchedConfig = serde.encode("json", config)
	fs.writeFile("build/bundle.darklua.json.patched", patchedConfig)

	-- Step 4: Bundle source with darklua
	log("Step 4/5: Bundling source with darklua")

	local bundleSuccess = runCommand("darklua", { "process", "src", "build/bundle", "--config", "build/bundle.darklua.json.patched" }, "Running darklua bundler")

	if not bundleSuccess then
		process.exit(1)
	end

	-- Step 5: Build binaries for each platform
	log("Step 5/5: Building platform-specific binaries")

	ensureDir("build/releases")

	for _, target in TARGETS do
		local platformName = `{target.os}-{target.arch}`
		local outputPath = `build/releases/rodeo_{platformName}{target.ext}`
		local targetArg = `{target.os}-{target.arch}`

		local buildSuccess = runCommand("lune", { "build", "build/bundle/init.luau", "-o", outputPath, "--target", targetArg }, `Building for {platformName}`)

		if not buildSuccess then
			stdio.ewrite(`Warning: Failed to build for {platformName}, continuing...\n`)
		else
			local fileSize = #fs.readFile(outputPath)
			log(`  Created {outputPath} ({fileSize} bytes)`)
		end
	end

	log("Build complete! Binaries are in build/releases/")
end

main()
