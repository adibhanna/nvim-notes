local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

local pinned_notes = {}
local db_path = nil

-- Initialize database path and create tables
local function init_database()
    if not db_path then
        local data_dir = vim.fn.stdpath('data') .. '/nvim-notes'
        db_path = data_dir .. '/notes.db'

        -- Create directory if it doesn't exist
        if not vim.fn.isdirectory(data_dir) then
            local success = vim.fn.mkdir(data_dir, 'p')
            if success == 0 then
                print('Warning: Failed to create nvim-notes data directory: ' .. data_dir)
                return false
            end
        end

        -- Create database and tables if they don't exist
        M.create_tables()
    end
    return true
end

-- Execute SQL command
local function execute_sql(sql, params)
    params = params or {}

    -- Simple file-based database implementation
    -- We'll store data in a simple text format for reliability
    local success, result = pcall(function()
        if sql:match('^CREATE TABLE') then
            -- Table creation - just ensure file exists
            local db_file = io.open(db_path, 'a')
            if db_file then
                db_file:close()
                return true
            end
            return false
        elseif sql:match('^INSERT') then
            -- Insert operation
            local note_path = params[1]
            local timestamp = params[2] or os.time()

            print('DEBUG: INSERT operation - note_path: ' ..
                tostring(note_path) .. ', timestamp: ' .. tostring(timestamp))
            print('DEBUG: Attempting to open file for append: ' .. db_path)

            local db_file = io.open(db_path, 'a')
            if db_file then
                print('DEBUG: File opened successfully, writing data')
                local line = string.format('%s|%d\n', note_path, timestamp)
                print('DEBUG: Writing line: ' .. line:sub(1, -2)) -- Remove trailing newline for display

                local write_success = db_file:write(line)
                db_file:close()

                if write_success then
                    print('DEBUG: Write successful')
                    return true
                else
                    print('DEBUG: Write failed')
                    return false
                end
            else
                print('DEBUG: Failed to open file for writing: ' .. db_path)
                return false
            end
        elseif sql:match('^DELETE') then
            -- Delete operation
            local note_path = params[1]

            -- Read all lines
            local lines = {}
            local db_file = io.open(db_path, 'r')
            if db_file then
                for line in db_file:lines() do
                    local path = line:match('^([^|]+)')
                    if path ~= note_path then
                        table.insert(lines, line)
                    end
                end
                db_file:close()

                -- Write back without the deleted entry
                db_file = io.open(db_path, 'w')
                if db_file then
                    for _, line in ipairs(lines) do
                        db_file:write(line .. '\n')
                    end
                    db_file:close()
                    return true
                end
            end
            return false
        elseif sql:match('^SELECT') then
            -- Select operation
            local results = {}
            local db_file = io.open(db_path, 'r')
            if db_file then
                for line in db_file:lines() do
                    if line ~= '' then
                        local path, timestamp = line:match('^([^|]+)|(%d+)')
                        if path and timestamp then
                            table.insert(results, { path = path, timestamp = tonumber(timestamp) })
                        end
                    end
                end
                db_file:close()
            end
            return results
        end

        return false
    end)

    if success then
        return result
    else
        print('Database operation failed: ' .. tostring(result))
        return false
    end
end

-- Create database tables
function M.create_tables()
    local sql = [[
        CREATE TABLE IF NOT EXISTS pinned_notes (
            note_path TEXT PRIMARY KEY,
            pinned_at INTEGER
        )
    ]]
    return execute_sql(sql)
end

-- Load pinned notes from database
function M.load_pinned_notes()
    if not init_database() then
        print('Failed to initialize database')
        return
    end

    local sql = "SELECT note_path, pinned_at FROM pinned_notes ORDER BY pinned_at DESC"
    local results = execute_sql(sql)

    if results then
        pinned_notes = {}
        for _, row in ipairs(results) do
            table.insert(pinned_notes, row.path)
        end
        print('Loaded ' .. #pinned_notes .. ' pinned notes from database')
    else
        print('Failed to load pinned notes from database')
    end

    -- Clean up pinned notes that no longer exist
    M.clean_pinned_notes()
end

-- Save pinned note to database
local function save_pin(note_path)
    print('DEBUG: Attempting to save pin for: ' .. note_path)

    if not init_database() then
        print('DEBUG: Database initialization failed')
        return false
    end

    print('DEBUG: Database initialized, db_path: ' .. tostring(db_path))

    local sql = "INSERT OR REPLACE INTO pinned_notes (note_path, pinned_at) VALUES (?, ?)"
    local timestamp = os.time()
    print('DEBUG: Executing SQL with params: ' .. note_path .. ', ' .. timestamp)

    local success = execute_sql(sql, { note_path, timestamp })

    if success then
        print('Pinned note saved to database: ' .. note_path)
        return true
    else
        print('Failed to save pinned note to database: ' .. note_path)
        return false
    end
end

-- Remove pinned note from database
local function remove_pin(note_path)
    if not init_database() then
        return false
    end

    local sql = "DELETE FROM pinned_notes WHERE note_path = ?"
    local success = execute_sql(sql, { note_path })

    if success then
        print('Removed pinned note from database: ' .. note_path)
        return true
    else
        print('Failed to remove pinned note from database: ' .. note_path)
        return false
    end
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
            for i, pinned_path in ipairs(pinned_notes) do
                if pinned_path == note_path then
                    table.remove(pinned_notes, i)
                    break
                end
            end
            return false
        else
            error('Failed to unpin note')
        end
    else
        -- Pin
        local success = save_pin(note_path)
        if success then
            table.insert(pinned_notes, note_path)
            return true
        else
            error('Failed to pin note')
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
