local M = {}

local defaults = {
	notes_dir = vim.fn.expand("~/notes/projects"),
}

-- Setup
M.setup = function() end

-- Open the note (add support for floating window)
M.open_note = function() end

-- Map a note file to a project (By default, it will map to the project name)
M.map_note_file = function() end

return M
