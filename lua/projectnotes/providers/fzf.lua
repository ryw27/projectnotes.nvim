local M = {}

function M.find_notes(cwd)
	require("fzf-lua").files({
		cwd = cwd,
		prompt = "Project Notes> ",
	})
end

function M.grep_notes(cwd)
	require("fzf-lua").live_grep({
		cwd = cwd,
		prompt = "Grep Notes> ",
	})
end

function M.find_note_to_link(cwd, callback)
	require("fzf-lua").files({
		cwd = cwd,
		prompt = "Link Note> ",
		actions = {
			["default"] = function(selected, opts)
				if not selected or not selected[1] then
					return
				end

				local path_info = require("fzf-lua.path").entry_to_file(selected[1], opts)
				callback(path_info.path)
			end,
		},
	})
end

return M
