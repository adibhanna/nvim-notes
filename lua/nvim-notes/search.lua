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

-- Show search results using FZF
function M.show_search_results(results, title)
    if #results == 0 then
        print('No results found')
        return
    end

    -- Check if fzf is available
    if vim.fn.executable('fzf') == 0 then
        print('FZF not found. Please install fzf: https://github.com/junegunn/fzf')
        return
    end

    -- Format results for FZF display
    local fzf_lines = {}
    local result_map = {}

    for i, result in ipairs(results) do
        local display_line = string.format('%s (%d matches) - %s - %s',
            result.note.title,
            result.match_count,
            result.note.modified,
            result.note.relative_path
        )
        table.insert(fzf_lines, display_line)
        result_map[display_line] = result
    end

    -- FZF options
    local fzf_opts = {
        source = fzf_lines,
        sink = function(selected)
            if selected and result_map[selected] then
                local result = result_map[selected]
                vim.cmd('edit ' .. result.note.path)
                -- If there are specific line matches, jump to the first one
                if #result.matches > 0 and result.matches[1].line_number > 0 then
                    vim.api.nvim_win_set_cursor(0, { result.matches[1].line_number, 0 })
                end
            end
        end,
        options = {
            '--prompt=' .. title .. ': ',
            '--height=60%',
            '--layout=reverse',
            '--border',
            '--info=inline',
            '--preview=bat --style=numbers --color=always --line-range=:50 {}',
            '--preview-window=right:50%:wrap',
            '--bind=ctrl-/:toggle-preview',
            '--header=' .. title .. ' - Enter to open, Ctrl-/ toggle preview',
        }
    }

    if vim.fn.exists('*fzf#run') == 1 then
        vim.fn['fzf#run'](fzf_opts)
    else
        print('FZF vim plugin not available')
    end
end

-- Interactive search using FZF
function M.interactive_search()
    local notes = utils.get_all_notes()
    if #notes == 0 then
        print('No notes found in vault')
        return
    end

    -- Check if fzf is available
    if vim.fn.executable('fzf') == 0 then
        print('FZF not found. Please install fzf: https://github.com/junegunn/fzf')
        return
    end

    -- Format notes for FZF display
    local fzf_lines = {}
    local note_map = {}

    for i, note in ipairs(notes) do
        local display_line = string.format('%s (%s) - %s',
            note.title,
            note.modified,
            note.relative_path
        )
        table.insert(fzf_lines, display_line)
        note_map[display_line] = note
    end

    -- FZF options
    local fzf_opts = {
        source = fzf_lines,
        sink = function(selected)
            if selected and note_map[selected] then
                vim.cmd('edit ' .. note_map[selected].path)
            end
        end,
        options = {
            '--prompt=🔍 Search Notes: ',
            '--height=60%',
            '--layout=reverse',
            '--border',
            '--info=inline',
            '--preview=bat --style=numbers --color=always --line-range=:50 {3}',
            '--preview-window=right:50%:wrap',
            '--bind=ctrl-/:toggle-preview',
            '--header=Ctrl-/ to toggle preview, Enter to open note',
        }
    }

    -- Use fzf#run if available, otherwise use fzf#vim#files as fallback
    if vim.fn.exists('*fzf#run') == 1 then
        vim.fn['fzf#run'](fzf_opts)
    else
        -- Fallback to simple FZF call
        local cmd = 'echo "' ..
            table.concat(fzf_lines, '\n') .. '" | fzf --prompt="🔍 Search Notes: " --height=60% --layout=reverse --border'

        vim.fn.jobstart(cmd, {
            on_stdout = function(_, data)
                if data and data[1] and data[1] ~= '' then
                    local selected = data[1]
                    if note_map[selected] then
                        vim.cmd('edit ' .. note_map[selected].path)
                    end
                end
            end,
            stdout_buffered = true,
        })
    end
end

-- Live note finder - shows all notes with live filtering
function M.live_note_finder()
    return M.interactive_search()
end

-- Search by tags using FZF
function M.search_by_tags()
    -- Check if fzf is available
    if vim.fn.executable('fzf') == 0 then
        print('FZF not found. Please install fzf: https://github.com/junegunn/fzf')
        return
    end

    local all_tags = {}
    local notes = utils.get_all_notes()
    local tag_notes_map = {}

    for _, note in ipairs(notes) do
        local tags = utils.extract_tags(note.path)
        for _, tag in ipairs(tags) do
            if not vim.tbl_contains(all_tags, tag) then
                table.insert(all_tags, tag)
                tag_notes_map[tag] = {}
            end
            table.insert(tag_notes_map[tag], note)
        end
    end

    if #all_tags == 0 then
        print('No tags found in notes')
        return
    end

    -- Format tags for FZF display
    local fzf_lines = {}
    for _, tag in ipairs(all_tags) do
        local count = #tag_notes_map[tag]
        local display_line = string.format('#%s (%d notes)', tag, count)
        table.insert(fzf_lines, display_line)
    end

    -- FZF options for tag selection
    local fzf_opts = {
        source = fzf_lines,
        sink = function(selected)
            if selected then
                local tag = selected:match('^#([^%s]+)')
                if tag and tag_notes_map[tag] then
                    M.show_notes_for_tag(tag, tag_notes_map[tag])
                end
            end
        end,
        options = {
            '--prompt=🏷️ Select Tag: ',
            '--height=40%',
            '--layout=reverse',
            '--border',
            '--info=inline',
            '--header=Select a tag to see all notes with that tag',
        }
    }

    if vim.fn.exists('*fzf#run') == 1 then
        vim.fn['fzf#run'](fzf_opts)
    else
        print('FZF vim plugin not available. Please install fzf.vim')
    end
end

-- Show notes for a specific tag using FZF
function M.show_notes_for_tag(tag, tag_notes)
    if not tag_notes or #tag_notes == 0 then
        print('No notes found for tag: ' .. tag)
        return
    end

    -- Format notes for FZF display
    local fzf_lines = {}
    local note_map = {}

    for _, note in ipairs(tag_notes) do
        local display_line = string.format('%s (%s) - %s',
            note.title,
            note.modified,
            note.relative_path
        )
        table.insert(fzf_lines, display_line)
        note_map[display_line] = note
    end

    -- FZF options
    local fzf_opts = {
        source = fzf_lines,
        sink = function(selected)
            if selected and note_map[selected] then
                vim.cmd('edit ' .. note_map[selected].path)
            end
        end,
        options = {
            '--prompt=📝 Notes with #' .. tag .. ': ',
            '--height=60%',
            '--layout=reverse',
            '--border',
            '--info=inline',
            '--preview=bat --style=numbers --color=always --line-range=:50 {}',
            '--preview-window=right:50%:wrap',
            '--bind=ctrl-/:toggle-preview',
            '--header=Notes tagged with #' .. tag .. ' (' .. #tag_notes .. ' total)',
        }
    }

    if vim.fn.exists('*fzf#run') == 1 then
        vim.fn['fzf#run'](fzf_opts)
    else
        print('FZF vim plugin not available')
    end
end

-- Search pinned notes using FZF
function M.search_pinned_notes()
    local pins = require('nvim-notes.pins')
    local pinned_notes = pins.get_pinned_notes()

    if #pinned_notes == 0 then
        print('No pinned notes found')
        return
    end

    -- Check if fzf is available
    if vim.fn.executable('fzf') == 0 then
        print('FZF not found. Please install fzf: https://github.com/junegunn/fzf')
        return
    end

    -- Format notes for FZF display
    local fzf_lines = {}
    local note_map = {}

    for _, note in ipairs(pinned_notes) do
        local display_line = string.format('📌 %s (%s) - %s',
            note.title,
            note.modified,
            note.relative_path
        )
        table.insert(fzf_lines, display_line)
        note_map[display_line] = note
    end

    -- FZF options
    local fzf_opts = {
        source = fzf_lines,
        sink = function(selected)
            if selected and note_map[selected] then
                vim.cmd('edit ' .. note_map[selected].path)
            end
        end,
        options = {
            '--prompt=📌 Pinned Notes: ',
            '--height=60%',
            '--layout=reverse',
            '--border',
            '--info=inline',
            '--preview=bat --style=numbers --color=always --line-range=:50 {}',
            '--preview-window=right:50%:wrap',
            '--bind=ctrl-/:toggle-preview',
            '--header=Pinned Notes (' .. #pinned_notes .. ' total)',
        }
    }

    if vim.fn.exists('*fzf#run') == 1 then
        vim.fn['fzf#run'](fzf_opts)
    else
        print('FZF vim plugin not available')
    end
end

return M
