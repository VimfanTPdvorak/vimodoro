" Ensure python3 is available
if !has('python3')
  echoerr "Python 3 support is required for vimodoro plugin"
  finish
endif

if &cp || exists("g:vimodoro_loaded") && g:vimodoro_loaded
    finish
endif

let g:vimodoro_loaded = 1

if !exists('g:vimodoro_SplitHeight')
    let g:vimodoro_SplitHeight = 20
endif

if !exists('g:vimodoro_WindowLayout')
    let g:vimodoro_WindowLayout = 1
endif

" Show cursorline
if !exists('g:vimodoro_CursorLine')
    let g:vimodoro_CursorLine = 1
endif

" If set, let vimodoro window get focus after being opened, otherwise
" focus will stay in current window.
if !exists('g:vimodoro_SetFocusWhenToggle')
    let g:vimodoro_SetFocusWhenToggle = 1
endif

command! RTM call pomodorohandlers#VimodoroToggle()
