local M = {}

-- Default configuration
local default_config = {
    vault_path = vim.fn.expand('~/notes'),
    auto_save = true,
    template = '# {{title}}\n\nCreated: {{date}} {{time}}\nTags: \n\n---\n\n',
    date_format = '%Y-%m-%d',
    time_format = '%H:%M',
    preview_command = nil, -- Will be auto-detected
    enable_concealing = true,
    conceal_level = 2,
    disable_default_keybindings = false,
    max_recent_notes = 10
}

local config = {}

-- Setup configuration
function M.setup(user_config)
    config = vim.tbl_deep_extend('force', default_config, user_config or {})

    -- Expand vault path
    config.vault_path = vim.fn.expand(config.vault_path)

    -- Auto-detect preview command if not set
    if not config.preview_command then
        M.detect_preview_command()
    end
end

-- Get current configuration
function M.get_config()
    return config
end

-- Get vault path
function M.get_vault_path()
    return config.vault_path or default_config.vault_path
end

-- Set vault path
function M.set_vault_path(path)
    config.vault_path = vim.fn.expand(path)
    M.save_config()
end

-- Auto-detect markdown preview command
function M.detect_preview_command()
    -- Check for common markdown preview tools
    local commands = {
        'glow',
        'mdcat',
        'bat',
        'cat'
    }

    for _, cmd in ipairs(commands) do
        if vim.fn.executable(cmd) == 1 then
            if cmd == 'glow' then
                config.preview_command = 'glow -p'
            elseif cmd == 'mdcat' then
                config.preview_command = 'mdcat'
            elseif cmd == 'bat' then
                config.preview_command = 'bat --language=markdown'
            else
                config.preview_command = 'cat'
            end
            break
        end
    end

    -- Fallback to cat if nothing else is found
    if not config.preview_command then
        config.preview_command = 'cat'
    end
end

-- Save configuration to file
function M.save_config()
    local config_dir = vim.fn.stdpath('data') .. '/nvim-notes'
    local config_file = config_dir .. '/config.json'

    -- Create directory if it doesn't exist
    if not vim.fn.isdirectory(config_dir) then
        vim.fn.mkdir(config_dir, 'p')
    end

    -- Save configuration
    local config_data = {
        vault_path = config.vault_path
    }

    local encoded = vim.fn.json_encode(config_data)
    vim.fn.writefile({ encoded }, config_file)
end

-- Load configuration from file
function M.load_config()
    local config_dir = vim.fn.stdpath('data') .. '/nvim-notes'
    local config_file = config_dir .. '/config.json'

    if vim.fn.filereadable(config_file) == 1 then
        local lines = vim.fn.readfile(config_file)
        if #lines > 0 then
            local ok, data = pcall(vim.fn.json_decode, lines[1])
            if ok and data then
                if data.vault_path then
                    config.vault_path = data.vault_path
                end
            end
        end
    end
end

-- Initialize configuration loading
M.load_config()

return M
