local config = require('nvim-notes.config')
local M = {}

-- Get all notes in the vault
function M.get_all_notes()
    local vault_path = config.get_vault_path()
    local notes = {}

    -- Use vim's globpath to find all markdown files
    local files = vim.fn.globpath(vault_path, '**/*.md', false, true)

    for _, file in ipairs(files) do
        if file ~= '' then
            local note = M.get_note_info(file)
            if note then
                table.insert(notes, note)
            end
        end
    end

    -- Sort by modification time (newest first)
    table.sort(notes, function(a, b)
        return a.modified_time > b.modified_time
    end)

    return notes
end

-- Extract creation date from note content
function M.get_note_creation_date(file_path)
    if vim.fn.filereadable(file_path) == 0 then
        return nil
    end

    local lines = vim.fn.readfile(file_path, '', 10) -- Read first 10 lines

    -- Look for "Created:" line
    for _, line in ipairs(lines) do
        local created_match = line:match('^Created:%s*(.+)')
        if created_match then
            -- Try to parse the date
            local date_part = created_match:match('(%d%d%d%d%-%d%d%-%d%d)')
            if date_part then
                return date_part
            end
            -- If no date pattern found, return the whole match
            return created_match:gsub('^%s*(.-)%s*$', '%1')
        end
    end

    -- Fallback to file creation time if available
    local stat = vim.loop.fs_stat(file_path)
    if stat and stat.birthtime then
        return os.date('%Y-%m-%d', stat.birthtime.sec)
    end

    -- Final fallback to modification time
    if stat then
        return os.date('%Y-%m-%d', stat.mtime.sec)
    end

    return nil
end

-- Get information about a specific note
function M.get_note_info(file_path)
    if vim.fn.filereadable(file_path) == 0 then
        return nil
    end

    local stat = vim.loop.fs_stat(file_path)
    if not stat then
        return nil
    end

    local title = M.get_note_title(file_path)
    local relative_path = file_path:gsub(config.get_vault_path() .. '/', '')
    local created = M.get_note_creation_date(file_path)

    return {
        path = file_path,
        relative_path = relative_path,
        title = title,
        created = created,
        modified_time = stat.mtime.sec,
        modified = os.date('%Y-%m-%d %H:%M', stat.mtime.sec),
        size = stat.size
    }
end

-- Extract title from note (first heading or filename)
function M.get_note_title(file_path)
    local lines = vim.fn.readfile(file_path, '', 10) -- Read first 10 lines
    local headings = {}

    -- Collect all headings
    for _, line in ipairs(lines) do
        local heading = line:match('^#%s+(.+)')
        if heading then
            table.insert(headings, heading)
        end
    end

    -- If we have headings, prefer non-date headings
    for _, heading in ipairs(headings) do
        -- Skip headings that are just dates (YYYY-MM-DD format) or look like dates
        if not heading:match('^%d%d%d%d%-%d%d%-%d%d$') and
            not heading:match('^%d%d%d%d%-%d%d%-%d%d%s') and
            not heading:match('^%d+/%d+/%d+') then
            return heading
        end
    end

    -- Fallback to filename without extension (prefer this over date headings)
    local filename = vim.fn.fnamemodify(file_path, ':t:r')

    -- If filename is also a date pattern, try to find a better heading
    if filename:match('^%d%d%d%d%-%d%d%-%d%d$') then
        -- Look for second-level headings (##) that might be better
        for _, line in ipairs(lines) do
            local heading = line:match('^##%s+(.+)')
            if heading and not heading:match('^%d%d%d%d%-%d%d%-%d%d') then
                return heading
            end
        end

        -- If all else fails, use the first heading even if it's a date
        if #headings > 0 then
            return headings[1]
        end
    end

    return filename
end

-- Get recent notes
function M.get_recent_notes(count)
    local notes = M.get_all_notes()
    local recent = {}

    for i = 1, math.min(count or 10, #notes) do
        table.insert(recent, notes[i])
    end

    return recent
end

-- Create a note slug from title
function M.create_slug(title)
    local slug = title:lower()
    slug = slug:gsub('[^%w%s-]', '') -- Remove special characters
    slug = slug:gsub('%s+', '-')     -- Replace spaces with hyphens
    slug = slug:gsub('-+', '-')      -- Replace multiple hyphens with single
    slug = slug:gsub('^-+', '')      -- Remove leading hyphens
    slug = slug:gsub('-+$', '')      -- Remove trailing hyphens

    return slug
end

-- Check if a file is in the vault
function M.is_in_vault(file_path)
    local vault_path = config.get_vault_path()
    return file_path:find(vault_path, 1, true) == 1
end

-- Get relative path within vault
function M.get_relative_path(file_path)
    local vault_path = config.get_vault_path()
    if M.is_in_vault(file_path) then
        return file_path:gsub(vault_path .. '/', '')
    end
    return file_path
end

-- Ensure file has .md extension
function M.ensure_md_extension(filename)
    if not filename:match('%.md$') then
        return filename .. '.md'
    end
    return filename
end

-- Extract tags from note content
function M.extract_tags(file_path)
    local tags = {}

    if vim.fn.filereadable(file_path) == 0 then
        return tags
    end

    local lines = vim.fn.readfile(file_path)

    for _, line in ipairs(lines) do
        -- Find hashtags
        for tag in line:gmatch('#([%w_-]+)') do
            if not vim.tbl_contains(tags, tag) then
                table.insert(tags, tag)
            end
        end

        -- Find tags in frontmatter or dedicated tags line
        if line:match('^[Tt]ags:%s*') then
            local tag_line = line:gsub('^[Tt]ags:%s*', '')
            for tag in tag_line:gmatch('[%w_-]+') do
                if not vim.tbl_contains(tags, tag) then
                    table.insert(tags, tag)
                end
            end
        end
    end

    return tags
end

-- Search for text in file content
function M.search_file_content(file_path, query)
    if vim.fn.filereadable(file_path) == 0 then
        return {}
    end

    local matches = {}
    local lines = vim.fn.readfile(file_path)
    local query_lower = query:lower()

    for line_num, line in ipairs(lines) do
        if line:lower():find(query_lower, 1, true) then
            table.insert(matches, {
                line_number = line_num,
                line_content = line,
                context = M.get_line_context(lines, line_num, 1)
            })
        end
    end

    return matches
end

-- Get context lines around a specific line
function M.get_line_context(lines, line_num, context_size)
    local context = {}
    local start_line = math.max(1, line_num - context_size)
    local end_line = math.min(#lines, line_num + context_size)

    for i = start_line, end_line do
        table.insert(context, {
            line_number = i,
            content = lines[i],
            is_match = i == line_num
        })
    end

    return context
end

-- Format file size for display
function M.format_file_size(bytes)
    if bytes < 1024 then
        return bytes .. 'B'
    elseif bytes < 1024 * 1024 then
        return string.format('%.1fKB', bytes / 1024)
    else
        return string.format('%.1fMB', bytes / (1024 * 1024))
    end
end

-- Sanitize filename for filesystem
function M.sanitize_filename(filename)
    -- Remove or replace invalid characters
    local sanitized = filename:gsub('[<>:"/\\|?*]', '_')
    sanitized = sanitized:gsub('^%.+', '') -- Remove leading dots
    sanitized = sanitized:gsub('%.+$', '') -- Remove trailing dots
    sanitized = sanitized:sub(1, 200)      -- Limit length

    return sanitized
end

-- Open file in appropriate application (for previews)
function M.open_external(file_path)
    local cmd
    if vim.fn.has('mac') == 1 then
        cmd = 'open'
    elseif vim.fn.has('unix') == 1 then
        cmd = 'xdg-open'
    elseif vim.fn.has('win32') == 1 then
        cmd = 'start'
    else
        print('Unsupported system for external file opening')
        return
    end

    vim.fn.system(cmd .. ' ' .. vim.fn.shellescape(file_path))
end

return M
