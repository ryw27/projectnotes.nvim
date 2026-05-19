-- local mapper = require("projectnotes.map")

local M = {}

local defaults = {
	notes_dir = vim.fn.expand("~/notes/projects"),
	ui_style = "float", -- "float", "vsplit", or "hsplit"
	root_markers = { ".git", "Makefile", "package.json" },
	auto_namer = function(cwd)
		if not cwd then
			return ""
		end

		string.gsub(cwd, "/", "%")

		return cwd .. ".md"
	end,
}

function M.setup(user_opts)
	if vim.fn.has("nvim-0.8.0") == 0 then
		error("projectnotes needs Neovim >= 0.8.0.")
	end

	M.options = vim.tbl_deep_extend("force", defaults, user_opts or {})

	if vim.fn.isdirectory(M.options.notes_dir) == 0 then
		vim.fn.mkdir(M.options.notes_dir, "p")
	end
end

return M
