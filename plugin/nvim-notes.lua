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

-- Set up keybindings with which-key if available
local function set_keybindings()
    local has_whichkey, wk = pcall(require, 'which-key')

    if has_whichkey then
        wk.register({
            fn = {
                name = "Notes",
                n = { notes.new_note, "Create new note" },
                s = { notes.search_notes, "Search notes content" },
                t = { notes.search_by_tags, "Search by tags" },
                p = { notes.toggle_pin, "Toggle pin current note" },
                P = { notes.search_pinned_notes, "Search pinned notes" },
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
