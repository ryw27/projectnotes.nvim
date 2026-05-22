local M = {}

local float = require("plenary.window.float")
local window = require("plenary.window")
local config = require("projectnotes.config")

M.buf_id = nil
M.float_win_id = nil

local function write_buf(buf)
	if not vim.api.nvim_buf_get_option(buf, "modified") then
		return
	end
	local path = vim.api.nvim_buf_get_name(buf)
	if path == "" then
		return
	end
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	vim.api.nvim_buf_call(buf, function()
		vim.cmd.write()
	end)
end

function M.close_float()
	if not M.float_win_id or not vim.api.nvim_win_is_valid(M.float_win_id) then
		M.float_win_id = nil
		M.buf_id = nil
		return
	end
	write_buf(M.buf_id)
	float.clear(M.buf_id)
	window.try_close(M.float_win_id, true)
	M.float_win_id = nil
	M.buf_id = nil
end

function M.show(file_path, kind)
	kind = kind or "proj"
	local style = kind == "general" and config.options.ui_style_general or config.options.ui_style_proj

	local buf = vim.fn.bufnr(file_path, true)
	if vim.fn.filereadable(file_path) == 1 then
		vim.fn.bufload(buf)
	end
	vim.bo[buf].filetype = "markdown"

	-- Already open somewhere: focus it, don't open again
	local winnr = vim.fn.bufwinnr(buf)
	if winnr > 0 then
		vim.cmd(winnr .. "wincmd w")
		return
	end

	if style == "float" then
		M.close_float()
		vim.bo[buf].bufhidden = "hide"
		M.buf_id = buf
		M.float_win_id = float.centered({ bufnr = buf, winblend = 0 }).win_id
	elseif style == "vsplit" or style == "hsplit" then
		vim.bo[buf].bufhidden = ""
		vim.api.nvim_open_win(buf, true, { split = style == "vsplit" and "right" or "below" })
	else
		vim.notify("Invalid UI style: " .. style, vim.log.levels.ERROR)
		return
	end

	vim.keymap.set("n", "q", function()
		local win = vim.api.nvim_get_current_win()
		write_buf(buf)
		float.clear(buf)
		if win == M.float_win_id then
			M.float_win_id = nil
			M.buf_id = nil
		end
		if vim.api.nvim_win_is_valid(win) then
			window.try_close(win, true)
		end
	end, { buffer = buf, desc = "Close note" })
end

function M.close_note()
	M.close_float()
end

return M
