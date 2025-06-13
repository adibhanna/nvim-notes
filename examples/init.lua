-- Example configuration for nvim-notes
-- Add this to your Neovim configuration

-- Basic setup
require('nvim-notes').setup()

-- Advanced setup with custom configuration
require('nvim-notes').setup({
    -- Vault configuration
    vault_path = '~/Documents/Notes', -- Custom vault location
    auto_save = true,               -- Auto-save notes

    -- Template configuration
    template = [[
# {{title}}

**Created:** {{date}} at {{time}}
**Tags:**

---

## Notes

]],

    -- Preview configuration
    preview_command = 'glow -p', -- Force glow for preview

    -- UI configuration
    enable_concealing = true,
    conceal_level = 2,
    telescope_theme = 'ivy', -- or 'dropdown', 'cursor'

    -- Behavior configuration
    max_recent_notes = 15,
    disable_default_keybindings = false,
})

-- Custom keybindings (optional)
local notes = require('nvim-notes')
vim.keymap.set('n', '<leader>nd', function()
    notes.new_note(os.date('%Y-%m-%d-daily'))
end, { desc = 'Create daily note' })

vim.keymap.set('n', '<leader>nw', function()
    notes.new_note(os.date('%Y-W%V-weekly'))
end, { desc = 'Create weekly note' })

-- Quick access to important notes
vim.keymap.set('n', '<leader>nt', function()
    notes.search_by_tags('todo urgent')
end, { desc = 'Search urgent todos' })

-- Custom commands
vim.api.nvim_create_user_command('NotesDaily', function()
    notes.new_note(os.date('%Y-%m-%d-daily'))
end, { desc = 'Create daily note' })

vim.api.nvim_create_user_command('NotesWeekly', function()
    notes.new_note(os.date('%Y-W%V-weekly'))
end, { desc = 'Create weekly note' })

vim.api.nvim_create_user_command('NotesTodo', function()
    notes.search_by_tags('todo')
end, { desc = 'Search todo notes' })
