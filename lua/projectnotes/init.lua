local M = {}

local config = require("projectnotes.config")
local mapper = require("projectnotes.map")
local render = require("projectnotes.ui")
local fzf = require("projectnotes.providers.fzf")

-- Returns file and mapdata entry (empty if not manual)
local function check_existence(cwd)
	local mapdata = mapper.read_map()
	local mapped_path = mapdata[cwd]

	if mapped_path and vim.fn.filereadable(mapped_path) == 1 then
		return mapped_path
	end

	local auto_fp = config.options.auto_namer(cwd)
	if vim.fn.filereadable(auto_fp) == 1 then
		return auto_fp
	end

	return nil
end

function M.setup(user_opts)
	require("projectnotes.config").setup(user_opts)
end

-- map_data: {
-- cwd: note_file_path,
-- cwd: note_file_path
-- }
function M.open_note_auto()
	local cwd = vim.fn.getcwd()
	local note_file = check_existence(cwd)

	if not note_file then
		mapper.delete_entry(cwd)
		note_file = mapper.create_auto_entry(cwd)
	end

	render.show(note_file)
end

function M.close_note()
	render.close()
end

function M.open_note_manual()
	local cwd = vim.fn.getcwd()
	local note_file = check_existence(cwd)

	if not note_file then
		mapper.delete_entry(cwd)
		note_file = mapper.create_manual_entry(cwd)
	end

	render.show(note_file)
end

-- Allows note linking. Will automatically change despite existing linked note
function M.link_note()
	local cwd = vim.fn.getcwd()
	local current_path = check_existence(cwd)

	-- Find a file in the notes dir to link to
	-- local note_files = vim.split(vim.fn.glob(config.options.notes_dir .. "/*.md"), "\n")
	fzf.find_note_to_link(cwd, function(selected)
		-- Will delete an old entry itself
		mapper.create_manual_entry(selected)
	end)

	vim.notify("Note successfully linked", vim.log.levels.INFO, {})

	-- Clear the old note buffer if it is open
	local current_buf_path = vim.fn.expand("%:p")
	if current_buf_path == current_path then
		local old_bufnr = vim.fn.bufnr(current_path)
		if old_bufnr ~= -1 then
			vim.cmd("bwipeout " .. old_bufnr)
		end
	end
end

function M.rename_note(new_name)
	-- Invalid input
	if not new_name or new_name == "" then
		vim.notify("Please provide a new name for the note.", vim.log.levels.ERROR)
		return
	end

	-- Don't allow nested paths
	if string.find(new_name, "/") then
		vim.notify("New name contains /", vim.log.levels.ERROR)
	end

	-- Check existence
	local cwd = vim.fn.getcwd()
	local current_path = check_existence(cwd)
	if not current_path then
		vim.notify("Note does not exist for this project", vim.log.levels.ERROR)
		return
	end

	-- Ensure it's a markdown file
	if not string.match(new_name, "%.md$") then
		new_name = new_name .. ".md"
	end

	-- Create path
	local new_path = config.options.notes_dir .. "/" .. new_name

	-- Check if the path exists
	if vim.fn.filereadable(new_path) == 1 then
		vim.notify("A note already exists at: " .. new_name, vim.log.levels.ERROR)
		return
	end

	-- Rename
	local success, err = vim.uv.fs_rename(current_path, new_path)
	if not success then
		vim.notify("Failed to rename file: " .. err, vim.log.levels.ERROR)
		return
	end

	mapper.create_mapping(new_path)

	local current_buf_path = vim.fn.expand("%:p")
	if current_buf_path == current_path then
		vim.cmd("edit " .. vim.fn.fnameescape(new_path))

		local old_bufnr = vim.fn.bufnr(current_path)
		if old_bufnr ~= -1 then
			vim.cmd("bwipeout " .. old_bufnr)
		end
	end
end

function M.search_notes()
	fzf.find_notes(config.options.notes_dir)
	-- local note_files = vim.split(vim.fn.glob(config.options.notes_dir .. "/*.md"), "\n", { trimempty = true })
	--
	-- vim.ui.select(note_files, {
	-- 	prompt = "Select a note file",
	-- 	format_item = function(item)
	-- 		return vim.fn.fnamemodify(item, ":t")
	-- 	end,
	-- }, function(choice)
	-- 	if choice then
	-- 		vim.cmd("edit " .. vim.fn.fnameescape(choice))
	-- 	end
	-- end)
end

function M.grep_notes()
	fzf.grep_notes(config.options.notes_dir)
	-- local note_files = vim.split(vim.fn.glob(config.options.notes_dir .. "/*.md"), "\n", { trimempty = true })
	--
	-- vim.ui.select(note_files, {
	-- 	prompt = "Select a note file",
	-- 	format_item = function(item)
	-- 		return vim.fn.fnamemodify(item, ":t")
	-- 	end,
	-- }, function(choice)
	-- 	if choice then
	-- 		vim.cmd("edit " .. vim.fn.fnameescape(choice))
	-- 	end
	-- end)
end

return M
