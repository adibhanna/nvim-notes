local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

local pinned_notes = {}
local pinned_file_path = nil

-- Initialize pinned file path
local function init_pinned_file_path()
    if not pinned_file_path then
        local data_dir = vim.fn.stdpath('data') .. '/nvim-notes'
        pinned_file_path = data_dir .. '/pinned.json'

        -- Create directory if it doesn't exist
        if not vim.fn.isdirectory(data_dir) then
            local success = vim.fn.mkdir(data_dir, 'p')
            if success == 0 then
                print('Warning: Failed to create nvim-notes data directory: ' .. data_dir)
            end
        end
    end
end

-- Load pinned notes from file
function M.load_pinned_notes()
    init_pinned_file_path()

    if vim.fn.filereadable(pinned_file_path) == 1 then
        local lines = vim.fn.readfile(pinned_file_path)
        if #lines > 0 then
            local ok, data = pcall(vim.fn.json_decode, lines[1])
            if ok and data and type(data) == 'table' then
                pinned_notes = data
            end
        end
    end

    -- Clean up pinned notes that no longer exist
    M.clean_pinned_notes()
end

-- Save pinned notes to file
function M.save_pinned_notes()
    init_pinned_file_path()

    -- Ensure directory exists before writing
    local data_dir = vim.fn.fnamemodify(pinned_file_path, ':h')
    if not vim.fn.isdirectory(data_dir) then
        local success = vim.fn.mkdir(data_dir, 'p')
        if success == 0 then
            error('Failed to create directory: ' .. data_dir)
        end
    end

    local encoded = vim.fn.json_encode(pinned_notes)
    local success = pcall(vim.fn.writefile, { encoded }, pinned_file_path)
    if not success then
        error('Failed to write pinned notes file: ' .. pinned_file_path)
    end
end

-- Clean up pinned notes that no longer exist
function M.clean_pinned_notes()
    local cleaned = {}

    for _, note_path in ipairs(pinned_notes) do
        if vim.fn.filereadable(note_path) == 1 then
            table.insert(cleaned, note_path)
        end
    end

    if #cleaned ~= #pinned_notes then
        pinned_notes = cleaned
        M.save_pinned_notes()
    end
end

-- Check if a note is pinned
function M.is_pinned(note_path)
    return vim.tbl_contains(pinned_notes, note_path)
end

-- Toggle pin status of a note
function M.toggle_pin(note_path)
    if M.is_pinned(note_path) then
        -- Unpin
        for i, pinned_path in ipairs(pinned_notes) do
            if pinned_path == note_path then
                table.remove(pinned_notes, i)
                break
            end
        end
        M.save_pinned_notes()
        return false
    else
        -- Pin
        table.insert(pinned_notes, note_path)
        M.save_pinned_notes()
        return true
    end
end

-- Pin a note
function M.pin_note(note_path)
    if not M.is_pinned(note_path) then
        table.insert(pinned_notes, note_path)
        M.save_pinned_notes()
    end
end

-- Unpin a note
function M.unpin_note(note_path)
    for i, pinned_path in ipairs(pinned_notes) do
        if pinned_path == note_path then
            table.remove(pinned_notes, i)
            M.save_pinned_notes()
            break
        end
    end
end

-- Get all pinned notes with metadata
function M.get_pinned_notes()
    M.clean_pinned_notes()

    local pinned_with_info = {}

    for _, note_path in ipairs(pinned_notes) do
        local note_info = utils.get_note_info(note_path)
        if note_info then
            table.insert(pinned_with_info, note_info)
        end
    end

    -- Sort by modification time (newest first)
    table.sort(pinned_with_info, function(a, b)
        return a.modified_time > b.modified_time
    end)

    return pinned_with_info
end

-- Show pinned notes
function M.show_pinned_notes()
    local pinned = M.get_pinned_notes()

    if #pinned == 0 then
        print('No pinned notes')
        return
    end

    M.show_buffer_pinned(pinned)
end

-- Show pinned notes using nui.nvim
function M.show_buffer_pinned(pinned_notes_list)
    if #pinned_notes_list == 0 then
        print('No pinned notes yet. Use <leader>np to pin the current note.')
        return
    end

    local Menu = require('nui.menu')

    local menu_items = {}

    for i, note in ipairs(pinned_notes_list) do
        local tags = utils.extract_tags(note.path)
        local tags_display = #tags > 0 and ' [' .. table.concat(tags, ', ') .. ']' or ''
        local display_text = string.format('📌 %d. %s%s', i, note.title, tags_display)
        table.insert(menu_items, Menu.item(display_text, { note = note }))
    end

    local menu = Menu({
        position = '50%',
        size = {
            width = math.min(100, vim.o.columns - 4),
            height = math.min(20, #menu_items + 4),
        },
        border = {
            style = 'rounded',
            text = {
                top = '[📌 Pinned Notes (' .. #pinned_notes_list .. ' total)]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:Normal',
        },
    }, {
        lines = menu_items,
        max_width = 90,
        keymap = {
            focus_next = { 'j', '<Down>', '<Tab>' },
            focus_prev = { 'k', '<Up>', '<S-Tab>' },
            close = { '<Esc>', '<C-c>' },
            submit = { '<CR>', '<Space>' },
            unpin = { 'u', 'U' },
        },
        on_close = function()
            -- Menu closed
        end,
        on_submit = function(item)
            if item.note then
                vim.cmd('edit ' .. item.note.path)
            end
        end,
    })

    -- Add custom keymap for unpinning
    menu:map('n', 'u', function()
        local tree = menu.tree
        local node = tree:get_node()
        if node and node.note then
            M.unpin_note(node.note.path)
            print('Unpinned: ' .. node.note.title)
            menu:unmount()
            -- Show updated list
            vim.defer_fn(function()
                M.show_pinned_notes()
            end, 100)
        end
    end, { noremap = true })

    menu:mount()
end

-- Get pinned notes count
function M.get_pinned_count()
    return #pinned_notes
end

-- Clear all pinned notes
function M.clear_all_pins()
    local choice = vim.fn.input('Clear all pinned notes? (y/N): ')
    if choice:lower() == 'y' then
        pinned_notes = {}
        M.save_pinned_notes()
        print('All pinned notes cleared')
    end
end

-- Initialize pins module
function M.init()
    M.load_pinned_notes()
end

return M
