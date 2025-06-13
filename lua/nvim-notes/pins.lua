local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

local pinned_notes = {}
local pins_file_path = nil

-- Initialize pins file path
local function init_pins_file()
    if not pins_file_path then
        local vault_path = config.get_vault_path()
        pins_file_path = vault_path .. '/.nvim-notes-pins'
    end
    return true
end

-- Save pinned notes to file
local function save_pins_to_file()
    if not init_pins_file() then
        return false
    end

    local file = io.open(pins_file_path, 'w')
    if not file then
        return false
    end

    for _, note_path in ipairs(pinned_notes) do
        file:write(note_path .. '\n')
    end
    file:close()
    return true
end

-- Load pinned notes from file
local function load_pins_from_file()
    if not init_pins_file() then
        return false
    end

    pinned_notes = {}

    local file = io.open(pins_file_path, 'r')
    if not file then
        return true
    end

    for line in file:lines() do
        line = line:match('^%s*(.-)%s*$') -- trim whitespace
        if line and line ~= '' then
            table.insert(pinned_notes, line)
        end
    end
    file:close()

    return true
end

-- Load pinned notes from file
function M.load_pinned_notes()
    if not load_pins_from_file() then
        print('Failed to load pinned notes')
        return
    end

    -- Clean up pinned notes that no longer exist
    M.clean_pinned_notes()
end

-- Add note to pins
local function save_pin(note_path)
    -- Add to memory if not already there
    if not vim.tbl_contains(pinned_notes, note_path) then
        table.insert(pinned_notes, 1, note_path) -- Add to front
    end

    -- Save to file
    return save_pins_to_file()
end

-- Remove note from pins
local function remove_pin(note_path)
    -- Remove from memory
    for i, pinned_path in ipairs(pinned_notes) do
        if pinned_path == note_path then
            table.remove(pinned_notes, i)
            break
        end
    end

    -- Save to file
    return save_pins_to_file()
end

-- Clean up pinned notes that no longer exist
function M.clean_pinned_notes()
    local cleaned = {}

    for _, note_path in ipairs(pinned_notes) do
        if vim.fn.filereadable(note_path) == 1 then
            table.insert(cleaned, note_path)
        else
            -- Remove from database if file no longer exists
            remove_pin(note_path)
        end
    end

    if #cleaned ~= #pinned_notes then
        pinned_notes = cleaned
        print('Cleaned up ' .. (#pinned_notes - #cleaned) .. ' non-existent pinned notes')
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
        local success = remove_pin(note_path)
        if success then
            print('Note unpinned')
            return false
        else
            print('Failed to unpin note')
            return nil
        end
    else
        -- Pin
        local success = save_pin(note_path)
        if success then
            print('Note pinned')
            return true
        else
            print('Failed to pin note')
            return nil
        end
    end
end

-- Pin a note
function M.pin_note(note_path)
    if not M.is_pinned(note_path) then
        local success = save_pin(note_path)
        if success then
            table.insert(pinned_notes, note_path)
        end
    end
end

-- Unpin a note
function M.unpin_note(note_path)
    local success = remove_pin(note_path)
    if success then
        for i, pinned_path in ipairs(pinned_notes) do
            if pinned_path == note_path then
                table.remove(pinned_notes, i)
                break
            end
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
