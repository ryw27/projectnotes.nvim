local M = {}

local float = require("plenary.window.float")
local window = require("plenary.window")
local config = require("projectnotes.config")

M.buf_id = nil
M.float_win_id = nil

function M.close_float()
	if not M.float_win_id or not vim.api.nvim_win_is_valid(M.float_win_id) then
		M.float_win_id = nil
		M.buf_id = nil
		return
	end
	if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) and vim.api.nvim_buf_get_option(M.buf_id, "modified") then
		vim.fn.mkdir(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(M.buf_id), ":h"), "p")
		vim.api.nvim_buf_call(M.buf_id, function()
			vim.cmd.write()
		end)
	end
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

	if vim.fn.bufwinnr(buf) > 0 then
		vim.cmd(vim.fn.bufwinnr(buf) .. "wincmd w")
		return
	end

	if style == "float" then
		M.close_float()
		vim.bo[buf].bufhidden = "hide"
		M.buf_id = buf

		local d = float.default_opts({ winblend = 0 })
		local pad = 2
		M.float_win_id = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			row = d.row + pad,
			col = d.col + pad,
			width = d.width - 2 * pad,
			height = d.height - 2 * pad,
			style = "minimal",
			border = "rounded",
			title = vim.fn.fnamemodify(file_path, ":t"),
			title_pos = "center",
		})
		vim.wo[M.float_win_id].winhl = "NormalFloat:Normal,FloatBorder:Normal"
		vim.wo[M.float_win_id].wrap = true
	elseif style == "vsplit" or style == "hsplit" then
		vim.bo[buf].bufhidden = ""
		vim.api.nvim_open_win(buf, true, { split = style == "vsplit" and "right" or "below" })
	else
		vim.notify("Invalid UI style: " .. style, vim.log.levels.ERROR)
		return
	end

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_get_current_win() == M.float_win_id then
			M.close_float()
		else
			if vim.api.nvim_buf_get_option(buf, "modified") then
				vim.api.nvim_buf_call(buf, function()
					vim.cmd.write()
				end)
			end
			window.try_close(vim.api.nvim_get_current_win(), true)
		end
	end, { buffer = buf, desc = "Close note" })
end

function M.close_note()
	M.close_float()
end

return M
