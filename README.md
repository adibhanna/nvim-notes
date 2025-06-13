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
- **📊 Dashboard**: Overview of your notes, tags, and recent activity

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

| Command            | Description                                  |
| ------------------ | -------------------------------------------- |
| `:NotesNew [name]` | Create a new note (defaults to current date) |

| `:NotesSearch [query]`    | Search notes by content                      |
| `:NotesSearchTags [tags]` | Search notes by tags                         |
| `:NotesPin`               | Toggle pin status of current note            |
| `:NotesPinned`            | Show all pinned notes                        |
| `:NotesPreview`           | Preview current note in markdown             |
| `:NotesIndex`             | Show notes dashboard                         |
| `:NotesSetVault [path]`   | Set the notes vault directory                |

### Keybindings

The plugin automatically sets up keybindings if `which-key.nvim` is installed:

| Keymap       | Action                  |
| ------------ | ----------------------- |
| `<leader>nn` | Create new note         |
| `<leader>ns` | Search notes content    |
| `<leader>nt` | Search by tags          |
| `<leader>np` | Toggle pin current note |
| `<leader>nP` | Search pinned notes     |
| `<leader>nv` | Preview current note    |
| `<leader>ni` | Show notes dashboard    |

If `which-key.nvim` is not installed, no default keybindings are set. You can use the commands directly or set up your own keybindings.

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

Add tags to your notes in several ways:

```markdown
# My Note

Tags: project personal important

Some content with #hashtags and more #tags.
```

### 3. Pinning Important Notes

Pin frequently accessed notes:

```lua
-- Pin current note
:NotesPin

-- View all pinned notes
:NotesPinned
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