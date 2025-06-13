local config = require('nvim-notes.config')
local utils = require('nvim-notes.utils')

local M = {}

-- Preview markdown file in a terminal buffer
function M.preview_markdown(file_path)
    local preview_cmd = config.get_config().preview_command

    if not preview_cmd then
        print('No preview command configured')
        return
    end

    -- Create a new terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_name(buf, 'Markdown Preview')

    -- Open in vertical split
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, buf)

    -- Run preview command
    local full_cmd = preview_cmd .. ' ' .. vim.fn.shellescape(file_path)
    vim.fn.termopen(full_cmd)

    -- Set up keybindings
    vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = buf, noremap = true, silent = true })
end

-- Preview current markdown buffer content
function M.preview_current_buffer()
    local current_file = vim.fn.expand('%:p')

    if not current_file:match('%.md$') then
        print('Current buffer is not a markdown file')
        return
    end

    -- Save current buffer if modified
    if vim.bo.modified then
        vim.cmd('write')
    end

    M.preview_markdown(current_file)
end

-- Live preview with auto-refresh
function M.live_preview()
    local current_file = vim.fn.expand('%:p')

    if not current_file:match('%.md$') then
        print('Current buffer is not a markdown file')
        return
    end

    -- Save current buffer if modified
    if vim.bo.modified then
        vim.cmd('write')
    end

    local preview_cmd = config.get_config().preview_command

    if not preview_cmd then
        print('No preview command configured')
        return
    end

    -- Create a new terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_name(buf, 'Live Preview')

    -- Open in vertical split
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    -- Function to refresh preview
    local function refresh_preview()
        -- Clear the buffer
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

        -- Run preview command
        local full_cmd = preview_cmd .. ' ' .. vim.fn.shellescape(current_file)
        vim.fn.termopen(full_cmd)
    end

    -- Initial preview
    refresh_preview()

    -- Set up auto-refresh on file change
    local group = vim.api.nvim_create_augroup('LivePreview', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        pattern = current_file,
        callback = function()
            if vim.api.nvim_buf_is_valid(buf) then
                refresh_preview()
            else
                -- Clean up autocmd if buffer is no longer valid
                vim.api.nvim_del_augroup_by_id(group)
            end
        end
    })

    -- Set up keybindings
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_del_augroup_by_id(group)
        vim.cmd('quit')
    end, { buffer = buf, noremap = true, silent = true })

    vim.keymap.set('n', 'r', refresh_preview, { buffer = buf, noremap = true, silent = true })
end

-- Export to HTML
function M.export_to_html(file_path, output_path)
    if not file_path then
        file_path = vim.fn.expand('%:p')
    end

    if not file_path:match('%.md$') then
        print('File is not a markdown file')
        return
    end

    if not output_path then
        output_path = file_path:gsub('%.md$', '.html')
    end

    -- Check if pandoc is available
    if vim.fn.executable('pandoc') == 0 then
        print('pandoc is required for HTML export')
        return
    end

    -- Export using pandoc
    local cmd = string.format('pandoc -f markdown -t html -o %s %s',
        vim.fn.shellescape(output_path),
        vim.fn.shellescape(file_path))

    local result = vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
        print('Exported to: ' .. output_path)

        -- Ask if user wants to open the HTML file
        local choice = vim.fn.input('Open HTML file? (y/N): ')
        if choice:lower() == 'y' then
            utils.open_external(output_path)
        end
    else
        print('Export failed: ' .. result)
    end
end

-- Export to PDF
function M.export_to_pdf(file_path, output_path)
    if not file_path then
        file_path = vim.fn.expand('%:p')
    end

    if not file_path:match('%.md$') then
        print('File is not a markdown file')
        return
    end

    if not output_path then
        output_path = file_path:gsub('%.md$', '.pdf')
    end

    -- Check if pandoc is available
    if vim.fn.executable('pandoc') == 0 then
        print('pandoc is required for PDF export')
        return
    end

    -- Export using pandoc
    local cmd = string.format('pandoc -f markdown -t pdf -o %s %s',
        vim.fn.shellescape(output_path),
        vim.fn.shellescape(file_path))

    local result = vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
        print('Exported to: ' .. output_path)

        -- Ask if user wants to open the PDF file
        local choice = vim.fn.input('Open PDF file? (y/N): ')
        if choice:lower() == 'y' then
            utils.open_external(output_path)
        end
    else
        print('Export failed: ' .. result)
    end
end

-- Preview in browser (requires markdown-preview-enhanced or similar)
function M.preview_in_browser()
    local current_file = vim.fn.expand('%:p')

    if not current_file:match('%.md$') then
        print('Current buffer is not a markdown file')
        return
    end

    -- Save current buffer if modified
    if vim.bo.modified then
        vim.cmd('write')
    end

    -- Try different preview methods
    local preview_methods = {
        -- Using grip (GitHub-flavored markdown preview)
        function()
            if vim.fn.executable('grip') == 1 then
                vim.fn.system('grip ' .. vim.fn.shellescape(current_file) .. ' --browser &')
                return true
            end
            return false
        end,

        -- Using markdown-preview-enhanced
        function()
            if vim.fn.executable('markdown-preview-enhanced') == 1 then
                vim.fn.system('markdown-preview-enhanced ' .. vim.fn.shellescape(current_file) .. ' &')
                return true
            end
            return false
        end,

        -- Convert to HTML and open in browser
        function()
            if vim.fn.executable('pandoc') == 1 then
                local temp_html = vim.fn.tempname() .. '.html'
                local cmd = string.format('pandoc -f markdown -t html -o %s %s',
                    vim.fn.shellescape(temp_html),
                    vim.fn.shellescape(current_file))

                if vim.fn.system(cmd) and vim.v.shell_error == 0 then
                    utils.open_external(temp_html)
                    return true
                end
            end
            return false
        end
    }

    for _, method in ipairs(preview_methods) do
        if method() then
            print('Opening preview in browser...')
            return
        end
    end

    print('No suitable browser preview method found')
    print('Install grip, markdown-preview-enhanced, or pandoc for browser preview')
end

-- Quick preview in a floating window
function M.quick_preview()
    local current_file = vim.fn.expand('%:p')

    if not current_file:match('%.md$') then
        print('Current buffer is not a markdown file')
        return
    end

    -- Save current buffer if modified
    if vim.bo.modified then
        vim.cmd('write')
    end

    local preview_cmd = config.get_config().preview_command

    if not preview_cmd then
        print('No preview command configured')
        return
    end

    -- Get preview content
    local full_cmd = preview_cmd .. ' ' .. vim.fn.shellescape(current_file)
    local content = vim.fn.system(full_cmd)

    if vim.v.shell_error ~= 0 then
        print('Preview command failed')
        return
    end

    -- Create floating window
    local lines = vim.split(content, '\n')
    local width = math.min(120, vim.o.columns - 4)
    local height = math.min(40, vim.o.lines - 4)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
        title = ' Preview: ' .. vim.fn.fnamemodify(current_file, ':t') .. ' ',
        title_pos = 'center'
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set up keybindings
    vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = buf, noremap = true, silent = true })
    vim.keymap.set('n', '<Esc>', '<cmd>quit<cr>', { buffer = buf, noremap = true, silent = true })
end

return M
