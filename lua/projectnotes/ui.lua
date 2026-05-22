local M = {}

local popup = require("plenary.popup")
local window = require("plenary.window")
local config = require("projectnotes.config")

M.buf_id = nil
M.win_id = nil

local function save(buf)
	if vim.api.nvim_buf_get_name(buf) == "" or not vim.api.nvim_buf_get_option(buf, "modified") then
		return
	end
	vim.fn.mkdir(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h"), "p")
	vim.api.nvim_buf_call(buf, function()
		vim.cmd.write()
	end)
end

local function setup_autocmds(buf)
	vim.keymap.set("n", "q", function()
		require("projectnotes").close_note()
	end, { buffer = buf, desc = "Close project note" })

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = vim.api.nvim_create_augroup("ProjectNotes", { clear = true }),
		buffer = buf,
		callback = function()
			save(buf)
			vim.schedule(M.close)
		end,
	})
end

function M.show(file_path)
	-- If window is already open, just jump into it
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		return vim.api.nvim_set_current_win(M.win_id)
	end

	M.close()

	M.buf_id = vim.fn.bufnr(file_path, true)
	if vim.fn.filereadable(file_path) == 1 then
		vim.fn.bufload(M.buf_id)
	end
	vim.bo[M.buf_id].bufhidden = "hide"
	vim.bo[M.buf_id].filetype = "markdown"

	local style = config.options.ui_style_proj
	if style == "float" then
		M.win_id = popup.create(M.buf_id, {
			relative = "editor",
			border = true,
		})
	elseif style == "vsplit" or style == "hsplit" then
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, { split = style == "vsplit" and "right" or "below" })
		vim.wo[M.win_id].wrap = true
	else
		vim.notify("Invalid projectnotes UI style: " .. style, vim.log.levels.ERROR)
		return M.close()
	end

	setup_autocmds(M.buf_id)
end

function M.close()
	if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
		save(M.buf_id)
		vim.api.nvim_buf_delete(M.buf_id, { force = true })
	end
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		window.try_close(M.win_id, true)
	end
	M.win_id = nil
	M.buf_id = nil
end

return M
