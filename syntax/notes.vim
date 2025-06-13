if exists('b:current_syntax')
  finish
endif

" Load base markdown syntax
runtime! syntax/markdown.vim

" Enhanced syntax for notes
syntax match notesTag '#[a-zA-Z0-9_-]\+' 
syntax match notesTagLine '^Tags:.*$'
syntax match notesCreatedLine '^Created:.*$'
syntax match notesModifiedLine '^Modified:.*$'
syntax match notesDateStamp '\d\{4\}-\d\{2\}-\d\{2\}'
syntax match notesTimeStamp '\d\{2\}:\d\{2\}'

" Highlight pinned indicator
syntax match notesPinned '📌'

" Links and references  
syntax match notesWikiLink '\[\[[^\]]\+\]\]'
syntax match notesReference '\[[^\]]\+\]([^)]\+)'

" Task lists (enhanced)
syntax match notesTaskDone '^\s*- \[x\].*$'
syntax match notesTaskTodo '^\s*- \[ \].*$'
syntax match notesTaskInProgress '^\s*- \[~\].*$'
syntax match notesTaskCancelled '^\s*- \[-\].*$'

" Priority indicators
syntax match notesPriorityHigh '!!!'
syntax match notesPriorityMedium '!!'
syntax match notesPriorityLow '\<!\>'

" Note sections
syntax region notesFrontmatter start=/^---$/ end=/^---$/
syntax match notesSection '^## .\+$'
syntax match notesSubsection '^### .\+$'

" Callouts and admonitions
syntax region notesCalloutInfo start=/^> \[!INFO\]/ end=/^$/
syntax region notesCalloutNote start=/^> \[!NOTE\]/ end=/^$/
syntax region notesCalloutWarning start=/^> \[!WARNING\]/ end=/^$/
syntax region notesCalloutError start=/^> \[!ERROR\]/ end=/^$/
syntax region notesCalloutTip start=/^> \[!TIP\]/ end=/^$/

" Highlights
syntax match notesHighlight '==[^=]\+==='

" Define colors
highlight default link notesTag Identifier
highlight default link notesTagLine Special
highlight default link notesCreatedLine Comment
highlight default link notesModifiedLine Comment
highlight default link notesDateStamp Number
highlight default link notesTimeStamp Number
highlight default link notesPinned Special

highlight default link notesWikiLink Underlined
highlight default link notesReference Underlined

highlight default link notesTaskDone Comment
highlight default link notesTaskTodo Todo
highlight default link notesTaskInProgress WarningMsg
highlight default link notesTaskCancelled Comment

highlight default link notesPriorityHigh ErrorMsg
highlight default link notesPriorityMedium WarningMsg
highlight default link notesPriorityLow Identifier

highlight default link notesFrontmatter Comment
highlight default link notesSection Title
highlight default link notesSubsection PreProc

highlight default link notesCalloutInfo Question
highlight default link notesCalloutNote Special
highlight default link notesCalloutWarning WarningMsg
highlight default link notesCalloutError ErrorMsg
highlight default link notesCalloutTip Identifier

highlight default link notesHighlight Search

let b:current_syntax = 'notes' 