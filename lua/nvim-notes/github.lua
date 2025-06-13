local config = require('nvim-notes.config')
local M = {}

-- Check if GitHub CLI is available
local function check_gh_cli()
    if vim.fn.executable('gh') == 0 then
        print('GitHub CLI (gh) not found. Install it from: https://cli.github.com/')
        return false
    end

    -- Check if user is authenticated
    local auth_check = vim.fn.system('gh auth status 2>&1')
    if vim.v.shell_error ~= 0 then
        print('GitHub CLI not authenticated. Run: gh auth login')
        return false
    end

    return true
end

-- Check if directory is a git repository
local function is_git_repo(path)
    local git_dir = path .. '/.git'
    return vim.fn.isdirectory(git_dir) == 1
end

-- Initialize git repository
local function init_git_repo(vault_path)
    print('Initializing git repository...')

    local commands = {
        'cd ' .. vim.fn.shellescape(vault_path),
        'git init',
        'git add .',
        'git commit -m "Initial commit: Add notes to repository"'
    }

    for _, cmd in ipairs(commands) do
        local result = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
            print('Error running: ' .. cmd)
            print('Output: ' .. result)
            return false
        end
    end

    return true
end

-- Create .gitignore for notes repository
local function create_gitignore(vault_path)
    local gitignore_path = vault_path .. '/.gitignore'

    if vim.fn.filereadable(gitignore_path) == 1 then
        return true -- Already exists
    end

    local gitignore_content = {
        '# Vim/Neovim temporary files',
        '*.swp',
        '*.swo',
        '*~',
        '.DS_Store',
        '',
        '# Local configuration',
        '.nvim-notes-local',
        '',
        '# Temporary files',
        '*.tmp',
        '*.temp',
    }

    vim.fn.writefile(gitignore_content, gitignore_path)
    print('Created .gitignore file')
    return true
end

-- Create GitHub repository
function M.create_github_repo()
    if not check_gh_cli() then
        return false
    end

    local vault_path = config.get_vault_path()

    if not vim.fn.isdirectory(vault_path) then
        print('Notes vault directory not found: ' .. vault_path)
        return false
    end

    -- Get repository name
    local default_name = vim.fn.fnamemodify(vault_path, ':t')
    if default_name == '' or default_name == '.' then
        default_name = 'my-notes'
    end

    local repo_name = vim.fn.input('Repository name [' .. default_name .. ']: ')
    if repo_name == '' then
        repo_name = default_name
    end

    -- Get repository description
    local description = vim.fn.input('Repository description [Private notes repository]: ')
    if description == '' then
        description = 'Private notes repository'
    end

    print('\nCreating GitHub repository: ' .. repo_name)

    -- Change to vault directory
    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    local success = false

    -- Create .gitignore if it doesn't exist
    create_gitignore(vault_path)

    -- Initialize git repo if not already done
    if not is_git_repo(vault_path) then
        if not init_git_repo(vault_path) then
            vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
            return false
        end
    end

    -- Create GitHub repository
    local create_cmd = string.format(
        'gh repo create %s --private --description %s --source=. --remote=origin --push',
        vim.fn.shellescape(repo_name),
        vim.fn.shellescape(description)
    )

    print('Running: ' .. create_cmd)
    local result = vim.fn.system(create_cmd)

    if vim.v.shell_error == 0 then
        print('✅ Successfully created and pushed to GitHub repository!')
        print('Repository URL: https://github.com/' ..
            vim.fn.system('gh api user --jq .login'):gsub('\n', '') .. '/' .. repo_name)
        success = true
    else
        print('❌ Failed to create GitHub repository')
        print('Error: ' .. result)
    end

    -- Return to original directory
    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

    return success
end

-- Push changes to GitHub
function M.push_to_github()
    if not check_gh_cli() then
        return false
    end

    local vault_path = config.get_vault_path()

    if not is_git_repo(vault_path) then
        print('Notes directory is not a git repository. Run :NotesGitHubCreate first.')
        return false
    end

    print('Syncing notes to GitHub...')

    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    local commands = {
        'git add .',
        'git commit -m "Update notes: ' .. os.date('%Y-%m-%d %H:%M:%S') .. '"',
        'git push origin main || git push origin master'
    }

    local success = true

    for _, cmd in ipairs(commands) do
        local result = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
            if cmd:match('git commit') and result:match('nothing to commit') then
                print('No changes to commit')
            else
                print('Error running: ' .. cmd)
                print('Output: ' .. result)
                success = false
                break
            end
        end
    end

    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

    if success then
        print('✅ Notes successfully synced to GitHub!')
    else
        print('❌ Failed to sync notes to GitHub')
    end

    return success
end

-- Pull changes from GitHub
function M.pull_from_github()
    if not check_gh_cli() then
        return false
    end

    local vault_path = config.get_vault_path()

    if not is_git_repo(vault_path) then
        print('Notes directory is not a git repository. Run :NotesGitHubCreate first.')
        return false
    end

    print('Pulling latest notes from GitHub...')

    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    local result = vim.fn.system('git pull origin main || git pull origin master')

    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

    if vim.v.shell_error == 0 then
        print('✅ Notes successfully updated from GitHub!')

        -- Reload any open buffers from the notes vault to show updated content
        local vault_path_pattern = vim.fn.fnameescape(vault_path)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:find(vault_path, 1, true) and vim.fn.filereadable(buf_name) == 1 then
                    -- Check if buffer has been modified
                    if not vim.api.nvim_buf_get_option(buf, 'modified') then
                        vim.api.nvim_buf_call(buf, function()
                            vim.cmd('checktime')
                            vim.cmd('edit!')
                        end)
                    end
                end
            end
        end
        print('🔄 Refreshed open note buffers')

        return true
    else
        print('❌ Failed to pull notes from GitHub')
        print('Error: ' .. result)
        return false
    end
end

-- Show git status
function M.show_git_status()
    local vault_path = config.get_vault_path()

    if not is_git_repo(vault_path) then
        print('Notes directory is not a git repository. Run :NotesGitHubCreate first.')
        return
    end

    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    local status = vim.fn.system('git status --porcelain')
    local branch = vim.fn.system('git branch --show-current'):gsub('\n', '')
    local remote_url = vim.fn.system('git remote get-url origin 2>/dev/null'):gsub('\n', '')

    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

    print('📊 Git Status for Notes Repository')
    print('Branch: ' .. branch)
    if remote_url ~= '' then
        print('Remote: ' .. remote_url)
    end
    print('')

    if status == '' then
        print('✅ Working directory clean - no changes to commit')
    else
        print('📝 Changes detected:')
        local lines = vim.split(status, '\n')
        for _, line in ipairs(lines) do
            if line ~= '' then
                local status_code = line:sub(1, 2)
                local file = line:sub(4)
                local status_desc = ''

                if status_code:match('M') then
                    status_desc = '📝 Modified'
                elseif status_code:match('A') then
                    status_desc = '➕ Added'
                elseif status_code:match('D') then
                    status_desc = '🗑️  Deleted'
                elseif status_code:match('%?') then
                    status_desc = '❓ Untracked'
                else
                    status_desc = '🔄 Changed'
                end

                print('  ' .. status_desc .. ': ' .. file)
            end
        end
    end
end

-- Clone existing notes repository
function M.clone_notes_repo()
    if not check_gh_cli() then
        return false
    end

    local repo_url = vim.fn.input('GitHub repository URL or owner/repo: ')
    if repo_url == '' then
        print('Repository URL required')
        return false
    end

    -- If it's just owner/repo format, convert to full URL
    if not repo_url:match('https://') and not repo_url:match('git@') then
        repo_url = 'https://github.com/' .. repo_url .. '.git'
    end

    local vault_path = config.get_vault_path()
    local parent_dir = vim.fn.fnamemodify(vault_path, ':h')
    local repo_name = vim.fn.fnamemodify(repo_url:gsub('%.git$', ''), ':t')
    local clone_path = parent_dir .. '/' .. repo_name

    print('Cloning repository to: ' .. clone_path)

    local result = vim.fn.system('git clone ' .. vim.fn.shellescape(repo_url) .. ' ' .. vim.fn.shellescape(clone_path))

    if vim.v.shell_error == 0 then
        print('✅ Repository cloned successfully!')

        local choice = vim.fn.input('Set as notes vault? (y/N): ')
        if choice:lower() == 'y' or choice:lower() == 'yes' then
            config.set_vault_path(clone_path)
            print('Notes vault updated to: ' .. clone_path)
        end

        return true
    else
        print('❌ Failed to clone repository')
        print('Error: ' .. result)
        return false
    end
end

-- Test git connectivity using GitHub CLI
local function test_git_connectivity(vault_path)
    print('🔍 Testing GitHub connectivity...')

    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    -- Test with a quick fetch
    local test_result = vim.fn.system('git ls-remote origin HEAD 2>&1')
    local success = vim.v.shell_error == 0

    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

    if not success then
        if test_result:match('Authentication failed') or test_result:match('Permission denied') then
            print('❌ Authentication failed - run: gh auth setup-git')
        elseif test_result:match('Could not resolve hostname') or test_result:match('Network is unreachable') then
            print('❌ Network connectivity issue')
        else
            print('❌ GitHub connectivity test failed: ' .. test_result)
        end
        return false
    end

    print('✅ GitHub connectivity OK')
    return true
end

-- Setup git authentication using GitHub CLI
local function setup_git_auth()
    print('🔧 Setting up git authentication with GitHub CLI...')
    local result = vim.fn.system('gh auth setup-git 2>&1')
    if vim.v.shell_error == 0 then
        print('✅ Git authentication configured successfully')
        return true
    else
        print('❌ Failed to setup git authentication: ' .. result)
        return false
    end
end

-- Super minimal sync function - handles everything automatically
function M.sync()
    if not check_gh_cli() then
        return false
    end

    local vault_path = config.get_vault_path()

    if not vim.fn.isdirectory(vault_path) then
        print('Notes vault directory not found: ' .. vault_path)
        return false
    end

    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(vault_path))

    local success = false

    if not is_git_repo(vault_path) then
        -- First time setup - create repo
        print('🚀 First time setup - creating GitHub repository...')

        local default_name = vim.fn.fnamemodify(vault_path, ':t')
        if default_name == '' or default_name == '.' then
            default_name = 'my-notes'
        end

        local repo_name = vim.fn.input('Repository name [' .. default_name .. ']: ')
        if repo_name == '' then
            repo_name = default_name
        end

        -- Create .gitignore
        create_gitignore(vault_path)

        -- Initialize git and create GitHub repo
        local commands = {
            'git init',
            'git add .',
            'git commit -m "Initial commit: Add notes to repository"',
            string.format('gh repo create %s --private --source=. --remote=origin --push', vim.fn.shellescape(repo_name))
        }

        for _, cmd in ipairs(commands) do
            local result = vim.fn.system(cmd)
            if vim.v.shell_error ~= 0 then
                print('❌ Error: ' .. cmd)
                print(result)
                vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
                return false
            end
        end

        print('✅ Repository created and notes synced!')
        success = true
    else
        -- Existing repo - sync changes with proper pull-before-push
        print('🔄 Syncing notes...')

        -- Test connectivity first
        if not test_git_connectivity(vault_path) then
            print('⚠️  Connectivity issues detected, trying to fix authentication...')
            if setup_git_auth() then
                print('🔄 Retrying connectivity test...')
                if not test_git_connectivity(vault_path) then
                    print('⚠️  Still having connectivity issues, working with local changes only...')
                end
            else
                print('⚠️  Could not fix authentication, working with local changes only...')
            end
        else
            -- First, pull any remote changes using git
            print('📥 Checking for remote updates...')

            -- Use regular git pull now that authentication is set up
            local pull_result = vim.fn.system('git pull origin main 2>&1 || git pull origin master 2>&1')

            if vim.v.shell_error ~= 0 then
                if pull_result:match('no tracking information') or pull_result:match("couldn't find remote ref") then
                    print('ℹ️  No remote tracking branch found, will push to create it')
                elseif pull_result:match('CONFLICT') or pull_result:match('Automatic merge failed') then
                    print('⚠️  Merge conflicts detected!')
                    print('Please resolve conflicts manually and run sync again.')
                    print('Conflicts in:')
                    local conflict_files = vim.fn.system('git diff --name-only --diff-filter=U')
                    print(conflict_files)
                    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
                    return false
                elseif pull_result:match('Authentication failed') or pull_result:match('Permission denied') then
                    print('❌ Authentication failed. Run: gh auth setup-git')
                    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
                    return false
                else
                    print('⚠️  Pull had issues: ' .. pull_result)
                    print('Continuing with local changes...')
                end
            else
                if pull_result:match('Already up to date') or pull_result:match('up to date') then
                    print('✅ Remote is up to date')
                else
                    print('✅ Pulled remote changes')
                    print('Changes: ' .. pull_result:gsub('\n', ' '))

                    -- Reload any open buffers from the notes vault to show updated content
                    local vault_path_pattern = vim.fn.fnameescape(vault_path)
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) then
                            local buf_name = vim.api.nvim_buf_get_name(buf)
                            if buf_name:find(vault_path, 1, true) and vim.fn.filereadable(buf_name) == 1 then
                                -- Check if buffer has been modified
                                if not vim.api.nvim_buf_get_option(buf, 'modified') then
                                    vim.api.nvim_buf_call(buf, function()
                                        vim.cmd('checktime')
                                        vim.cmd('edit!')
                                    end)
                                end
                            end
                        end
                    end
                    print('🔄 Refreshed open note buffers')
                end
            end
        end

        -- After pulling, check if we have any local changes to commit
        local status_check = vim.fn.system('git status --porcelain')
        local has_local_changes = status_check ~= ''

        -- Handle local changes
        if has_local_changes then
            print('📤 Committing local changes...')
            vim.fn.system('git add .')
            local commit_result = vim.fn.system('git commit -m "Update notes: ' .. os.date('%Y-%m-%d %H:%M:%S') .. '"')

            if vim.v.shell_error == 0 then
                print('✅ Local changes committed')

                -- Push changes with timeout (only if connectivity test passed)
                if test_git_connectivity(vault_path) then
                    print('📤 Pushing to GitHub...')
                    local push_result = vim.fn.system('git push origin main 2>&1 || git push origin master 2>&1')
                    if vim.v.shell_error == 0 then
                        print('✅ Notes synced successfully!')
                        success = true
                    else
                        print('❌ Failed to push changes')
                        print('Error: ' .. push_result)
                    end
                else
                    print('⚠️  Skipping push due to connectivity issues')
                    print('Local changes committed but not pushed to GitHub')
                    success = true
                end
            else
                print('❌ Failed to commit changes')
                print('Error: ' .. commit_result)
            end
        else
            print('✅ No local changes to sync')
            success = true
        end
    end

    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
    return success
end

return M
