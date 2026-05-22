local projectnotes = require("projectnotes")

vim.api.nvim_create_user_command("ProjectNote", function()
	projectnotes.open_note_auto()
end, {
	nargs = 0,
	desc = "Open or create the note for the current project (auto-named)",
})

vim.api.nvim_create_user_command("ProjectNoteManual", function()
	projectnotes.open_note_manual()
end, {
	nargs = 0,
	desc = "Create a project note with a custom filename",
})

vim.api.nvim_create_user_command("ProjectNoteRename", function(opts)
	projectnotes.rename_note(opts.args)
end, {
	nargs = "?",
	desc = "Rename the note linked to the current project",
})

vim.api.nvim_create_user_command("ProjectNoteLink", function()
	projectnotes.link_note()
end, {
	nargs = 0,
	desc = "Link an existing note file to the current project",
})

vim.api.nvim_create_user_command("ProjectNotes", function()
	projectnotes.search_notes()
end, {
	nargs = 0,
	desc = "Search notes in the notes directory",
})

vim.api.nvim_create_user_command("ProjectNotesGrep", function()
	projectnotes.grep_notes()
end, {
	nargs = 0,
	desc = "Grep notes in the notes directory",
})
