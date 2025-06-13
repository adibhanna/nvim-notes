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
end

-- Create a new note
function M.new_note(name)
    local vault_path = config.get_vault_path()

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
    vim.cmd('edit ' .. note_path)

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

-- Search pinned notes using FZF
function M.search_pinned_notes()
    search.search_pinned_notes()
end

-- Toggle pin status of current note
function M.toggle_pin()
    local current_file = vim.fn.expand('%:p')
    local vault_path = config.get_vault_path()

    print('DEBUG: Current file: ' .. current_file)
    print('DEBUG: Vault path: ' .. vault_path)

    -- Check if current file is in vault
    if not current_file:find(vault_path, 1, true) then
        print('Current file is not in the notes vault')
        return
    end

    if not current_file:match('%.md$') then
        print('Current file is not a markdown file')
        return
    end

    local result = pins.toggle_pin(current_file)
    if result == true then
        print('Note pinned')
    elseif result == false then
        print('Note unpinned')
    else
        print('Failed to toggle pin status')
    end
end

-- Show pinned notes using FZF
function M.show_pinned()
    search.search_pinned_notes()
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

    -- Create index buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_name(buf, 'Notes Index')

    local lines = {}
    table.insert(lines, '# Notes Dashboard')
    table.insert(lines, '')
    table.insert(lines, '**Vault:** ' .. vault_path)
    table.insert(lines, '**Total Notes:** ' .. #notes)
    table.insert(lines, '')

    -- Pinned notes
    if #pinned_notes > 0 then
        table.insert(lines, '## 📌 Pinned Notes')
        table.insert(lines, '')
        for _, note in ipairs(pinned_notes) do
            table.insert(lines, '- [' .. note.title .. '](' .. note.path .. ')')
        end
        table.insert(lines, '')
    end

    -- Recent notes
    if #recent_notes > 0 then
        table.insert(lines, '## 🕐 Recent Notes')
        table.insert(lines, '')
        for _, note in ipairs(recent_notes) do
            table.insert(lines, '- [' .. note.title .. '](' .. note.path .. ') - ' .. note.modified)
        end
        table.insert(lines, '')
    end

    -- All tags
    local all_tags = tags.get_all_tags()
    if #all_tags > 0 then
        table.insert(lines, '## 🏷️  All Tags')
        table.insert(lines, '')
        for _, tag in ipairs(all_tags) do
            table.insert(lines, '- #' .. tag.name .. ' (' .. tag.count .. ')')
        end
        table.insert(lines, '')
    end

    -- Shortcuts
    table.insert(lines, '## ⚡ Shortcuts')
    table.insert(lines, '')
    table.insert(lines, '- `<leader>nn` - New note')
    table.insert(lines, '- `<leader>no` - Open note')
    table.insert(lines, '- `<leader>ns` - Search notes')
    table.insert(lines, '- `<leader>nt` - Search by tags')
    table.insert(lines, '- `<leader>np` - Toggle pin')
    table.insert(lines, '- `<leader>nv` - Preview markdown')

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Open in new window
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)

    -- Set up link navigation
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local link = line:match('%[.-%]%((.-)%)')
        if link then
            vim.cmd('edit ' .. link)
        end
    end, { buffer = buf, noremap = true, silent = true })
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

return M
