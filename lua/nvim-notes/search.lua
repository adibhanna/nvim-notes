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

-- Show search results using vim.ui.select
function M.show_search_results(results, title)
    if #results == 0 then
        print('No results found')
        return
    end

    -- Format results for display
    local options = {}
    local result_map = {}

    for i, result in ipairs(results) do
        local display_line = string.format('%d. %s (%d matches) - %s',
            i,
            result.note.title,
            result.match_count,
            result.note.created or result.note.modified:match('%d%d%d%d%-%d%d%-%d%d') or 'Unknown'
        )
        table.insert(options, display_line)
        result_map[display_line] = result
    end

    vim.ui.select(options, {
        prompt = title .. ': ',
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice and result_map[choice] then
            local result = result_map[choice]
            vim.cmd('edit ' .. result.note.path)
            -- If there are specific line matches, jump to the first one
            if #result.matches > 0 and result.matches[1].line_number > 0 then
                vim.api.nvim_win_set_cursor(0, { result.matches[1].line_number, 0 })
            end
        end
    end)
end

-- Interactive search using vim.ui.select
function M.interactive_search()
    local notes = utils.get_all_notes()
    if #notes == 0 then
        print('No notes found in vault')
        return
    end

    -- Get pinned notes and separate them
    local pins = require('nvim-notes.pins')
    local pinned_notes = pins.get_pinned_notes()
    local pinned_paths = {}

    for _, pinned in ipairs(pinned_notes) do
        pinned_paths[pinned.path] = true
    end

    -- Separate pinned and unpinned notes
    local pinned_list = {}
    local unpinned_list = {}

    for _, note in ipairs(notes) do
        if pinned_paths[note.path] then
            table.insert(pinned_list, note)
        else
            table.insert(unpinned_list, note)
        end
    end

    -- Format notes for display (pinned first)
    local options = {}
    local note_map = {}
    local counter = 1

    -- Add pinned notes first with pin indicator
    for _, note in ipairs(pinned_list) do
        local tags = utils.extract_tags(note.path)
        local tag_indicator = #tags > 0 and '🏷️ ' or ''
        local display_line = string.format('📌 %s%s - %s',
            tag_indicator,
            note.title,
            note.created or note.modified:match('%d%d%d%d%-%d%d%-%d%d') or 'Unknown'
        )
        table.insert(options, display_line)
        note_map[display_line] = note
        counter = counter + 1
    end

    -- Add unpinned notes
    for _, note in ipairs(unpinned_list) do
        local tags = utils.extract_tags(note.path)
        local tag_indicator = #tags > 0 and '🏷️ ' or ''
        local display_line = string.format('%s%s - %s',
            tag_indicator,
            note.title,
            note.created or note.modified:match('%d%d%d%d%-%d%d%-%d%d') or 'Unknown'
        )
        table.insert(options, display_line)
        note_map[display_line] = note
        counter = counter + 1
    end

    local prompt = '🔍 Search Notes: '
    if #pinned_list > 0 then
        prompt = string.format('🔍 Search Notes (%d pinned): ', #pinned_list)
    end

    vim.ui.select(options, {
        prompt = prompt,
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice and note_map[choice] then
            vim.cmd('edit ' .. note_map[choice].path)
        end
    end)
end

-- Live note finder - shows all notes with live filtering
function M.live_note_finder()
    return M.interactive_search()
end

-- Search by tags using vim.ui.select
function M.search_by_tags()
    local all_tags = {}
    local notes = utils.get_all_notes()
    local tag_notes_map = {}

    print('Debug: Found ' .. #notes .. ' notes to scan for tags')

    for _, note in ipairs(notes) do
        local tags = utils.extract_tags(note.path)
        print('Debug: Note "' .. note.title .. '" has tags: ' .. table.concat(tags, ', '))
        for _, tag in ipairs(tags) do
            if not vim.tbl_contains(all_tags, tag) then
                table.insert(all_tags, tag)
                tag_notes_map[tag] = {}
            end
            table.insert(tag_notes_map[tag], note)
        end
    end

    print('Debug: Found ' .. #all_tags .. ' unique tags: ' .. table.concat(all_tags, ', '))

    if #all_tags == 0 then
        print('No tags found in notes')
        return
    end

    -- Format tags for display
    local tag_options = {}
    local tag_map = {}
    for _, tag in ipairs(all_tags) do
        local count = #tag_notes_map[tag]
        local display_line = string.format('#%s (%d notes)', tag, count)
        table.insert(tag_options, display_line)
        tag_map[display_line] = { tag = tag, notes = tag_notes_map[tag] }
    end

    -- Use vim.ui.select for tag selection
    vim.ui.select(tag_options, {
        prompt = '🏷️ Select Tag: ',
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice and tag_map[choice] then
            M.show_notes_for_tag(tag_map[choice].tag, tag_map[choice].notes)
        end
    end)
end

-- Show notes for a specific tag using vim.ui.select
function M.show_notes_for_tag(tag, tag_notes)
    if not tag_notes or #tag_notes == 0 then
        print('No notes found for tag: ' .. tag)
        return
    end

    -- Format notes for display
    local note_options = {}
    local note_map = {}

    for _, note in ipairs(tag_notes) do
        local display_line = string.format('%s (%s) - %s',
            note.title,
            note.modified,
            note.relative_path
        )
        table.insert(note_options, display_line)
        note_map[display_line] = note
    end

    -- Use vim.ui.select for note selection
    vim.ui.select(note_options, {
        prompt = string.format('📝 Notes with #%s (%d total): ', tag, #tag_notes),
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice and note_map[choice] then
            vim.cmd('edit ' .. note_map[choice].path)
        end
    end)
end

return M
