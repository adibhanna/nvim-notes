# nvim-notes

A comprehensive note-taking plugin for Neovim with full markdown support, beautiful UI components, tagging, pinning, search functionality, and markdown preview capabilities.

## ✨ Features

- **📝 Quick Note Creation**: Create notes with automatic date-based naming
- **🔍 Powerful Search**: Search notes by content, filename, or tags
- **🏷️ Tag Management**: Create, manage, and search by tags
- **📌 Pin Notes**: Pin important notes for quick access
- **👀 Markdown Preview**: Multiple preview options including terminal, browser, and floating windows
- **🎨 Syntax Highlighting**: Enhanced markdown syntax with note-specific highlighting
- **🗂️ Vault Management**: Organized note storage with customizable vault location
- **✨ Beautiful UI**: Elegant menus and inputs powered by nui.nvim
- **📊 Dashboard**: Beautiful popup overview of your notes, tags, and recent activity

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'adibhanna/nvim-notes',
  dependencies = {
    'junegunn/fzf', -- Required for fuzzy finding
    'junegunn/fzf.vim', -- Required for fzf integration
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
    'junegunn/fzf', -- Required for fuzzy finding
    'junegunn/fzf.vim', -- Required for fzf integration
  },
  config = function()
    require('nvim-notes').setup()
  end
}
```

## 📋 Prerequisites

Before installing, make sure you have FZF installed on your system:

```bash
# macOS
brew install fzf

# Ubuntu/Debian
sudo apt install fzf

# Arch Linux
sudo pacman -S fzf

# Or install via git
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
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
  telescope_theme = 'dropdown',              -- Telescope theme
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

| Command                   | Description                                  |
| ------------------------- | -------------------------------------------- |
| `:NotesNew [name]`        | Create a new note (defaults to current date) |
| `:NotesSearch [query]`    | Search notes by content (pinned shown first) |
| `:NotesSearchTags [tags]` | Search notes by tags                         |
| `:NotesPinToggle`         | Toggle pin status of current note            |
| `:NotesDelete`            | Delete current note (with confirmation)      |
| `:NotesPreview`           | Preview current note in markdown             |
| `:NotesIndex`             | Show notes dashboard popup                   |
| `:NotesSetVault [path]`   | Set the notes vault directory                |

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

If `which-key.nvim` is not installed, no default keybindings are set. You can use the commands directly or set up your own keybindings.

### 📚 Dashboard Features

The Notes Dashboard (`<leader><tab>i` or `:NotesIndex`) provides a beautiful popup overview:

- **📊 Quick Stats**: Total notes, pinned count, tags overview
- **📌 Pinned Notes**: Your most important notes at a glance
- **🕐 Recent Activity**: Latest modified notes
- **🏷️ Popular Tags**: Most used tags with counts
- **⚡ Quick Actions**: Single-key shortcuts to common actions
- **📱 Interactive**: Press `n`, `s`, `t`, `p`, `v` for instant actions
- **❓ Help**: Press `?` for keyboard shortcuts

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
-- Create a note with today's date
:NotesNew

-- Create a note with specific name
:NotesNew "Meeting Notes"
```

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

### 4. Searching and Discovery

```lua
-- Search by content
:NotesSearch "important meeting"

-- Search by tags
:NotesSearchTags "project work"

-- Browse all notes  
:NotesSearch
```

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

-- Or use the keybing
<leader><tab>i
```

The dashboard shows your vault stats, pinned notes, recent activity, and popular tags with interactive shortcuts for quick actions.

## 🎨 Syntax Highlighting

The plugin provides enhanced syntax highlighting for notes:

- **Tags**: Highlighted with `#tag` syntax and `Tags:` lines
- **Dates/Times**: Special highlighting for timestamps
- **Task Lists**: Enhanced checkbox highlighting
- **Callouts**: Support for `[!INFO]`, `[!NOTE]`, `[!WARNING]` etc.
- **Wiki Links**: `[[Internal Links]]` highlighting
- **Highlights**: `==highlighted text==` support

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

# For browser preview and export
pip install grip
npm install -g @shd101wyy/markdown-preview-enhanced
```

### Preview Options

- **Terminal Preview**: `:NotesPreview` (uses glow/mdcat/bat)
- **Browser Preview**: Available through the preview module
- **Floating Window**: Quick preview in a floating window
- **Live Preview**: Auto-refreshing preview on file changes
- **Export**: Export to HTML/PDF using pandoc

## 🔧 Advanced Configuration

### UI Customization

The plugin uses [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for beautiful UI components. All menus and inputs are styled with rounded borders and intuitive navigation.

### Auto-save Configuration

```lua
require('nvim-notes').setup({
  auto_save = true,  -- Enable auto-save
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

## 🎯 Tips and Tricks

### 1. Daily Notes Workflow

Create a daily note with:
```vim
:NotesNew
```

This automatically creates a note named with today's date.

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

### 4. Link Between Notes

Use wiki-style links to connect notes:
```markdown
This relates to [[Meeting Notes]] and [[Project Alpha]].
```

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

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by Obsidian and other note-taking applications
- Built for the Neovim ecosystem
- Uses [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for beautiful UI components 