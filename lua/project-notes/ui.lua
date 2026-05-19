local M = {}

M.buf_id = nil
M.win_id = nil

local config = require("projectnotes.config")

local function setup_autocmds()
	local bufnr = M.buf_id
	vim.keymap.set("n", "q", function()
		require("projectnotes").close_note()
	end, { buffer = bufnr, silent = true, desc = "Close project note" })

	-- Create an event listener that auto-closes the window if they click away
	local group_id = vim.api.nvim_create_augroup("ProjectNotesLocal", { clear = true })

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = group_id,
		buffer = bufnr, -- Only triggers when leaving THIS specific buffer
		callback = function()
			-- We use schedule to defer the execution safely outside the event loop split
			vim.schedule(M.close)
		end,
	})
end

function M.show(file_path)
	-- If window is already open, just jump into it
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		vim.api.nvim_set_current_win(M.win_id)
		return
	end

	-- Create a clean scratch buffer
	if not M.buf_id or not vim.api.nvim_buf_is_valid(M.buf_id) then
		M.buf_id = vim.api.nvim_create_buf(false, true)
	end

	-- Assign the actual file path to this buffer
	vim.api.nvim_buf_set_name(M.buf_id, file_path)

	-- Load the file contents into the buffer
	vim.fn.bufload(M.buf_id)

	if config.options.ui_style == "float" then
		-- Calculate dimensions dynamically based on user's terminal size
		local screen_width = vim.o.columns
		local screen_height = vim.o.lines
		local win_width = math.ceil(screen_width * 0.6)
		local win_height = math.ceil(screen_height * 0.6)
		local row = math.ceil((screen_height - win_height) / 2)
		local col = math.ceil((screen_width - win_width) / 2)

		local win_opts = {
			relative = "editor",
			row = row,
			col = col,
			width = win_width,
			height = win_height,
			style = "minimal",
			border = "rounded",
		}

		-- Open the window and focus it
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, win_opts)
		setup_autocmds()
	elseif config.options.ui_style == "vsplit" then
		local win_opts = {
			split = "right",
		}
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, win_opts)
	elseif config.options.ui_style == "hsplit" then
		local win_opts = {
			split = "below",
		}
		M.win_id = vim.api.nvim_open_win(M.buf_id, true, win_opts)
	else
		vim.notify("Invalid projectnotes UI style", vim.log.levels.ERROR)
	end

	-- Set the filetype to markdown so syntax highlighting works instantly
	vim.bo[M.buf_id].filetype = "markdown"
	vim.wo[M.win_id].wrap = true
end

function M.close()
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		-- Close the window viewport
		vim.api.nvim_win_close(M.win_id, true)
		M.win_id = nil
		M.buf_id = nil
	end
end

return M
