-- local mapper = require("projectnotes.map")

local M = {}

local defaults = {
	notes_dir = vim.fn.expand("~/notes/projects"),
	-- Denotes project note opened
	ui_style_proj = "float", -- "float", "vsplit", or "hsplit"
	-- Denotes notes opened by search/grep
	ui_style_general = "float", -- "float", "vsplit", or "hsplit"
	picker = "auto", -- "auto", "fzf", or "builtin"
	root_markers = { ".git", "Makefile", "package.json" },
	resolve_root = nil, -- optional function() -> project root path
	auto_namer = function(project_root)
		local pathname = project_root:gsub("/", "%%")
		return M.options.notes_dir .. "/" .. pathname .. ".md"
	end,
}

function M.setup(user_opts)
	if vim.fn.has("nvim-0.8.0") == 0 then
		error("projectnotes needs Neovim >= 0.8.0.")
	end

	local ok = pcall(require, "plenary.popup")
	if not ok then
		error("projectnotes.nvim requires plenary.nvim (https://github.com/nvim-lua/plenary.nvim)")
	end

	M.options = vim.tbl_deep_extend("force", defaults, user_opts or {})

	if vim.fn.isdirectory(M.options.notes_dir) == 0 then
		vim.fn.mkdir(M.options.notes_dir, "p")
	end
end

return M
