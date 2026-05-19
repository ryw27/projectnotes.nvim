local M = {}

local mapping_file = vim.fn.stdpath("data") .. "projectnotes.json"

local cached_state = {}

-- Get manual project note mappings
function M.read_map()
	if cached_state ~= nil then
		return cached_state
	end

	-- Read from file
	local f = io.open(mapping_file, "r")
	if not f then
		cached_state = {}
		return {}
	end

	local content = f:read("*a")
	f:close()

	if content == "" then
		cached_state = {}
		return {}
	end

	local ok, map_state = pcall(vim.json.decode, content)
	if not ok or not map_state then
		cached_state = {}
		return {}
	end

	cached_state = map_state
	return map_state
end

function M.update_map(new_state)
	local f = io.open(mapping_file, "w")
	if not f then
		vim.notify("ProjectNotes: Could not open mapping file for writing", vim.log.levels.ERROR)
		return
	end

	f:write(vim.json.encode(new_state))
	f:close()

	cached_state = new_state
end

function M.delete_entry(cwd)
	local map_state = M.read_map()

	if map_state[cwd] then
		map_state.cwd = nil
		M.update_map(map_state)
	end
end

-- Manual Mapping Logic
function M.create_manual_entry(cwd, file_path)
	local map_state = cached_state

	if map_state[cwd] and file_path == map_state[cwd] then
		return
	end

	map_state[cwd] = file_path
	M.update_map(map_state)
end

-- Auto Mapping Logic
function M.create_auto_entry(cwd)
	local map_state = cached_state

	local config = require("projectnotes.config")
	local file_path = config.options.auto_namer(cwd)

	if map_state[cwd] and file_path == map_state[cwd] then
		return file_path
	elseif map_state[cwd] then
		map_state[cwd] = nil
		M.update_map(map_state)
	end

	return file_path
end

return M
