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

-- Interactive search with live results (telescope-like)
function M.interactive_search()
    local Layout = require('nui.layout')
    local Popup = require('nui.popup')
    local event = require('nui.utils.autocmd').event

    local notes = utils.get_all_notes()
    if #notes == 0 then
        print('No notes found in vault')
        return
    end

    local filtered_notes = notes
    local selected_idx = 1
    local search_query = ''

    -- Create search input popup
    local search_popup = Popup({
        border = {
            style = 'rounded',
            text = {
                top = '[🔍 Search Notes]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:TelescopePromptNormal,FloatBorder:TelescopePromptBorder',
        },
    })

    -- Create results popup
    local results_popup = Popup({
        border = {
            style = 'rounded',
            text = {
                top = '[📝 Results]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:TelescopeResultsNormal,FloatBorder:TelescopeResultsBorder',
        },
    })

    -- Create preview popup
    local preview_popup = Popup({
        border = {
            style = 'rounded',
            text = {
                top = '[👁️ Preview]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:TelescopePreviewNormal,FloatBorder:TelescopePreviewBorder',
        },
    })

    -- Create layout
    local layout = Layout(
        {
            position = '50%',
            size = {
                width = math.min(120, vim.o.columns - 4),
                height = math.min(40, vim.o.lines - 4),
            },
        },
        Layout.Box({
            Layout.Box(search_popup, { size = 3 }),
            Layout.Box({
                Layout.Box(results_popup, { size = '60%' }),
                Layout.Box(preview_popup, { size = '40%' }),
            }, { dir = 'row', size = '100%' }),
        }, { dir = 'col' })
    )

    -- Function to filter notes
    local function filter_notes(query)
        if not query or query == '' then
            filtered_notes = notes
        else
            filtered_notes = {}
            local query_lower = query:lower()
            for _, note in ipairs(notes) do
                -- Search in title and content
                local title_match = note.title:lower():find(query_lower, 1, true)
                local content_matches = utils.search_file_content(note.path, query)

                if title_match or #content_matches > 0 then
                    table.insert(filtered_notes, note)
                end
            end
        end
        selected_idx = math.min(selected_idx, math.max(1, #filtered_notes))
    end

    -- Function to update results display
    local function update_results()
        local lines = {}
        for i, note in ipairs(filtered_notes) do
            local prefix = i == selected_idx and '▶ ' or '  '
            local line = string.format('%s%s (%s)', prefix, note.title, note.modified)
            table.insert(lines, line)
        end

        if #lines == 0 then
            lines = { '  No matches found' }
        end

        vim.api.nvim_buf_set_lines(results_popup.bufnr, 0, -1, false, lines)

        -- Update title with count
        local title = string.format('[📝 Results (%d/%d)]', #filtered_notes, #notes)
        vim.api.nvim_buf_set_name(results_popup.bufnr, title)
    end

    -- Function to update preview
    local function update_preview()
        if #filtered_notes == 0 or selected_idx > #filtered_notes then
            vim.api.nvim_buf_set_lines(preview_popup.bufnr, 0, -1, false, { 'No preview available' })
            return
        end

        local note = filtered_notes[selected_idx]
        local lines = vim.fn.readfile(note.path)

        -- Limit preview lines
        if #lines > 30 then
            lines = vim.list_slice(lines, 1, 30)
            table.insert(lines, '...')
        end

        vim.api.nvim_buf_set_lines(preview_popup.bufnr, 0, -1, false, lines)

        -- Set filetype for syntax highlighting
        vim.api.nvim_buf_set_option(preview_popup.bufnr, 'filetype', 'markdown')
    end

    -- Function to update search prompt
    local function update_search()
        local prompt_line = '> ' .. search_query
        vim.api.nvim_buf_set_lines(search_popup.bufnr, 0, -1, false, { prompt_line })

        -- Position cursor at the end
        vim.api.nvim_win_set_cursor(search_popup.winid, { 1, #prompt_line })
    end

    -- Function to open selected note
    local function open_selected_note()
        if #filtered_notes > 0 and selected_idx <= #filtered_notes then
            local note = filtered_notes[selected_idx]
            layout:unmount()
            vim.cmd('edit ' .. note.path)
        end
    end

    -- Initial setup
    filter_notes('')

    -- Mount layout
    layout:mount()

    -- Set up search popup
    update_search()
    update_results()
    update_preview()

    -- Set buffer to be editable and disable completion
    vim.api.nvim_buf_set_option(search_popup.bufnr, 'modifiable', true)
    vim.api.nvim_buf_set_option(search_popup.bufnr, 'buftype', 'prompt')
    vim.api.nvim_buf_set_option(search_popup.bufnr, 'filetype', '')

    -- Disable completion plugins
    vim.api.nvim_buf_set_var(search_popup.bufnr, 'cmp_enabled', false)
    vim.api.nvim_buf_set_var(search_popup.bufnr, 'completion_enable', false)

    -- Disable blink.cmp specifically
    pcall(function()
        vim.api.nvim_buf_set_var(search_popup.bufnr, 'blink_cmp_enabled', false)
    end)

    -- Set additional buffer options to prevent completion
    vim.api.nvim_win_set_option(search_popup.winid, 'completefunc', '')
    vim.api.nvim_win_set_option(search_popup.winid, 'omnifunc', '')

    -- Create autocmd to disable completion when entering this buffer
    vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertEnter' }, {
        buffer = search_popup.bufnr,
        callback = function()
            -- Disable various completion options
            vim.opt_local.complete = ''
            vim.opt_local.completeopt = ''

            -- Disable completion plugins via buffer variables
            vim.b.cmp_enabled = false
            vim.b.completion_enable = false
            pcall(function()
                vim.b.blink_cmp_enabled = false
            end)
        end,
    })

    -- Focus search and enter insert mode
    vim.api.nvim_set_current_win(search_popup.winid)
    vim.cmd('startinsert!')

    -- Key mappings for search popup
    search_popup:map('i', '<CR>', function()
        open_selected_note()
    end, { noremap = true })

    search_popup:map('i', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    search_popup:map('i', '<C-j>', function()
        selected_idx = math.min(selected_idx + 1, #filtered_notes)
        update_results()
        update_preview()
    end, { noremap = true })

    search_popup:map('i', '<C-k>', function()
        selected_idx = math.max(selected_idx - 1, 1)
        update_results()
        update_preview()
    end, { noremap = true })

    search_popup:map('i', '<Down>', function()
        selected_idx = math.min(selected_idx + 1, #filtered_notes)
        update_results()
        update_preview()
    end, { noremap = true })

    search_popup:map('i', '<Up>', function()
        selected_idx = math.max(selected_idx - 1, 1)
        update_results()
        update_preview()
    end, { noremap = true })

    search_popup:map('i', '<C-c>', function()
        layout:unmount()
    end, { noremap = true })

    -- Set up live search
    local search_timer = nil
    search_popup:on(event.TextChangedI, function()
        if search_timer then
            vim.fn.timer_stop(search_timer)
        end

        search_timer = vim.fn.timer_start(150, function()
            local current_line = vim.api.nvim_buf_get_lines(search_popup.bufnr, 0, 1, false)[1] or ''
            search_query = current_line:gsub('^> ', '')

            filter_notes(search_query)
            update_results()
            update_preview()
        end)
    end)

    -- Key mappings for results popup
    results_popup:map('n', '<CR>', function()
        open_selected_note()
    end, { noremap = true })

    results_popup:map('n', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    results_popup:map('n', 'j', function()
        selected_idx = math.min(selected_idx + 1, #filtered_notes)
        update_results()
        update_preview()
    end, { noremap = true })

    results_popup:map('n', 'k', function()
        selected_idx = math.max(selected_idx - 1, 1)
        update_results()
        update_preview()
    end, { noremap = true })

    results_popup:map('n', 'i', function()
        vim.api.nvim_set_current_win(search_popup.winid)
        vim.cmd('startinsert!')
    end, { noremap = true })

    -- Key mappings for preview popup
    preview_popup:map('n', '<Esc>', function()
        layout:unmount()
    end, { noremap = true })

    preview_popup:map('n', 'i', function()
        vim.api.nvim_set_current_win(search_popup.winid)
        vim.cmd('startinsert!')
    end, { noremap = true })

    preview_popup:map('n', '<CR>', function()
        open_selected_note()
    end, { noremap = true })
end

-- Live note finder - shows all notes with live filtering
function M.live_note_finder()
    return M.interactive_search()
end

return M
