local M = {}

M.buf_id = nil
M.win_id = nil

local config = require("projectnotes.config")

local function setup_autocmds()
	local bufnr = M.buf_id
	vim.keymap.set("n", "q", function()
		require("projectnotes").close_note()
	end, { buffer = bufnr, silent = true, desc = "Close project note" })

	local group_id = vim.api.nvim_create_augroup("ProjectNotesLocal", { clear = true })

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = group_id,
		buffer = bufnr,
		callback = function()
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd.write({ bang = false })
			end)
			vim.schedule(M.close)
		end,
	})
end

function M.show(file_path)
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		vim.api.nvim_set_current_win(M.win_id)
		return
	end

	if M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
		vim.api.nvim_buf_delete(M.buf_id, { force = true })
	end

	M.buf_id = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(M.buf_id, file_path)
	vim.bo[M.buf_id].buftype = ""
	vim.bo[M.buf_id].bufhidden = "hide"

	if vim.fn.filereadable(file_path) == 1 then
		local lines = vim.fn.readfile(file_path)
		vim.api.nvim_buf_set_lines(M.buf_id, 0, -1, false, lines)
	else
		vim.api.nvim_buf_set_lines(M.buf_id, 0, -1, false, { "" })
	end

	if config.options.ui_style == "float" then
		local screen_width = vim.o.columns
		local screen_height = vim.o.lines
		local win_width = math.ceil(screen_width * 0.6)
		local win_height = math.ceil(screen_height * 0.6)
		local row = math.ceil((screen_height - win_height) / 2)
		local col = math.ceil((screen_width - win_width) / 2)

		M.win_id = vim.api.nvim_open_win(M.buf_id, true, {
			relative = "editor",
			row = row,
			col = col,
			width = win_width,
			height = win_height,
			style = "minimal",
			border = "rounded",
		})
		setup_autocmds()
	elseif config.options.ui_style == "vsplit" then
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, { split = "right" })
		setup_autocmds()
	elseif config.options.ui_style == "hsplit" then
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, { split = "below" })
		setup_autocmds()
	else
		vim.notify("Invalid projectnotes UI style", vim.log.levels.ERROR)
		return
	end

	vim.bo[M.buf_id].filetype = "markdown"
	vim.wo[M.win_id].wrap = true
end

function M.close()
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		vim.api.nvim_win_close(M.win_id, true)
	end
	M.win_id = nil
	M.buf_id = nil
end

return M
