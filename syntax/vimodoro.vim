setlocal conceallevel=3
setlocal concealcursor=nvc

syntax match VimodoroHelpKey '^" \zs.\{-}\ze:' contained
syntax match VimodoroHelpTitle '===.*===' contained
syntax match VimodoroHelp '^".*$' contains=VimodoroHelpKey,VimodoroHelpTitle

hi def link VimodoroHelp Comment
hi def link VimodoroHelpKey Function
hi def link VimodoroHelpTitle Type

syntax match VimodoroTodoInComplete  '.*$' contained
syntax match VimodoroTodoId '^[0-9]\{3\}\. ' contained nextgroup=VimodoroTodoInComplete
syntax match VimodoroTodo '^[0-9]\{3\}\. .*$' contains=VimodoroTodoId,VimodoroTodoInComplete

hi def link VimodoroTodoInComplete Constant
hi def link VimodoroTodoId Type

syntax match VimodoroStrikethrough '\~\~' contained conceal
syntax match VimodoroTodoComplete '\~\~[^\~]\+\~\~' contains=VimodoroStrikethrough

" Ref: https://stackoverflow.com/questions/59956790/terminal-vim-strikethrough
if &term =~ 'xterm\|kitty\|alacritty\|tmux'
    let &t_Ts = "\e[9m"   " Strikethrough
    let &t_Te = "\e[29m"
    let &t_Cs = "\e[4:3m" " Undercurl
    let &t_Ce = "\e[4:0m"
endif

if v:version > 800 || (v:version == 800 && has('patch1038')) || has('nvim-0.4.3')
  hi def VimodoroTodoCompleted ctermfg=Grey term=strikethrough cterm=strikethrough gui=strikethrough
else
  hi def link VimodoroTodoCompleted Comment
endif

hi def link VimodoroTodoComplete VimodoroTodoCompleted

syntax match VimodoroQueryPrompt '^Query>' contained
syntax match VimodoroQuery '^Query>.*$'
            \ contains=
            \VimodoroQueryPrompt,
            \VimodoroRTMkeywords,
            \VimodoroRTMOperators

hi def link VimodoroQueryPrompt Function

syntax match VimodoroRTMKeywords
            \ '\clist\|
            \listContains\|
            \priority\|
            \status\|
            \\<tag\>\|tagContains\|
            \isTagged\|
            \location\|
            \locationContains\|
            \locatedWithin\|
            \isLocated\|
            \isRepeating\|
            \name\|
            \noteContains\|
            \hasNotes\|
            \filename\|
            \hasAttachments\|
            \\<due\>\|dueBefore\|dueAfter\|dueWithin\|
            \\<start\>\|startBefore\|startAfter\|startWithin\|
            \timeEstimate\|
            \hasTimeEstimate\|
            \hasURL\|
            \hasSubtasks\|
            \isSubtask\|
            \\<completed\>\|completedBefore\|completedAfter\|completedWithin\|
            \\<added\>\|addedBefore addedAfter addedWithin\|
            \updated\|updatedBefore\|updatedAfter\|updatedWithin\|
            \posponed\|
            \isShared sharedWith\|
            \givenTo\|givenBy\|isGiven\|
            \source\|
            \includeArchived'
            \ contained

syntax match VimodoroRTMOperators
            \ '\c\<AND\>\|
            \\<OR\>\|
            \\<NOT\>\|
            \"\|
            \(\|)\|
            \:'
            \ contained

hi def link VimodoroRTMKeywords Keyword
hi def link VimodoroRTMOperators Type

syntax match VimodoroList '^#.*$'
hi def link VimodoroList Comment
