" Filetype detection for notes
" This will use the custom notes syntax for markdown files in the notes vault

augroup nvim_notes_filetype
  autocmd!
  " Set filetype to 'notes' for markdown files in the vault directory
  " This will be set by the plugin when it knows the vault path
augroup END 