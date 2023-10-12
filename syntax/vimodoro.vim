syntax match VimodoroTodo '^[0-9]\{3\}\. .*$' contains=VimodoroTodoId
syntax match VimodoroTodoId '^[0-9]\{3\}\. ' contained
syntax match VimodoroTodoInComplete  '^[0-9]\{3\}\. \zs.*\ze$'

syntax match VimodoroQuery '^Query>.*$'
syntax match VimodoroList '^#.*$'

syntax match VimodoroHelp '^".*$' contains=VimodoroHelpKey,VimodoroHelpTitle
syntax match VimodoroHelpKey '^" \zs.\{-}\ze:' contained
syntax match VimodoroHelpTitle '===.*===' contained

hi def link VimodoroTodoId Type
hi def link VimodoroTodoInComplete Function

hi def link VimodoroQuery Type
hi def link VimodoroList Comment

hi def link VimodoroHelp Comment
hi def link VimodoroHelpKey Function
hi def link VimodoroHelpTitle Type
