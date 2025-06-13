# nvim-notes

A comprehensive note-taking plugin for Neovim with full markdown support, beautiful UI components, tagging, pinning, search functionality, GitHub sync, and enhanced syntax highlighting.

## ✨ Features

- **📝 Quick Note Creation**: Create notes with custom names or automatic date-based naming
- **🔍 Powerful Search**: Search notes by content, filename, or tags using vim.ui.select
- **🏷️ Tag Management**: Create, manage, and search by tags with hashtag and YAML-style support
- **📌 Pin Notes**: Pin important notes for quick access (pinned notes appear first in search)
- **👀 Markdown Preview**: Multiple preview options including terminal and browser preview
- **🎨 Enhanced Syntax**: Custom syntax highlighting for tags, dates, tasks, priorities, and more
- **🗂️ Vault Management**: Organized note storage with customizable vault location
- **✨ Beautiful UI**: Elegant dashboard and menus powered by nui.nvim
- **📊 Interactive Dashboard**: Beautiful popup overview with sync status and quick actions
- **🔄 GitHub Sync**: One-command sync with automatic repository creation and backup
- **🚀 Zero Dependencies**: Works with built-in vim.ui.select (no external fuzzy finder required)

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'adibhanna/nvim-notes',
  dependencies = {
    'MunifTanjim/nui.nvim', -- Required for beautiful UI components
  },
  config = function()
    require('nvim-notes').setup({
      -- Your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'adibhanna/nvim-notes',
  requires = {
    'MunifTanjim/nui.nvim', -- Required for beautiful UI components
  },
  config = function()
    require('nvim-notes').setup()
  end
}
```

## 📋 Prerequisites

The plugin works out of the box with Neovim's built-in `vim.ui.select`. For enhanced experience, you can optionally install:

```bash
# Optional: For better markdown preview
brew install glow

# Optional: Alternative preview tools
brew install bat
cargo install mdcat

# Required for GitHub sync
brew install gh
gh auth login
```

## ⚙️ Configuration

### Default Configuration

```lua
require('nvim-notes').setup({
  vault_path = '~/notes',                    -- Where to store notes
  auto_save = true,                          -- Auto-save notes on changes
  template = '# {{title}}\n\nCreated: {{date}} {{time}}\nTags: \n\n---\n\n',
  date_format = '%Y-%m-%d',                  -- Date format for new notes
  time_format = '%H:%M',                     -- Time format for templates
  preview_command = nil,                     -- Auto-detected (glow, mdcat, bat, cat)
  enable_concealing = true,                  -- Enable markdown concealing
  conceal_level = 2,                         -- Conceal level for markdown
  disable_default_keybindings = false,       -- Disable default key mappings
  max_recent_notes = 10,                     -- Number of recent notes to show
})
```

### Custom Template

You can customize the template for new notes using template variables:

```lua
require('nvim-notes').setup({
  template = [[
# {{title}}

**Created:** {{date}} at {{time}}
**Tags:** 

> [!NOTE]
> This is a new note created with nvim-notes

---

## Content

]],
})
```

Available template variables:
- `{{title}}` - Note title (filename without extension)
- `{{date}}` - Current date
- `{{time}}` - Current time

## 🚀 Usage

### Commands

| Command                   | Description                                       |
| ------------------------- | ------------------------------------------------- |
| `:NotesNew [name]`        | Create a new note (prompts for name or uses date) |
| `:NotesSearch [query]`    | Search notes by content (pinned shown first)      |
| `:NotesSearchTags [tags]` | Search notes by tags                              |
| `:NotesPinToggle`         | Toggle pin status of current note                 |
| `:NotesDelete`            | Delete current note (with confirmation)           |
| `:NotesPreview`           | Preview current note in markdown                  |
| `:NotesIndex`             | Show notes dashboard popup                        |
| `:NotesSetVault [path]`   | Set the notes vault directory                     |
| `:NotesSync`              | Sync notes with GitHub (creates repo first time)  |

### Keybindings

The plugin automatically sets up keybindings if `which-key.nvim` is installed:

| Keymap           | Action                            |
| ---------------- | --------------------------------- |
| `<leader><tab>n` | Create new note                   |
| `<leader><tab>s` | Search notes (pinned shown first) |
| `<leader><tab>t` | Search by tags                    |
| `<leader><tab>p` | Toggle pin current note           |
| `<leader><tab>d` | Delete current note               |
| `<leader><tab>v` | Preview current note              |
| `<leader><tab>i` | Show notes dashboard popup        |
| `<leader><tab>S` | Sync notes with GitHub            |

If `which-key.nvim` is not installed, no default keybindings are set. You can use the commands directly or set up your own keybindings.

### 📚 Dashboard Features

The Notes Dashboard (`<leader><tab>i` or `:NotesIndex`) provides a beautiful popup overview:

- **📊 Quick Stats**: Total notes, pinned count, tags overview
- **📌 Pinned Notes**: Your most important notes at a glance
- **🕐 Recent Activity**: Latest modified notes
- **🏷️ Popular Tags**: Most used tags with counts
- **🔄 Sync Status**: Last synced time, local changes, remote updates
- **📱 Interactive**: ESC or 'q' to close, '?' for help
- **🎯 Auto-focus**: Cursor automatically positioned in the popup

### Custom Keybindings

```lua
-- Disable automatic keybindings and set your own
require('nvim-notes').setup({
  disable_keybindings = true,
})

-- Set custom keybindings
local notes = require('nvim-notes')
vim.keymap.set('n', '<leader>nn', notes.new_note, { desc = 'Create new note' })
vim.keymap.set('n', '<leader>ns', notes.search_notes, { desc = 'Search notes' })
-- ... etc
```

## 📝 Note Taking Workflow

### 1. Quick Note Creation

```lua
-- Create a note (prompts for name, defaults to current date-time)
:NotesNew

-- Create a note with specific name
:NotesNew "Meeting Notes"
```

When creating a new note, you'll be prompted to enter a name. Press Enter to use the current date-time as the filename, or type a custom name.

### 2. Organizing with Tags

nvim-notes supports multiple tagging formats for flexible organization:

#### Tag Formats

**1. Hashtag Style (anywhere in content):**
```markdown
# Meeting Notes

Today we discussed #project-alpha and #budget-planning.
The #urgent items need attention by #deadline-friday.
```

**2. Tags Line (YAML-style):**
```markdown
# Project Update

Tags: work project urgent meeting
Tags: project-alpha, budget, Q1-planning

Content goes here...
```

**3. Mixed Usage:**
```markdown
# Daily Standup

Tags: work meeting daily

- Discussed #project-alpha progress
- #blocker: waiting for API documentation  
- Next: focus on #frontend-tasks
```

#### Searching by Tags

```bash
# Search for specific tags
:NotesSearchTags project
:NotesSearchTags "work urgent"

# Use the keybinding
<leader><tab>t

# From dashboard - press 't'
<leader><tab>i
```

#### Tag Best Practices

- **Use consistent naming**: `project-alpha` vs `projectalpha` vs `project_alpha`
- **Create tag hierarchies**: `work/meetings`, `personal/ideas`, `learning/vim`
- **Keep tags short**: `urgent` vs `urgent-high-priority`
- **Use descriptive tags**: `budget-2024` vs `budget`

#### Tag Management

Tags are automatically extracted and indexed. View popular tags in the dashboard (`<leader><tab>i`) to see:
- Most used tags with counts
- Tag-based note organization
- Quick tag-based search access

### 3. Pinning Important Notes

Pin frequently accessed notes for quick access:

```lua
-- Pin current note
:NotesPinToggle

-- Pinned notes appear first in search results
:NotesSearch
```

Pinned notes are stored in a simple text file in your vault directory and appear first in all search results with a 📌 indicator.

### 4. Searching and Discovery

```lua
-- Search by content (pinned notes shown first)
:NotesSearch "important meeting"

-- Search by tags
:NotesSearchTags "project work"

-- Browse all notes  
:NotesSearch
```

Search results show pinned notes first, followed by regular notes. Each result displays:
- Pin indicator (📌) for pinned notes
- Tag indicator (🏷️) for notes with tags
- Note name and creation date

### 5. Note Management

```lua
-- Delete current note (with confirmation)
:NotesDelete
<leader><tab>d

-- Pin/unpin current note
:NotesPinToggle
<leader><tab>p
```

### 6. Dashboard Overview

Get a quick overview of your notes:

```lua
-- Open beautiful dashboard popup
:NotesIndex

-- Or use the keybinding
<leader><tab>i
```

The dashboard shows:
- Vault statistics (total notes, pinned count, tag count)
- Pinned notes list
- Recent activity
- Popular tags with counts
- Sync status information
- Interactive help (press '?' for shortcuts)

## 🔄 GitHub Sync & Backup

Keep your notes safe and synced across devices with one simple command.

### Prerequisites

Install and authenticate with GitHub CLI:

```bash
# Install GitHub CLI
brew install gh
# or on Linux
sudo apt install gh

# Authenticate with GitHub
gh auth login

# Configure git authentication (fixes hanging issues)
gh auth setup-git
```

### Usage

**One command does everything:**

```bash
:NotesSync
# or
<leader><tab>S
```

**First time:** Creates a private GitHub repository and pushes all your notes  
**Every other time:** Syncs changes bidirectionally (pull then push)

### Features

- **🚀 Zero configuration**: Just run `:NotesSync`
- **🔒 Private repositories**: Your notes stay private by default
- **🔄 Bidirectional sync**: Pulls remote changes first, then pushes local changes
- **📝 Smart commits**: Automatic timestamped commits with change summaries
- **📱 Multi-device**: Use the same command on all devices
- **💾 Backup**: Never lose your notes
- **🔧 Error handling**: Graceful handling of conflicts and connectivity issues
- **📊 Status tracking**: Dashboard shows sync status and last sync time

### Multi-Device Workflow

**On your first device:**
```bash
:NotesSync  # Creates repo and pushes notes
```

**On additional devices:**
```bash
# Clone the repository first (one time)
gh repo clone your-username/your-notes-repo ~/notes
:NotesSetVault ~/notes

# Then just sync normally
:NotesSync  # Pulls latest, pushes any changes
```

**Daily usage on any device:**
```bash
:NotesSync  # That's it!
```

The command automatically:
1. Tests connectivity to GitHub
2. Pulls any remote changes first
3. Commits your local changes with timestamps
4. Pushes everything to GitHub
5. Reloads any changed buffers
6. Updates sync status in dashboard

## 🎨 Enhanced Syntax Highlighting

The plugin provides a custom `notes` filetype with enhanced syntax highlighting:

### Features

- **Tags**: Highlighted `#hashtag` syntax and `Tags:` lines
- **Dates/Times**: Special highlighting for timestamps (`2024-01-15`, `14:30`)
- **Task Lists**: Enhanced checkbox highlighting (`- [ ]`, `- [x]`)
- **Priorities**: Priority markers (`!!`, `!!!`) with different colors
- **Pin Indicators**: Special highlighting for 📌 pin markers
- **Sections**: Enhanced header highlighting (`##`, `###`)
- **Created/Modified Lines**: Special highlighting for metadata lines
- **Markdown Base**: Built on top of standard markdown syntax

### Syntax Examples

```markdown
# Project Meeting Notes

Created: 2024-01-15 14:30
Tags: work project urgent

## Action Items

- [ ] Review budget proposal !!!
- [x] Send meeting notes !!
- [ ] Schedule follow-up #next-week

## Discussion Points

We covered #project-alpha and #budget-planning.
The #urgent items need attention by #deadline-friday.

📌 This note is pinned for quick access.
```

## 👀 Markdown Preview

### Prerequisites

For best preview experience, install one of these tools:

```bash
# Recommended: glow (GitHub-flavored markdown renderer)
brew install glow
# or
go install github.com/charmbracelet/glow@latest

# Alternative: mdcat
cargo install mdcat

# Alternative: bat with syntax highlighting
brew install bat
```

### Preview Options

- **Terminal Preview**: `:NotesPreview` (uses glow/mdcat/bat/cat)
- **Auto-detection**: Plugin automatically detects available preview tools
- **Fallback**: Uses `cat` if no other tools are available

The preview command is automatically detected in this order:
1. `glow -p` (best GitHub-flavored markdown rendering)
2. `mdcat` (good terminal markdown rendering)
3. `bat --language=markdown` (syntax highlighted text)
4. `cat` (plain text fallback)

## 🔧 Advanced Configuration

### UI Customization

The plugin uses [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for beautiful UI components. All menus and popups feature:
- Rounded borders
- Proper focus management
- Intuitive navigation
- Auto-sizing based on content

### Auto-save Configuration

```lua
require('nvim-notes').setup({
  auto_save = true,  -- Enable auto-save on buffer leave/focus lost
})
```

### Custom Vault Location

```lua
require('nvim-notes').setup({
  vault_path = '~/Documents/MyNotes',
})

-- Or set dynamically
:NotesSetVault ~/Documents/MyNotes
```

### Disable Default Keybindings

```lua
require('nvim-notes').setup({
  disable_default_keybindings = true,
})
```

## 🎯 Tips and Tricks

### 1. Daily Notes Workflow

Create a daily note with:
```vim
:NotesNew
```

Press Enter to use today's date-time, or type a custom name.

### 2. Project-Based Organization

Use subdirectories in your vault:
```
~/notes/
├── projects/
│   ├── project-a.md
│   └── project-b.md
├── meetings/
│   ├── 2024-01-15-standup.md
│   └── 2024-01-16-review.md
└── personal/
    ├── ideas.md
    └── todos.md
```

### 3. Effective Tagging

Use consistent tagging schemes:
```markdown
Tags: work meeting project-alpha urgent
Tags: personal idea creative
Tags: learning vim neovim
```

### 4. Pin Management

- Pin your most frequently accessed notes
- Pinned notes appear first in all search results
- Use the dashboard to see all pinned notes at a glance
- Toggle pin status with `:NotesPinToggle` or `<leader><tab>p`

### 5. Search Workflow

- Use `:NotesSearch` without arguments to browse all notes
- Pinned notes always appear first
- Search results show creation dates and tag indicators
- Use `:NotesSearchTags` for tag-specific searches

## 🐛 Troubleshooting

### Preview Not Working

1. Ensure you have a preview tool installed (glow, mdcat, bat)
2. Check if the preview command is detected:
   ```lua
   :lua print(require('nvim-notes.config').get_config().preview_command)
   ```

### UI Components Not Working

The plugin requires [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for its beautiful UI components. Make sure it's properly installed as a dependency.

### Vault Directory Issues

1. Ensure the vault directory exists and is writable
2. Check the vault path: `:lua print(require('nvim-notes.config').get_vault_path())`

### GitHub Sync Issues

1. Ensure GitHub CLI is installed and authenticated: `gh auth status`
2. Configure git authentication: `gh auth setup-git`
3. Check connectivity: The plugin tests GitHub connectivity before syncing
4. For hanging issues, ensure git credentials are properly configured

### Search Not Working

1. Ensure your vault directory contains `.md` files
2. Check that files are readable
3. Verify vault path is correct

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License 