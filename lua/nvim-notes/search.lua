local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

-- Search notes by content
function M.search_content(query)
    local vault_path = config.get_vault_path()
    local notes = utils.get_all_notes()
    local results = {}

    for _, note in ipairs(notes) do
        local matches = utils.search_file_content(note.path, query)
        if #matches > 0 then
            table.insert(results, {
                note = note,
                matches = matches,
                match_count = #matches
            })
        end
    end

    if #results == 0 then
        print('No notes found containing: ' .. query)
        return
    end

    -- Sort by number of matches (descending)
    table.sort(results, function(a, b)
        return a.match_count > b.match_count
    end)

    M.show_search_results(results, 'Content search: ' .. query)
end

-- Search notes by filename
function M.search_filename(query)
    local notes = utils.get_all_notes()
    local results = {}
    local query_lower = query:lower()

    for _, note in ipairs(notes) do
        local title_lower = note.title:lower()
        local relative_path_lower = note.relative_path:lower()

        if title_lower:find(query_lower, 1, true) or
            relative_path_lower:find(query_lower, 1, true) then
            table.insert(results, {
                note = note,
                matches = { {
                    line_number = 1,
                    line_content = note.title,
                    context = {}
                } },
                match_count = 1
            })
        end
    end

    if #results == 0 then
        print('No notes found with filename containing: ' .. query)
        return
    end

    M.show_search_results(results, 'Filename search: ' .. query)
end

-- Combined search (content and filename)
function M.search_all(query)
    local vault_path = config.get_vault_path()
    local notes = utils.get_all_notes()
    local results = {}
    local query_lower = query:lower()

    for _, note in ipairs(notes) do
        local content_matches = utils.search_file_content(note.path, query)
        local filename_match = false

        -- Check filename match
        local title_lower = note.title:lower()
        local relative_path_lower = note.relative_path:lower()

        if title_lower:find(query_lower, 1, true) or
            relative_path_lower:find(query_lower, 1, true) then
            filename_match = true
        end

        if #content_matches > 0 or filename_match then
            local matches = content_matches
            if filename_match and #content_matches == 0 then
                matches = { {
                    line_number = 0,
                    line_content = '📁 ' .. note.title,
                    context = {}
                } }
            end

            table.insert(results, {
                note = note,
                matches = matches,
                match_count = #matches,
                filename_match = filename_match
            })
        end
    end

    if #results == 0 then
        print('No notes found containing: ' .. query)
        return
    end

    -- Sort by filename matches first, then by match count
    table.sort(results, function(a, b)
        if a.filename_match and not b.filename_match then
            return true
        elseif not a.filename_match and b.filename_match then
            return false
        else
            return a.match_count > b.match_count
        end
    end)

    M.show_search_results(results, 'Search: ' .. query)
end

-- Show search results in a buffer
function M.show_search_results(results, title)
    M.show_buffer_results(results, title)
end

-- Show results using nui.nvim menu
function M.show_buffer_results(results, title)
    if #results == 0 then
        print('No results found')
        return
    end

    local Menu = require('nui.menu')
    local Text = require('nui.text')

    local menu_items = {}

    for i, result in ipairs(results) do
        -- Create menu item for each result
        local display_text = string.format('%d. %s (%d matches)', i, result.note.title, result.match_count)
        table.insert(menu_items, Menu.item(display_text, {
            result = result,
            index = i
        }))

        -- Add separator between results if there are matches to show
        if #result.matches > 0 and i < #results then
            table.insert(menu_items, Menu.separator(''))
        end
    end

    local menu = Menu({
        position = '50%',
        size = {
            width = math.min(100, vim.o.columns - 4),
            height = math.min(25, #menu_items + 4),
        },
        border = {
            style = 'rounded',
            text = {
                top = '[🔍 ' .. title .. ']',
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
        },
        on_close = function()
            -- Menu closed
        end,
        on_submit = function(item)
            if item.result then
                vim.cmd('edit ' .. item.result.note.path)
                -- If there are specific line matches, jump to the first one
                if #item.result.matches > 0 and item.result.matches[1].line_number > 0 then
                    vim.api.nvim_win_set_cursor(0, { item.result.matches[1].line_number, 0 })
                end
            end
        end,
    })

    menu:mount()
end

-- Interactive search with live results
function M.interactive_search()
    local Layout = require('nui.layout')
    local Input = require('nui.input')
    local Menu = require('nui.menu')
    local event = require('nui.utils.autocmd').event

    local notes = utils.get_all_notes()
    if #notes == 0 then
        print('No notes found in vault')
        return
    end

    local filtered_notes = notes
    local menu_items = {}

    -- Function to update menu items based on search
    local function update_menu_items(search_query)
        menu_items = {}
        filtered_notes = {}

        if not search_query or search_query == '' then
            filtered_notes = notes
        else
            local query_lower = search_query:lower()
            for _, note in ipairs(notes) do
                -- Search in title and content
                local title_match = note.title:lower():find(query_lower, 1, true)
                local content_matches = utils.search_file_content(note.path, search_query)

                if title_match or #content_matches > 0 then
                    table.insert(filtered_notes, note)
                end
            end
        end

        for i, note in ipairs(filtered_notes) do
            local display_text = string.format('%d. %s (%s)', i, note.title, note.modified)
            table.insert(menu_items, Menu.item(display_text, { note = note }))
        end

        return menu_items
    end

    -- Create initial menu items
    update_menu_items('')

    -- Create input component
    local input = Input({
        border = {
            style = 'rounded',
            text = {
                top = '[🔍 Search Notes]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:Normal',
        },
    }, {
        prompt = '> ',
        default_value = '',
        on_close = function() end,
        on_submit = function(value)
            -- Enter pressed in search box - open first result if available
            if #filtered_notes > 0 then
                vim.cmd('edit ' .. filtered_notes[1].path)
            end
        end,
    })

    -- Create menu component
    local menu = Menu({
        border = {
            style = 'rounded',
            text = {
                top = '[📝 Notes (' .. #notes .. ' total)]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:Normal',
        },
    }, {
        lines = menu_items,
        max_width = 80,
        keymap = {
            focus_next = { 'j', '<Down>', '<Tab>' },
            focus_prev = { 'k', '<Up>', '<S-Tab>' },
            close = { '<Esc>', '<C-c>' },
            submit = { '<CR>', '<Space>' },
        },
        on_close = function() end,
        on_submit = function(item)
            if item.note then
                vim.cmd('edit ' .. item.note.path)
            end
        end,
    })

    -- Create layout
    local layout = Layout(
        {
            position = '50%',
            size = {
                width = math.min(100, vim.o.columns - 4),
                height = math.min(30, vim.o.lines - 4),
            },
        },
        Layout.Box({
            Layout.Box(input, { size = 3 }),
            Layout.Box(menu, { size = '100%' }),
        }, { dir = 'col' })
    )

    -- Set up live search
    local search_timer = nil
    input:on(event.TextChangedI, function()
        if search_timer then
            vim.fn.timer_stop(search_timer)
        end

        search_timer = vim.fn.timer_start(150, function()
            local current_value = vim.api.nvim_buf_get_lines(input.bufnr, 0, 1, false)[1]
            if current_value then
                -- Remove the prompt from the value
                local search_query = current_value:gsub('^> ', '')
                update_menu_items(search_query)

                -- Update menu
                menu:unmount()
                menu = Menu({
                    border = {
                        style = 'rounded',
                        text = {
                            top = '[📝 ' ..
                                (#filtered_notes > 0 and filtered_notes[1].title or 'No matches') ..
                                ' (' .. #filtered_notes .. '/' .. #notes .. ')]',
                            top_align = 'center',
                        },
                    },
                    win_options = {
                        winhighlight = 'Normal:Normal,FloatBorder:Normal',
                    },
                }, {
                    lines = menu_items,
                    max_width = 80,
                    keymap = {
                        focus_next = { 'j', '<Down>', '<Tab>' },
                        focus_prev = { 'k', '<Up>', '<S-Tab>' },
                        close = { '<Esc>', '<C-c>' },
                        submit = { '<CR>', '<Space>' },
                    },
                    on_close = function() end,
                    on_submit = function(item)
                        if item.note then
                            layout:unmount()
                            vim.cmd('edit ' .. item.note.path)
                        end
                    end,
                })

                -- Update layout
                layout:update(Layout.Box({
                    Layout.Box(input, { size = 3 }),
                    Layout.Box(menu, { size = '100%' }),
                }, { dir = 'col' }))
            end
        end)
    end)

    -- Key mappings for navigation between input and menu
    input:map('n', '<Tab>', function()
        vim.api.nvim_set_current_win(menu.winid)
    end, { noremap = true })

    input:map('i', '<Tab>', function()
        vim.api.nvim_set_current_win(menu.winid)
    end, { noremap = true })

    menu:map('n', '<S-Tab>', function()
        vim.api.nvim_set_current_win(input.winid)
        vim.cmd('startinsert!')
    end, { noremap = true })

    -- Close all on escape
    input:map('n', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    input:map('i', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    menu:map('n', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    -- Mount the layout
    layout:mount()

    -- Focus input and enter insert mode
    vim.api.nvim_set_current_win(input.winid)
    vim.cmd('startinsert!')
end

-- Live note finder - shows all notes with live filtering
function M.live_note_finder()
    return M.interactive_search()
end

return M
