" Ensure python3 is available
if !has('python3')
  echoerr "Python 3 support is required for vimodoro plugin"
  finish
endif

if &cp || exists("g:vimodoro_loaded") && g:vimodoro_loaded
    finish
endif

let g:vimodoro_loaded = 1

let s:rtmREST = "https://api.rememberthemilk.com/services/rest/"

let s:plugin_root = expand("<sfile>:h:h")
let s:prnTaskList_py = s:plugin_root . "/py/prnTaskList.py"

command! VimodoroRTM call s:vimodoroGetTasksList("dueBefore:tomorrow AND status:incomplete")<cr>

function! s:vimodoroGetTasksList(rtmFilter)
    " TODO: Handling the creation of and/or set focus to the RTM tasks list
    " window.
    execute "py3 sys.argv = " . "['" . a:rtmFilter . "']"
    execute "py3file " . s:prnTaskList_py
endfunction
