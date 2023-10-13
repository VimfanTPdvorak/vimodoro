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

syntax match VimodoroTodoComplete '\~\~.*\~\~' conceal

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

"hi def link StrikeThrough VimodoroTodoCompleted
"call matchadd('StrikeThrough', '\~\~\ze.*\~\~', 10, -1, {'conceal': ''})
"call matchadd('StrikeThrough', '\~\~\.*\zs\~\~\ze', 10, -1, {'conceal': ''})

syntax match VimodoroRTMQuery '.*$' contained
syntax match VimodoroQueryPrompt '^Query>' contained
syntax match VimodoroQuery '^Query>.*$' contains=VimodoroQueryPrompt,VimodoroRTMQuery nextgroup=VimodoroRTMQuery
syntax match VimodoroList '^#.*$'

hi def link VimodoroRTMQuery Keyword
hi def link VimodoroQueryPrompt Function
hi def link VimodoroList Comment
