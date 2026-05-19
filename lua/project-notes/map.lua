local M = {}
local config = require("projectnotes.config")

local mapping_file = vim.fn.stdpath("data") .. "projectnotes.json"

-- Get manual project note mappings
function M.read_map()
	local f = io.open(mapping_file, "w")
	if not f then
		return {}
	end

	local content = f:read("*a")
	f:close()

	local map_state = vim.json.decode(content)
	if not map_state then
		return {}
	end

	return map_state
end

-- Manual Mapping Logic
function M.create_manual_entry(cwd) end

-- Auto Mapping Logic
function M.create_auto_entry(cwd) end

return M
