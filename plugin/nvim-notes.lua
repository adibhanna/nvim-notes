-- nvim-notes plugin entry point
if vim.g.loaded_nvim_notes == 1 then
    return
end
vim.g.loaded_nvim_notes = 1

local notes = require('nvim-notes')

-- Commands
vim.api.nvim_create_user_command('NotesNew', function(opts)
    notes.new_note(opts.args)
end, { nargs = '?', desc = 'Create a new note' })

vim.api.nvim_create_user_command('NotesOpen', function()
    notes.open_note()
end, { desc = 'Open/search for a note' })

vim.api.nvim_create_user_command('NotesSetVault', function(opts)
    notes.set_vault(opts.args)
end, { nargs = 1, desc = 'Set the notes vault directory' })

vim.api.nvim_create_user_command('NotesSearch', function(opts)
    notes.search_notes(opts.args)
end, { nargs = '?', desc = 'Search notes by content' })

vim.api.nvim_create_user_command('NotesSearchTags', function(opts)
    notes.search_by_tags(opts.args)
end, { nargs = '?', desc = 'Search notes by tags' })

vim.api.nvim_create_user_command('NotesPin', function()
    notes.toggle_pin()
end, { desc = 'Toggle pin status of current note' })

vim.api.nvim_create_user_command('NotesPinned', function()
    notes.show_pinned()
end, { desc = 'Show all pinned notes' })

vim.api.nvim_create_user_command('NotesPreview', function()
    notes.preview_markdown()
end, { desc = 'Preview current note in markdown' })

vim.api.nvim_create_user_command('NotesIndex', function()
    notes.show_index()
end, { desc = 'Show notes index/dashboard' })

-- Default keybindings (can be overridden in user config)
local function set_keybindings()
    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<leader>nn', notes.new_note, opts)
    vim.keymap.set('n', '<leader>no', notes.open_note, opts)
    vim.keymap.set('n', '<leader>ns', notes.search_notes, opts)
    vim.keymap.set('n', '<leader>nt', notes.search_by_tags, opts)
    vim.keymap.set('n', '<leader>np', notes.toggle_pin, opts)
    vim.keymap.set('n', '<leader>nP', notes.show_pinned, opts)
    vim.keymap.set('n', '<leader>nv', notes.preview_markdown, opts)
    vim.keymap.set('n', '<leader>ni', notes.show_index, opts)
end

-- Setup function to be called by user
_G.setup_nvim_notes = function(config)
    notes.setup(config or {})
    if not config or config.disable_default_keybindings ~= true then
        set_keybindings()
    end
end
