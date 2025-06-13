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

vim.api.nvim_create_user_command('NotesSetVault', function(opts)
    notes.set_vault(opts.args)
end, { nargs = 1, desc = 'Set the notes vault directory' })

vim.api.nvim_create_user_command('NotesSearch', function(opts)
    notes.search_notes(opts.args)
end, { nargs = '?', desc = 'Search notes by content' })

vim.api.nvim_create_user_command('NotesSearchTags', function(opts)
    notes.search_by_tags(opts.args)
end, { nargs = '?', desc = 'Search notes by tags' })

vim.api.nvim_create_user_command('NotesPinToggle', function()
    notes.toggle_pin()
end, { desc = 'Toggle pin status of current note' })

vim.api.nvim_create_user_command('NotesPinSearch', function()
    notes.search_pinned_notes()
end, { desc = 'Search pinned notes' })

vim.api.nvim_create_user_command('NotesPreview', function()
    notes.preview_markdown()
end, { desc = 'Preview current note in markdown' })

vim.api.nvim_create_user_command('NotesIndex', function()
    notes.show_index()
end, { desc = 'Show notes index/dashboard' })

-- Default keybindings (can be overridden in user config)
local function set_keybindings()
    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<leader>nn', notes.new_note, vim.tbl_extend('force', opts, { desc = 'Create new note' }))
    vim.keymap.set('n', '<leader>ns', notes.search_notes,
        vim.tbl_extend('force', opts, { desc = 'Search notes content' }))
    vim.keymap.set('n', '<leader>nt', notes.search_by_tags, vim.tbl_extend('force', opts, { desc = 'Search by tags' }))
    vim.keymap.set('n', '<leader>np', notes.toggle_pin,
        vim.tbl_extend('force', opts, { desc = 'Toggle pin current note' }))
    vim.keymap.set('n', '<leader>nP', notes.search_pinned_notes,
        vim.tbl_extend('force', opts, { desc = 'Search pinned notes' }))
    vim.keymap.set('n', '<leader>nv', notes.preview_markdown,
        vim.tbl_extend('force', opts, { desc = 'Preview current note' }))
    vim.keymap.set('n', '<leader>ni', notes.show_index, vim.tbl_extend('force', opts, { desc = 'Show notes dashboard' }))
end

-- Setup function to be called by user
_G.setup_nvim_notes = function(config)
    notes.setup(config or {})
    if not config or config.disable_default_keybindings ~= true then
        set_keybindings()
    end
end
