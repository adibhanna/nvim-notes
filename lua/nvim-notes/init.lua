local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')
local search = require('nvim-notes.search')
local tags = require('nvim-notes.tags')
local pins = require('nvim-notes.pins')
local preview = require('nvim-notes.preview')

local M = {}

-- Setup function
function M.setup(user_config)
    config.setup(user_config)

    -- Ensure vault directory exists
    local vault_path = config.get_vault_path()
    if not vim.fn.isdirectory(vault_path) then
        vim.fn.mkdir(vault_path, 'p')
    end

    -- Load pinned notes
    pins.load_pinned_notes()

    -- Set up autocmds for markdown files in vault
    vim.api.nvim_create_autocmd('BufRead', {
        pattern = vault_path .. '/*.md',
        callback = function()
            vim.opt_local.filetype = 'notes'
            if config.get_config().enable_concealing then
                vim.opt_local.conceallevel = config.get_config().conceal_level
                vim.opt_local.concealcursor = 'niv'
            end
        end
    })

    -- Auto-save notes
    if config.get_config().auto_save then
        vim.api.nvim_create_autocmd('TextChanged', {
            pattern = vault_path .. '/*.md',
            callback = function()
                vim.cmd('silent! write')
            end
        })
    end

    -- Set up keybindings
    if not user_config or user_config.disable_keybindings ~= true then
        M.setup_keybindings()
    end
end

-- Set up keybindings with which-key if available
function M.setup_keybindings()
    local has_whichkey, wk = pcall(require, 'which-key')

    if has_whichkey then
        -- Set the actual keybindings
        local opts = { noremap = true, silent = true }
        vim.keymap.set('n', '<leader><tab>n', M.new_note, vim.tbl_extend('force', opts, { desc = 'Create new note' }))
        vim.keymap.set('n', '<leader><tab>s', M.search_notes,
            vim.tbl_extend('force', opts, { desc = 'Search notes content' }))
        vim.keymap.set('n', '<leader><tab>t', M.search_by_tags,
            vim.tbl_extend('force', opts, { desc = 'Search by tags' }))
        vim.keymap.set('n', '<leader><tab>p', M.toggle_pin,
            vim.tbl_extend('force', opts, { desc = 'Toggle pin current note' }))
        vim.keymap.set('n', '<leader><tab>d', M.delete_note,
            vim.tbl_extend('force', opts, { desc = 'Delete current note' }))
        vim.keymap.set('n', '<leader><tab>v', M.preview_markdown,
            vim.tbl_extend('force', opts, { desc = 'Preview current note' }))
        vim.keymap.set('n', '<leader><tab>i', M.show_index,
            vim.tbl_extend('force', opts, { desc = 'Show notes dashboard' }))

        -- Register with which-key (v3 format)
        wk.add({
            { "<leader><tab>",  group = "Notes" },
            { "<leader><tab>n", M.new_note,         desc = "Create new note" },
            { "<leader><tab>s", M.search_notes,     desc = "Search notes (pinned first)" },
            { "<leader><tab>t", M.search_by_tags,   desc = "Search by tags" },
            { "<leader><tab>p", M.toggle_pin,       desc = "Toggle pin current note" },
            { "<leader><tab>d", M.delete_note,      desc = "Delete current note" },
            { "<leader><tab>v", M.preview_markdown, desc = "Preview current note" },
            { "<leader><tab>i", M.show_index,       desc = "Show notes dashboard" },
        })
    end
end

-- Create a new note
function M.new_note(name)
    local vault_path = config.get_vault_path()

    -- Ensure vault directory exists first
    if not vim.fn.isdirectory(vault_path) then
        local result = vim.fn.mkdir(vault_path, 'p')
        if result == 0 then
            print('Error: Failed to create vault directory: ' .. vault_path)
            return
        end
    end

    if not name or name == '' then
        name = os.date('%Y-%m-%d')
    end

    -- Ensure name has .md extension
    if not name:match('%.md$') then
        name = name .. '.md'
    end

    local note_path = vault_path .. '/' .. name

    -- Check if file already exists
    if vim.fn.filereadable(note_path) == 1 then
        local choice = vim.fn.input('Note already exists. (o)pen, (n)ew name, (c)ancel: ')

        if choice:lower() == 'o' then
            vim.cmd('edit ' .. note_path)
            return
        elseif choice:lower() == 'n' then
            local new_name = vim.fn.input('New note name: ')
            if new_name and new_name ~= '' then
                M.new_note(new_name)
            end
            return
        else
            return
        end
    end

    -- Create and open new note
    local ok, err = pcall(function()
        vim.cmd('edit ' .. vim.fn.fnameescape(note_path))
    end)

    if not ok then
        print('Error: Failed to open file: ' .. tostring(err))
        return
    end

    -- Add template if configured
    local template = config.get_config().template
    if template and template ~= '' then
        local lines = vim.split(template, '\n')
        -- Replace template variables
        for i, line in ipairs(lines) do
            lines[i] = line:gsub('{{date}}', os.date('%Y-%m-%d'))
            lines[i] = lines[i]:gsub('{{time}}', os.date('%H:%M'))
            lines[i] = lines[i]:gsub('{{title}}', name:gsub('%.md$', ''))
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end

    -- Save the file immediately after creating it
    vim.cmd('silent! write')

    -- Position cursor at end of file
    vim.cmd('normal! G')
    if vim.api.nvim_get_current_line() ~= '' then
        vim.cmd('normal! o')
    end

    vim.cmd('startinsert')
end

-- Open/search for a note
function M.open_note()
    local vault_path = config.get_vault_path()
    local notes = utils.get_all_notes()

    if #notes == 0 then
        print('No notes found in vault: ' .. vault_path)
        return
    end

    -- Use the interactive search interface
    search.interactive_search()
end

-- Search notes by content
function M.search_notes(query)
    if not query or query == '' then
        -- If no query provided, show live search interface
        search.interactive_search()
        return
    end

    -- If query provided, do traditional search
    search.search_all(query)
end

-- Search notes by tags using FZF
function M.search_by_tags(tag_query)
    if not tag_query or tag_query == '' then
        -- Use FZF for tag selection
        search.search_by_tags()
        return
    end

    tags.search_by_tags(tag_query)
end

-- Toggle pin status of current note
function M.toggle_pin()
    local current_file = vim.fn.expand('%:p')
    local vault_path = config.get_vault_path()

    -- Check if current file is in vault
    if not current_file:find(vault_path, 1, true) then
        print('Current file is not in the notes vault')
        return
    end

    if not current_file:match('%.md$') then
        print('Current file is not a markdown file')
        return
    end

    pins.toggle_pin(current_file)
end

-- Show pinned notes - now integrated into main search
function M.show_pinned()
    -- Just use regular search which will show pinned notes first
    search.interactive_search()
end

-- Preview current note in markdown
function M.preview_markdown()
    local current_file = vim.fn.expand('%:p')

    if not current_file:match('%.md$') then
        print('Current file is not a markdown file')
        return
    end

    preview.preview_markdown(current_file)
end

-- Show notes index/dashboard
function M.show_index()
    local vault_path = config.get_vault_path()
    local notes = utils.get_all_notes()
    local pinned_notes = pins.get_pinned_notes()
    local recent_notes = utils.get_recent_notes(5)
    local all_tags = tags.get_all_tags()

    local Popup = require('nui.popup')
    local event = require('nui.utils.autocmd').event

    -- Calculate dynamic height based on content
    local content_lines = 8 -- Base lines (header + stats + separators)
    content_lines = content_lines + math.min(#pinned_notes, 5) + (pinned_notes and #pinned_notes > 0 and 2 or 0)
    content_lines = content_lines + math.min(#recent_notes, 5) + 2
    content_lines = content_lines + math.min(#all_tags, 8) + (all_tags and #all_tags > 0 and 2 or 0)
    content_lines = content_lines + 9 -- Shortcuts section

    local height = math.min(content_lines + 4, math.floor(vim.o.lines * 0.8))
    local width = math.min(80, math.floor(vim.o.columns * 0.8))

    local popup = Popup({
        position = '50%',
        size = {
            width = width,
            height = height,
        },
        border = {
            style = 'rounded',
            text = {
                top = ' 📚 Notes Dashboard ',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:Normal',
        },
        buf_options = {
            modifiable = false,
            readonly = true,
            filetype = 'markdown',
        },
    })

    -- Build content
    local lines = {}

    -- Header stats
    table.insert(lines, '📁 **Vault:** `' .. vim.fn.fnamemodify(vault_path, ':~') .. '`')
    table.insert(lines, '📄 **Total Notes:** `' .. #notes .. '`')
    table.insert(lines, '📌 **Pinned Notes:** `' .. #pinned_notes .. '`')
    table.insert(lines, '🏷️  **Tags:** `' .. #all_tags .. '`')
    table.insert(lines, '')
    table.insert(lines, '─────────────────────────────────────────────────────')
    table.insert(lines, '')

    -- Pinned notes section
    if #pinned_notes > 0 then
        table.insert(lines, '### 📌 Pinned Notes')
        table.insert(lines, '')
        local display_count = math.min(#pinned_notes, 5)
        for i = 1, display_count do
            local note = pinned_notes[i]
            table.insert(lines, string.format('  • **%s** _%s_', note.title, note.modified))
        end
        if #pinned_notes > 5 then
            table.insert(lines, string.format('  ⋯ and %d more pinned notes', #pinned_notes - 5))
        end
        table.insert(lines, '')
    end

    -- Recent notes section
    if #recent_notes > 0 then
        table.insert(lines, '### 🕐 Recent Notes')
        table.insert(lines, '')
        for _, note in ipairs(recent_notes) do
            table.insert(lines, string.format('  • **%s** _%s_', note.title, note.modified))
        end
        table.insert(lines, '')
    end

    -- Popular tags section
    if #all_tags > 0 then
        table.insert(lines, '### 🏷️  Popular Tags')
        table.insert(lines, '')
        local tag_line = '  '
        local display_count = math.min(#all_tags, 8)
        for i = 1, display_count do
            local tag = all_tags[i]
            tag_line = tag_line .. string.format('`#%s (%d)` ', tag.name, tag.count)
            if i % 4 == 0 and i < display_count then
                table.insert(lines, tag_line)
                tag_line = '  '
            end
        end
        if tag_line ~= '  ' then
            table.insert(lines, tag_line)
        end
        table.insert(lines, '')
    end

    -- Shortcuts section
    table.insert(lines, '─────────────────────────────────────────────────────')
    table.insert(lines, '')
    table.insert(lines, '### ⚡ Quick Actions')
    table.insert(lines, '')
    table.insert(lines, '  `<tab>n` New Note    `<tab>s` Search    `<tab>t` Tags')
    table.insert(lines, '  `<tab>p` Pin Toggle  `<tab>d` Delete    `<tab>v` Preview')
    table.insert(lines, '')
    table.insert(lines, '_Press ESC to close, ? for help_')

    -- Set content
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)

    -- Mount the popup
    popup:mount()

    -- Set up keybindings
    local function close_popup()
        popup:unmount()
    end

    -- Quick action keybindings
    popup:map('n', '<Esc>', close_popup, { noremap = true })
    popup:map('n', 'q', close_popup, { noremap = true })
    popup:map('n', 'n', function()
        close_popup()
        M.new_note()
    end, { noremap = true })
    popup:map('n', 's', function()
        close_popup()
        M.search_notes()
    end, { noremap = true })
    popup:map('n', 't', function()
        close_popup()
        M.search_by_tags()
    end, { noremap = true })
    popup:map('n', 'd', function()
        close_popup()
        M.delete_note()
    end, { noremap = true })
    popup:map('n', 'v', function()
        close_popup()
        M.preview_markdown()
    end, { noremap = true })
    popup:map('n', '?', function()
        vim.notify('Dashboard Help:\n\n' ..
            'n - New note\n' ..
            's - Search notes (pinned shown first)\n' ..
            't - Search by tags\n' ..
            'd - Delete current note\n' ..
            'v - Preview current note\n' ..
            'q/ESC - Close dashboard', vim.log.levels.INFO)
    end, { noremap = true })

    -- Auto-close on buffer leave
    popup:on(event.BufLeave, function()
        popup:unmount()
    end)
end

-- Set vault directory
function M.set_vault(path)
    if not path or path == '' then
        local Input = require('nui.input')
        local event = require('nui.utils.autocmd').event

        local input = Input({
            position = '50%',
            size = { width = 60 },
            border = {
                style = 'rounded',
                text = {
                    top = '[📂 Set Vault Path]',
                    top_align = 'center',
                },
            },
            win_options = {
                winhighlight = 'Normal:Normal,FloatBorder:Normal',
            },
        }, {
            prompt = '> ',
            default_value = vim.fn.expand('~'),
            on_close = function() end,
            on_submit = function(value)
                if value and value ~= '' then
                    M.set_vault(value)
                end
            end,
        })

        input:mount()
        input:on(event.BufLeave, function()
            input:unmount()
        end)
        return
    end

    path = vim.fn.expand(path)
    config.set_vault_path(path)

    -- Create directory if it doesn't exist
    if not vim.fn.isdirectory(path) then
        vim.fn.mkdir(path, 'p')
    end

    print('Vault set to: ' .. path)
end

-- Delete current note
function M.delete_note()
    local current_file = vim.fn.expand('%:p')
    local vault_path = config.get_vault_path()

    -- Check if current file is in vault
    if not current_file:find(vault_path, 1, true) then
        print('Current file is not in the notes vault')
        return
    end

    if not current_file:match('%.md$') then
        print('Current file is not a markdown file')
        return
    end

    -- Get note name for confirmation
    local note_name = vim.fn.fnamemodify(current_file, ':t')

    -- Confirmation prompt
    local choice = vim.fn.input('Delete note "' .. note_name .. '"? (y/N): ')

    if choice:lower() ~= 'y' and choice:lower() ~= 'yes' then
        print('Note deletion cancelled')
        return
    end

    -- Remove from pins if it's pinned
    local pins = require('nvim-notes.pins')
    if pins.is_pinned(current_file) then
        pins.unpin_note(current_file)
        print('Note unpinned before deletion')
    end

    -- Close the buffer first
    vim.cmd('bdelete!')

    -- Delete the file
    local success = vim.fn.delete(current_file)
    if success == 0 then
        print('Note "' .. note_name .. '" deleted successfully')
    else
        print('Failed to delete note "' .. note_name .. '"')
    end
end

return M
