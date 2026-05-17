local M = {}

local defaults = {
	notes_dir = vim.fn.expand("~/notes/projects"),
	prefix = "", -- Prefix to remove from names
}

local plenary = require("plenary.popup")

M.get_note_filepath = function()
	local full_cwd = vim.fn.getcwd()

	local prefix_start, prefix_end = string.find(full_cwd, defaults.prefix)
	local note_file_path = full_cwd
	-- Remove the prefix if exists
	if prefix_start == 1 then
		note_file_path = string.sub(full_cwd, prefix_end + 1)
	end

	-- Replace /'s with -'
	string.gsub(note_file_path, "/", "-")
	note_file_path = defaults.notes_dir .. note_file_path .. ".md"

	return note_file_path
end

-- Setup plugin
M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts or {})

	if vim.fn.isdirectory(M.config.notes_dir) == 0 then
		vim.fn.mkdir(defaults.notes_dir, "p")
	end
end

-- Open the note (add support for floating window)
M.open_note = function()
	local note_file_path = M.get_note_filepath()
	if not note_file_path then
		return
	end

	local win_id, win = plenary.create("", {
		title = "Project notes",
		border = true,
	})

	local bufnr = win.bufnr

	vim.cmd("edit " .. vim.fn.fnameescape(note_file_path))

	-- Quick close map
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win_id, true)
	end, { buffer = bufnr, silent = true })
end

-- Map a note file to a project (By default, it will map to the project name)
-- Get
M.map_note_file = function()
	local note_file_path = M.get_note_filepath()
	-- Create a new file or just open it
	local f = io.open(note_file_path, "r")
	io.close(f)
end

return M
