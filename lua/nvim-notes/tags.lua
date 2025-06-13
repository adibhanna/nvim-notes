local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

-- Get all tags from all notes
function M.get_all_tags()
    local notes = utils.get_all_notes()
    local tag_counts = {}

    for _, note in ipairs(notes) do
        local tags = utils.extract_tags(note.path)
        for _, tag in ipairs(tags) do
            if tag_counts[tag] then
                tag_counts[tag].count = tag_counts[tag].count + 1
                table.insert(tag_counts[tag].notes, note)
            else
                tag_counts[tag] = {
                    name = tag,
                    count = 1,
                    notes = { note }
                }
            end
        end
    end

    -- Convert to array and sort by count
    local tags_array = {}
    for _, tag_data in pairs(tag_counts) do
        table.insert(tags_array, tag_data)
    end

    table.sort(tags_array, function(a, b)
        return a.count > b.count
    end)

    return tags_array
end

-- Search notes by tags
function M.search_by_tags(tag_query)
    local query_tags = {}

    -- Parse tag query (space-separated tags)
    for tag in tag_query:gmatch('%S+') do
        -- Remove # if present
        tag = tag:gsub('^#', '')
        table.insert(query_tags, tag:lower())
    end

    if #query_tags == 0 then
        print('No tags specified')
        return
    end

    local notes = utils.get_all_notes()
    local matching_notes = {}

    for _, note in ipairs(notes) do
        local note_tags = utils.extract_tags(note.path)
        local note_tags_lower = {}

        for _, tag in ipairs(note_tags) do
            table.insert(note_tags_lower, tag:lower())
        end

        -- Check if note contains all requested tags
        local matches_all = true
        local matched_tags = {}

        for _, query_tag in ipairs(query_tags) do
            local found = false
            for _, note_tag in ipairs(note_tags_lower) do
                if note_tag:find(query_tag, 1, true) then
                    found = true
                    table.insert(matched_tags, note_tag)
                    break
                end
            end
            if not found then
                matches_all = false
                break
            end
        end

        if matches_all then
            table.insert(matching_notes, {
                note = note,
                matched_tags = matched_tags,
                all_tags = note_tags
            })
        end
    end

    if #matching_notes == 0 then
        print('No notes found with tags: ' .. table.concat(query_tags, ', '))
        return
    end

    M.show_tag_results(matching_notes, 'Notes with tags: ' .. table.concat(query_tags, ', '))
end

-- Show tag search results
function M.show_tag_results(results, title)
    M.show_buffer_tag_results(results, title)
end

-- Show tag results using nui.nvim
function M.show_buffer_tag_results(results, title)
    if #results == 0 then
        print('No results found')
        return
    end

    local Menu = require('nui.menu')

    local menu_items = {}

    for i, result in ipairs(results) do
        local tags_display = '#' .. table.concat(result.all_tags, ' #')
        local display_text = string.format('%d. %s [%s]', i, result.note.title, tags_display)
        table.insert(menu_items, Menu.item(display_text, { result = result }))
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
                top = '[🏷️  ' .. title .. ']',
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
            end
        end,
    })

    menu:mount()
end

-- Show all tags in a selectable list
function M.show_all_tags()
    local all_tags = M.get_all_tags()

    if #all_tags == 0 then
        print('No tags found in notes')
        return
    end

    M.show_buffer_all_tags(all_tags)
end

-- Show all tags using nui.nvim
function M.show_buffer_all_tags(all_tags)
    if #all_tags == 0 then
        print('No tags found')
        return
    end

    local Menu = require('nui.menu')

    local menu_items = {}

    for _, tag in ipairs(all_tags) do
        local display_text = string.format('#%s (%d notes)', tag.name, tag.count)
        table.insert(menu_items, Menu.item(display_text, { tag = tag }))
    end

    local menu = Menu({
        position = '50%',
        size = {
            width = math.min(80, vim.o.columns - 4),
            height = math.min(20, #menu_items + 4),
        },
        border = {
            style = 'rounded',
            text = {
                top = '[🏷️  All Tags (' .. #all_tags .. ' total)]',
                top_align = 'center',
            },
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:Normal',
        },
    }, {
        lines = menu_items,
        max_width = 70,
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
            if item.tag then
                M.search_by_tags(item.tag.name)
            end
        end,
    })

    menu:mount()
end

-- Add tag to current note
function M.add_tag_to_current_note(tag)
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

    if not tag or tag == '' then
        local Input = require('nui.input')
        local event = require('nui.utils.autocmd').event

        local input = Input({
            position = '50%',
            size = { width = 40 },
            border = {
                style = 'rounded',
                text = {
                    top = '[🏷️  Add Tag]',
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
                if value and value ~= '' then
                    M.add_tag_to_current_note(value)
                end
            end,
        })

        input:mount()
        input:on(event.BufLeave, function()
            input:unmount()
        end)
        return
    end

    -- Remove # if present
    tag = tag:gsub('^#', '')

    -- Check if tag already exists
    local existing_tags = utils.extract_tags(current_file)
    if vim.tbl_contains(existing_tags, tag) then
        print('Tag already exists: ' .. tag)
        return
    end

    -- Find or create tags line
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local tags_line_num = nil

    for i, line in ipairs(lines) do
        if line:match('^[Tt]ags:%s*') then
            tags_line_num = i
            break
        end
    end

    if tags_line_num then
        -- Add to existing tags line
        local current_line = lines[tags_line_num]
        local new_line = current_line .. ' ' .. tag
        vim.api.nvim_buf_set_lines(0, tags_line_num - 1, tags_line_num, false, { new_line })
    else
        -- Look for a good place to insert tags line (after title/frontmatter)
        local insert_line = 1

        -- Skip title if present
        if lines[1] and lines[1]:match('^#') then
            insert_line = 2

            -- Skip empty line after title
            if lines[2] and lines[2] == '' then
                insert_line = 3
            end
        end

        -- Insert tags line
        vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, { 'Tags: ' .. tag, '' })
    end

    print('Added tag: ' .. tag)
end

return M
