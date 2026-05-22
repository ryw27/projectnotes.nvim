local M = {}

local function backend()
	local config = require("projectnotes.config").options
	local pref = config.picker or "auto"
	if pref == "builtin" then
		return "builtin"
	end
	if pref == "fzf" then
		if pcall(require, "fzf-lua") then
			return "fzf"
		end
		vim.notify("projectnotes: fzf-lua not found, using builtin picker", vim.log.levels.WARN)
		return "builtin"
	end
	local ok = pcall(require, "fzf-lua")
	if ok then
		return "fzf"
	else
		return "builtin"
	end
end

local function list_note_files(notes_dir)
	return vim.fn.globpath(notes_dir, "*.md", false, true)
end

local function builtin_select(files, prompt, notes_dir, on_select)
	if #files == 0 then
		vim.notify("No notes found in " .. notes_dir, vim.log.levels.WARN)
		return
	end
	vim.ui.select(files, {
		prompt = prompt,
		format_item = function(item)
			return vim.fn.fnamemodify(item, ":t")
		end,
	}, function(choice)
		if choice and on_select then
			on_select(choice)
		end
	end)
end

function M.find_notes(notes_dir)
	if backend() == "fzf" then
		require("projectnotes.providers.fzf").find_notes(notes_dir)
		return
	end

	local ui = require("projectnotes.ui")
	local files = list_note_files(notes_dir)
	builtin_select(files, "Project Notes> ", notes_dir, function(choice)
		ui.show(choice, "general")
	end)
end

function M.grep_notes(notes_dir)
	if backend() == "fzf" then
		require("projectnotes.providers.fzf").grep_notes(notes_dir)
		return
	end

	vim.ui.input({ prompt = "Grep notes> " }, function(pattern)
		if not pattern or pattern == "" then
			return
		end
		vim.cmd.vimgrep("/" .. pattern:gsub("/", "\\/") .. "/gj", notes_dir .. "/*.md")
		vim.cmd.copen()
	end)
end

function M.find_note_to_link(notes_dir, callback)
	if backend() == "fzf" then
		require("projectnotes.providers.fzf").find_note_to_link(notes_dir, callback)
		return
	end

	local files = list_note_files(notes_dir)
	builtin_select(files, "Link Note> ", notes_dir, callback)
end

return M
