-- nvim-notes plugin entry point
if vim.g.loaded_nvim_notes == 1 then
    return
end
vim.g.loaded_nvim_notes = 1

-- Immediately prevent German spell check warnings
vim.opt.spelllang = 'en_us'
vim.opt.spell = false
vim.cmd('silent! set spelllang=en_us')
vim.cmd('silent! set nospell')

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

vim.api.nvim_create_user_command('NotesDelete', function()
    notes.delete_note()
end, { desc = 'Delete current note' })

vim.api.nvim_create_user_command('NotesPreview', function()
    notes.preview_markdown()
end, { desc = 'Preview current note in markdown' })

vim.api.nvim_create_user_command('NotesIndex', function()
    notes.show_index()
end, { desc = 'Show notes index/dashboard' })

vim.api.nvim_create_user_command('NotesSync', function()
    notes.sync()
end, { desc = 'Sync notes with GitHub (creates repo on first use)' })

-- Set up keybindings with which-key if available
local function set_keybindings()
    local has_whichkey, wk = pcall(require, 'which-key')

    if has_whichkey then
        -- Set the actual keybindings
        local opts = { noremap = true, silent = true }
        vim.keymap.set('n', '<leader><tab>n', notes.new_note, vim.tbl_extend('force', opts, { desc = 'Create new note' }))
        vim.keymap.set('n', '<leader><tab>s', notes.search_notes,
            vim.tbl_extend('force', opts, { desc = 'Search notes content' }))
        vim.keymap.set('n', '<leader><tab>t', notes.search_by_tags,
            vim.tbl_extend('force', opts, { desc = 'Search by tags' }))
        vim.keymap.set('n', '<leader><tab>p', notes.toggle_pin,
            vim.tbl_extend('force', opts, { desc = 'Toggle pin current note' }))
        vim.keymap.set('n', '<leader><tab>v', notes.preview_markdown,
            vim.tbl_extend('force', opts, { desc = 'Preview current note' }))
        vim.keymap.set('n', '<leader><tab>i', notes.show_index,
            vim.tbl_extend('force', opts, { desc = 'Show notes dashboard' }))

        -- Register with which-key
        wk.register({
            ["<tab>"] = {
                name = "Notes",
                n = { notes.new_note, "Create new note" },
                s = { notes.search_notes, "Search notes" },
                t = { notes.search_by_tags, "Search by tags" },
                p = { notes.toggle_pin, "Toggle pin current note" },
                v = { notes.preview_markdown, "Preview current note" },
                i = { notes.show_index, "Show notes dashboard" },
            }
        }, { prefix = "<leader>" })
    end
    -- If which-key is not available, no default keymaps are set
    -- Users can set their own keymaps or use commands directly
end

-- Setup function to be called by user
_G.setup_nvim_notes = function(config)
    notes.setup(config or {})
    if not config or config.disable_keybindings ~= true then
        set_keybindings()
    end
end
