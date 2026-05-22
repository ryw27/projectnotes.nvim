local M = {}

local config = require("projectnotes.config")
local mapper = require("projectnotes.map")
local render = require("projectnotes.ui")
local picker = require("projectnotes.picker")

local function project_root()
	if config.options.resolve_root then
		local resolved = config.options.resolve_root()
		if resolved and resolved ~= "" then
			resolved = vim.fn.fnamemodify(resolved, ":p")
			if #resolved > 1 and resolved:sub(-1) == "/" then
				resolved = resolved:sub(1, -2)
			end
			return resolved
		end
	end
	return mapper.resolve(config.options.root_markers)
end

local function check_existence(project_root_path)
	local mapdata = mapper.read_map()
	local mapped_path = mapdata[project_root_path]

	if mapped_path and vim.fn.filereadable(mapped_path) == 1 then
		return mapped_path
	end

	local auto_fp = config.options.auto_namer(project_root_path)
	if vim.fn.filereadable(auto_fp) == 1 then
		return auto_fp
	end

	return nil
end

function M.setup(user_opts)
	require("projectnotes.config").setup(user_opts)
	require("projectnotes.map").migrate()
end

function M.open_note_auto()
	local proj = project_root()
	local note_file = check_existence(proj)

	if not note_file then
		note_file = mapper.create_auto_entry(proj)
	end

	render.show(note_file)
end

function M.close_note()
	render.close_float()
end

function M.open_note_manual()
	local proj = project_root()
	local note_file = check_existence(proj)

	if note_file then
		render.show(note_file)
		return
	end

	vim.ui.input({ prompt = "Note filename: ", default = vim.fn.fnamemodify(proj, ":t") .. ".md" }, function(name)
		if not name or name == "" then
			return
		end
		if name:find("/", 1, true) then
			vim.notify("Note name cannot contain /", vim.log.levels.ERROR)
			return
		end
		if not name:match("%.md$") then
			name = name .. ".md"
		end
		local file_path = config.options.notes_dir .. "/" .. name
		if vim.fn.filereadable(file_path) == 1 then
			mapper.create_manual_entry(proj, file_path)
			render.show(file_path)
			return
		end
		note_file = mapper.create_manual_entry(proj, file_path)
		render.show(note_file)
	end)
end

-- Allows note linking. Will automatically change despite existing linked note
function M.link_note()
	local proj = project_root()
	local current_path = check_existence(proj)

	picker.find_note_to_link(config.options.notes_dir, function(selected)
		if not selected then
			return
		end
		mapper.create_manual_entry(proj, selected)
		render.show(selected)
		vim.notify("Note linked to project", vim.log.levels.INFO)

		-- Close the old buffer if it's open
		if current_path then
			local old_bufnr = vim.fn.bufnr(current_path)
			if old_bufnr ~= -1 and vim.api.nvim_buf_get_name(0) == current_path then
				vim.cmd.bwipeout(old_bufnr)
			end
		end
	end)
end

function M.rename_note(new_name)
	if not new_name or new_name == "" then
		local proj = project_root()
		local current_path = check_existence(proj)
		if not current_path then
			vim.notify("Note does not exist for this project", vim.log.levels.ERROR)
			return
		end
		vim.ui.input({
			prompt = "New note name: ",
			default = vim.fn.fnamemodify(current_path, ":t"),
		}, function(name)
			M.rename_note(name)
		end)
		return
	end

	-- Don't allow nested paths
	if string.find(new_name, "/") then
		vim.notify("New name cannot contain /", vim.log.levels.ERROR)
		return
	end

	-- Check existence
	local proj = project_root()
	local current_path = check_existence(proj)
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

	mapper.set_mapping(proj, new_path)

	local current_buf_path = vim.fn.expand("%:p")
	if current_buf_path == current_path then
		vim.cmd.edit(vim.fn.fnameescape(new_path))

		local old_bufnr = vim.fn.bufnr(current_path)
		if old_bufnr ~= -1 then
			vim.cmd.bwipeout(old_bufnr)
		end
	end
end

function M.search_notes()
	picker.find_notes(config.options.notes_dir)
end

function M.grep_notes()
	picker.grep_notes(config.options.notes_dir)
end

return M
