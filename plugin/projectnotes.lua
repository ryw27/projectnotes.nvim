local projectnotes = require("projectnotes")

vim.api.nvim_create_user_command("ProjectNote", function()
	projectnotes.open_note_auto()
end, {
	nargs = 0,
	desc = "Create a project note in the notes dir using the auto namer fn if it doesn't exist and opens it, else opens it",
})

vim.api.nvim_create_user_command("ProjectNoteManual", function()
	projectnotes.open_note_manual()
end, {
	nargs = 0,
	desc = "Create a project note in the notes dir with a manual prompt if it doesn't exist",
})

vim.api.nvim_create_user_command("ProjectNoteRename", function()
	projectnotes.rename_note()
end, {
	nargs = 0,
	desc = "Prompts for a corresponding note rename if a note exists",
})

vim.api.nvim_create_user_command("ProjectNoteRename", function()
	projectnotes.link_note()
end, {
	nargs = 0,
	desc = "Opens a picker to link a new note to a project",
})

vim.api.nvim_create_user_command("ProjectNote", function()
	projectnotes.search_notes()
end, {
	nargs = 0,
	desc = "Search notes dir",
})

vim.api.nvim_create_user_command("ProjectNote", function()
	projectnotes.grep_notes()
end, {
	nargs = 0,
	desc = "Grep notes dir",
})
