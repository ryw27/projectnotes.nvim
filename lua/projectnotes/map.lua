local M = {}

local mapping_file = vim.fn.stdpath("data") .. "/projectnotes.json"
local cached_state = nil

--- Directory to start walking upward from (buffer file dir, else Neovim cwd).
function M.start_dir()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
		return vim.fn.fnamemodify(bufname, ":p:h")
	end
	return vim.fn.getcwd()
end

local function marker_exists(dir, marker)
	local path = dir .. "/" .. marker
	return vim.fn.getftype(path) ~= ""
end

--- Walk parents from start_dir until a root_marker is found.
--- Falls back to start_dir when no marker matches.
function M.resolve(markers, start_dir)
	start_dir = vim.fn.fnamemodify(start_dir or M.start_dir(), ":p")
	if #start_dir > 1 and start_dir:sub(-1) == "/" then
		start_dir = start_dir:sub(1, -2)
	end

	local dir = start_dir
	while true do
		for _, marker in ipairs(markers) do
			if marker_exists(dir, marker) then
				return dir
			end
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	return start_dir
end

-- Get manual project note mappings
function M.read_map()
	if cached_state ~= nil then
		return cached_state
	end

	-- Read from file
	local f = io.open(mapping_file, "r")
	if not f then
		cached_state = {}
		return cached_state
	end

	local content = f:read("*a")
	f:close()

	if content == "" then
		cached_state = {}
		return cached_state
	end

	local ok, map_state = pcall(vim.json.decode, content)
	if not ok or type(map_state) ~= "table" then
		cached_state = {}
		return cached_state
	end

	cached_state = map_state
	return cached_state
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

local function ensure_note_file(file_path)
	if vim.fn.filereadable(file_path) == 0 then
		local dir = vim.fn.fnamemodify(file_path, ":h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
		local f = io.open(file_path, "w")
		if f then
			f:close()
		end
	end
end

function M.set_mapping(project_root, file_path)
	ensure_note_file(file_path)
	local map_state = M.read_map()
	map_state[project_root] = file_path
	M.update_map(map_state)
end

-- Manual Mapping Logic
function M.create_manual_entry(project_root, file_path)
	local map_state = M.read_map()

	if map_state[project_root] == file_path then
		return file_path
	end

	M.set_mapping(project_root, file_path)

	return file_path
end

function M.create_auto_entry(project_root)
	local config = require("projectnotes.config")
	local map_state = M.read_map()
	local file_path = config.options.auto_namer(project_root)

	if map_state[project_root] == file_path then
		return file_path
	end

	M.set_mapping(project_root, file_path)
	return file_path
end

--- Re-key mappings from subdirectory cwd to detected project roots.
function M.migrate()
	local config = require("projectnotes.config")
	if not config.options then
		return
	end

	local map_state = M.read_map()
	local migrated = {}
	local changed = false

	for key, note_path in pairs(map_state) do
		local resolved = M.resolve(config.options.root_markers, key)
		if resolved ~= key then
			changed = true
		end
		if migrated[resolved] and migrated[resolved] ~= note_path then
			vim.notify(
				"ProjectNotes: keeping "
					.. note_path
					.. " for "
					.. resolved
					.. " (dropped "
					.. migrated[resolved]
					.. ")",
				vim.log.levels.WARN
			)
		end
		migrated[resolved] = note_path
	end

	if changed then
		M.update_map(migrated)
	end
end

return M
