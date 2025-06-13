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
    local Input = require('nui.input')
    local event = require('nui.utils.autocmd').event

    local input = Input({
        position = '50%',
        size = {
            width = 50,
        },
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
        on_close = function()
            -- Input closed
        end,
        on_submit = function(value)
            if value and value ~= '' then
                M.search_all(value)
            end
        end,
    })

    input:mount()

    -- unmount component when cursor leaves buffer
    input:on(event.BufLeave, function()
        input:unmount()
    end)
end

return M
