if exists('b:current_syntax')
  finish
endif

" Prevent German spell check warnings aggressively
setlocal spelllang=en_us
setlocal nospell
" Disable spell file loading to prevent any language file warnings
let b:did_ftplugin = 1
let g:loaded_spellfile_plugin = 1

" Load base markdown syntax
runtime! syntax/markdown.vim

" Simple enhanced syntax for notes
syntax match notesTag '#\w\+'
syntax match notesTagLine '^Tags:.*$'
syntax match notesCreatedLine '^Created:.*$'
syntax match notesModifiedLine '^Modified:.*$'
syntax match notesDateStamp '\d\d\d\d-\d\d-\d\d'
syntax match notesTimeStamp '\d\d:\d\d'

" Highlight pinned indicator
syntax match notesPinned '📌'

" Simple task lists
syntax match notesTaskDone '^\s*- \[x\].*$'
syntax match notesTaskTodo '^\s*- \[ \].*$'

" Simple priority
syntax match notesPriorityHigh '!!!'
syntax match notesPriorityMedium '!!'

" Simple sections
syntax match notesSection '^##\s.*$'
syntax match notesSubsection '^###\s.*$'

" Define colors
highlight default link notesTag Identifier
highlight default link notesTagLine Special
highlight default link notesCreatedLine Comment
highlight default link notesModifiedLine Comment
highlight default link notesDateStamp Number
highlight default link notesTimeStamp Number
highlight default link notesPinned Special

highlight default link notesTaskDone Comment
highlight default link notesTaskTodo Todo

highlight default link notesPriorityHigh ErrorMsg
highlight default link notesPriorityMedium WarningMsg

highlight default link notesSection Title
highlight default link notesSubsection PreProc

let b:current_syntax = 'notes' 