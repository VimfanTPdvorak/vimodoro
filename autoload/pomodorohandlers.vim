" autoload/pomodorohandlers.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License
" Maintainer: Billy Chamberlain

if exists("g:loaded_autoload_pomodorohandlers") || &cp
    " requires nocompatible
    " also, don't double load
    finish
endif

let g:loaded_autoload_pomodorohandlers = 1

let s:pomodoro_count = 1
let s:pomodoro_break_duration = g:pomodoro_short_break

const s:pomodoro_default_rtm_filter = "dueBefore:tomorrow AND status:incomplete"
let s:pomodoro_rtm_filter = s:pomodoro_default_rtm_filter

" s:vimodoro_state
" ----------------
" inactive: Vimodoro is inactive
" focus   : Vimodoro is actived and in focus mode/state
" break   : Vimodoro is actived and in break mode/state
" focus_ended: Vimodoro focus session ended and awaited for user action
" break_ended: Vimodoro break session ended and awaited for user action
const s:vimodoro_states = { 'inactive': 0, 'focus': 1, 'break': 2, 'focus_ended': 3, 'break_ended': 4 }

function! pomodorohandlers#set_secret(the_secret)
    if !exists("s:pomodoro_secret")
        let s:pomodoro_secret = a:the_secret
        call pomodorocommands#logger("g:pomodoro_debug_file", "Secret has been set.")
    else
        call pomodorocommands#logger("g:pomodoro_debug_file", "pomodorohandlers#set_secret: Do nothing.")
    endif
endfunction

function! pomodorohandlers#pause(name,timer)
    call pomodorocommands#notify()

    call SetPomodoroState(s:pomodoro_secret, s:vimodoro_states.focus_ended)

    if s:pomodoro_count == 4
        let s:pomodoro_break_duration = g:pomodoro_long_break
    else
        let s:pomodoro_break_duration = g:pomodoro_short_break
    endif

    call pomodorocommands#logger("g:pomodoro_debug_file", "s:pomodoro_count = " . s:pomodoro_count)
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:pomodoro_break_duration = " . s:pomodoro_break_duration)

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count .
                \ " focus session ended. Waiting for user's action...")

    let answer = ''

    while answer != "YES" && answer != "INTERRUPTED" && answer != "DONE"
        redraw
        let answer = input("Great, " . a:name . " #" . s:pomodoro_count . " focus session has ended. Take a break or what's next?\n
                    \Type \"YES\" = Take a " . s:pomodoro_break_duration . "m break,\n
                    \Type \"INTERRUPTED\" = An interruption. Stop the Pomodoro,\n
                    \Type \"DONE\" = Stop the Pomodoro and mark the task as Done.\n
                    \Your answer? ")
    endwhile

    if answer == "YES"
        call SetPomodoroBreakAt(s:pomodoro_secret) " Track break at time
        call SetPomodoroState(s:pomodoro_secret, s:vimodoro_states.break)

        call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count .
                    \ " focus ended. Duration: " . pomodorocommands#calculate_duration(GetPomodoroStartedAt(1), localtime()) . ".")
        call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count . " break started.")

        " Start the break timer
        call StartBreakTimer(s:pomodoro_secret, a:name, s:pomodoro_break_duration)
    elseif answer == "INTERRUPTED"
        call PomodoroInterrupted(s:pomodoro_secret)
    elseif answer == "DONE"
        call s:vimodoro.rtm_task_complete()
    endif
endfunction

function! pomodorohandlers#restart(name, duration, timer)
    call pomodorocommands#notify()

    call SetPomodoroState(s:pomodoro_secret, s:vimodoro_states.break_ended)

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count .
                \ " break session ended. Waiting for user's action...")

    let answer = ''

    while answer != "YES" && answer != "INTERRUPTED" && answer != "DONE"
        redraw
        let answer = input(a:name . " " . a:duration . "m break is over... Feeling rested?\nWant to start another Pomodoro?\n
                    \Type \"YES\" = Yes. I'm ready to continue working on the task,\n
                    \Type \"INTERRUPTED\" = An interruption. Stop the Pomodoro,\n
                    \Type \"DONE\" = Stop the Pomodoro and mark the task as Done.\n
                    \Your answer? ")
    endwhile

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count . " break ended. " .
                \ "Duration: " . pomodorocommands#calculate_duration(GetPomodoroStartedAt(2), localtime()) . ".")

    if answer == "YES"
        if s:pomodoro_count < 4
            let s:pomodoro_count += 1
        else
            let s:pomodoro_count = 1
        endif
        call VimodoroStart(s:pomodoro_secret, a:name, s:task_type)
    elseif answer == "INTERRUPTED"
        call PomodoroInterrupted(s:pomodoro_secret)
    elseif answer == "DONE"
        call s:vimodoro.rtm_task_complete()
    endif
endfunction

function! pomodorohandlers#rtm_task_complete(the_secret)
    if a:the_secret == s:pomodoro_secret
        call s:vimodoro.rtm_task_complete()
    endif
endfunction

function! pomodorohandlers#rtm_reset_if_non_rtm_task(the_secret)
    if a:the_secret == s:pomodoro_secret
        call s:vimodoro.resetRTMTaskKey()
    endif
endfunction

function! pomodorohandlers#get_pomodoro_count()
    return s:pomodoro_count
endfunction

function! pomodorohandlers#get_pomodoro_break_duration()
    return s:pomodoro_break_duration
endfunction

let s:rtmREST = "https://api.rememberthemilk.com/services/rest/"

let s:plugin_root = expand("<sfile>:h:h")
let s:getTaskList_py = s:plugin_root . "/py/getTaskList.py"
let s:setTaskComplete_py = s:plugin_root . "/py/setTaskComplete.py"

" Help text
let s:helpmore = ['"   ===== Hotkeys =====']

if !g:vimodoro_HelpLine
    let s:helpless = []
else
    let s:helpless = ['" Press ? for help.']
endif

" Keymap
let s:keymap = []
" action, key, help.
let s:keymap += [['Help', '?', 'Toggle quick help']]
let s:keymap += [['Close', 'q', 'Close Vimodoro panel']]
let s:keymap += [['Reload', 'r', 'Reload tasks list']]
let s:keymap += [['Start', 's', 'Start Working on current task']]

const s:task_types = { 'manual': 0, 'rtm': 1 }
let s:task_type = s:task_types.manual

let s:vdrId = ''
let s:rtm_taskname = ''

let s:tasklist = {}
" Store RTM list ID, task series ID, and task ID
" tasklist = { '0': {'type': 'list', 'label': 'Personal'},
"             '1': {'type': 'taskseries',
"                   'tasks': {
"                               '001': {'lsID': '123', 'tsID': '555', 'ID': '544', 'label': 'To do #1', 'completed': '2023-06-22T12:38:59Z'},
"                               '002': {'lsID': '123', 'tsID': '455', 'ID': '444', 'label': 'To do #2', 'completed': ''}
"                            }
"                  },
"             '2': {'type': 'blankline', 'label': ''},
"             '3': {'type': 'list', 'label': 'Work'},
"             '4': {'type': 'taskseries',
"                   'tasks': {
"                             '003': {...}
"                            }
"                  }
"            }

" TODO: The use of s:panel and s:vimodoro is excessive for this Vomodoro plugin.
" Should simplifies the implementation since the RTM tasks list should be a
" single instance within a (n)vim session.

let s:panel = {}

function! s:new(obj) abort
    let newobj = deepcopy(a:obj)
    call newobj.Init()
    return newobj
endfunction

function! s:panel.Init() abort
    let self.bufname = "invalid"
endfunction

function! s:panel.SetFocus() abort
    let winnr = bufwinnr(self.bufname)
    if winnr == -1
        echoerr "Fatal: window does not exist!"
        return
    elseif winnr == winnr() " already focused.
        return
    else
        " wincmd would cause cursor outside window.
        call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>")
    endif
endfunction

function! s:panel.IsVisible() abort
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:panel.Hide() abort
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
endfunction

let s:vimodoro = s:new(s:panel)

call pomodorocommands#logger("g:pomodoro_debug_file", "s:vimodoro.bufname = " . s:vimodoro.bufname)

function! s:vimodoro.Init() abort
    let self.bufname = "vimodoro_".s:getUniqueID()

    " Increase to make it unique.
    let self.height = g:vimodoro_SplitHeight
    let self.targetid = -1
    let self.targetBufnr = -1

    let self.tasklistloaded = 0
    let self.showHelp = 0
endfunction

call pomodorocommands#logger("g:pomodoro_debug_file", "s:vimodoro.bufname = " . s:vimodoro.bufname)

function! s:vimodoro.BindKey() abort
    if v:version > 703 || (v:version == 703 && has("patch1261"))
        let map_options = ' <nowait> '
    else
        let map_options = ''
    endif
    let map_options = map_options.' <silent> <buffer> '
    for i in s:keymap
        silent exec 'nmap '.map_options.i[1].' <plug>Vimodoro'.i[0]
        silent exec 'nnoremap '.map_options.'<plug>Vimodoro'.i[0]
            \ .' :call <sid>vimodoroAction("'.i[0].'")<cr>'
    endfor
    if exists('*g:Vimodoro_CustomMap')
        call g:Vimodoro_CustomMap()
    endif
endfunction

function! s:vimodoro.BindAu() abort
    " Auto exit if it's the last window
    augroup Vimodoro_Main
        au!
        au BufEnter <buffer> call s:exitIfLast()
        au BufEnter,BufLeave <buffer> if exists('t:vimodoro') |
                    \let t:vimodoro.height = winheight(winnr()) | endif
    augroup end
endfunction

function! s:vimodoro.Action(action) abort
    if !self.IsVisible() || !exists('b:isVimodoroBuffer')
        echoerr "Fatal: window does not exist."
        return
    endif
    if !has_key(self,'Action'.a:action)
        echoerr "Fatal: Action does not exist!"
        return
    endif
    if a:action == "Start" || a:action == "Reload"
        exec 'call self.Action'.a:action.'()'
    else
        silent exec 'call self.Action'.a:action.'()'
    endif
endfunction

" Helper function, do action in target window, and then update itself.
function! s:vimodoro.ActionInTarget(cmd) abort
    if !self.SetTargetFocus()
        return
    endif
    " Target should be a normal buffer.
    if (&bt == '' || &bt == 'acwrite') && (&modifiable == 1) && (mode() == 'n')
        call s:exec(a:cmd)
        " Open folds so that the change being undone/redone is visible.
        if s:open_folds
            call s:exec('normal! zv')
        endif
        call self.Update()
    endif
    " Update not always set current focus.
    call self.SetFocus()
endfunction

function! s:vimodoro.ActionHelp() abort
    let self.showHelp = !self.showHelp
    call self.Draw()
endfunction

function! s:vimodoro.ActionFocusTarget() abort
    call self.SetTargetFocus()
endfunction

function! s:vimodoro.ActionClose() abort
    call self.Toggle()
endfunction

function! s:vimodoro.ActionStart() abort
    call pomodorocommands#logger("g:pomodoro_debug_file", string(s:tasklist))
    let s:vdrId = matchstr(getline('.'), '^\d\{3}')
    let tasklistKey = s:getTasklistKey(s:vdrId)
    if tasklistKey
        let s:rtm_taskname = '[🐮 ' . substitute(matchstr(getline('.'), '\.\s.*$'), '^\.\s', '', '') . ']'
        let choice = confirm(s:rtm_taskname . "\nWant to start working on the selected task?", "&Yes\n&No")
        if choice == 1
            call self.Toggle()
            let s:task_type = s:task_types.rtm
            call VimodoroStart(s:pomodoro_secret, s:rtm_taskname, s:task_type)
            call pomodorocommands#logger("g:pomodoro_debug_file", "self.bufname = " . self.bufname)
            call pomodorocommands#logger("g:pomodoro_debug_file",
                        \ "VimodoroStart [" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['lsID'] . ":" .
                        \ s:tasklist[tasklistKey]['tasks'][s:vdrId]['tsID'] . ":" .
                        \ s:tasklist[tasklistKey]['tasks'][s:vdrId]['ID'] . "]")
        endif
    else
        echohl WarningMsg
        echo "Move the cursor to a task you wish to begin, then press the start key."
        echohl None
    endif
endfunction

function! s:getTasklistKey(vdrId)
    for key in keys(s:tasklist)
        if s:tasklist[key]['type'] == 'taskseries'
            let tasks = s:tasklist[key]['tasks']
            if has_key(tasks, a:vdrId)
                return key
            endif
        endif
    endfor
    return ''
endfunction

function! s:vimodoro.ActionReload() abort
    call self.Update(1)
endfunction

" May fail due to target window closed.
function! s:vimodoro.SetTargetFocus() abort
    for winnr in range(1, winnr('$')) "winnr starts from 1
        if getwinvar(winnr,'vimodoro_id') == self.targetid
            if winnr() != winnr
                call s:exec("norm! ".winnr."\<c-w>\<c-w>")
                return 1
            endif
        endif
    endfor
    return 0
endfunction

function! s:vimodoro.Toggle() abort
    "Global auto commands to keep vimodoro up to date.
    let auEvents = "BufEnter,InsertLeave,CursorMoved,BufWritePost"

    if self.IsVisible()
        call self.Hide()
        call self.SetTargetFocus()
        augroup Vimodoro
            autocmd!
        augroup END
    else
        call self.Show()
        if !g:vimodoro_SetFocusWhenToggle
            call self.SetTargetFocus()
        endif
        augroup Vimodoro
            au!
            exec "au! ".auEvents." * call pomodorohandlers#VimodoroUpdate()"
        augroup END
    endif
endfunction

function! s:vimodoro.Show() abort
    if self.IsVisible()
        return
    endif

    let self.targetid = w:vimodoro_id

    " Create vimodoro window.
    if exists("g:vimodoro_CustomVimodoroCmd")
        let cmd = g:vimodoro_CustomVimodoroCmd . ' ' .
                    \self.bufname
    elseif g:vimodoro_WindowLayout == 1 || g:vimodoro_WindowLayout == 2
        let cmd = "botright horizontal" .
                    \self.height . ' new ' . self.bufname
    else
        keepalt botright horizontal 20 new /tmp/test.txt
        let cmd = "topleft horizontal" .
                    \self.height . ' new ' . self.bufname
    endif
    call s:exec("silent keepalt ".cmd)
    call self.SetFocus()

    " We need a way to tell if the buffer is belong to vimodoro,
    " bufname() is not always reliable.
    let b:isVimodoroBuffer = 1

    setlocal winfixheight
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nonumber
    setlocal norelativenumber
    if g:vimodoro_CursorLine
        setlocal cursorline
    else
        setlocal nocursorline
    endif
    setlocal nomodifiable
    setfiletype vimodoro

    call self.BindKey()
    call self.BindAu()

    let ei_bak= &eventignore
    set eventignore=all

    call self.SetTargetFocus()
    let self.targetBufnr = -1 "force update
    call self.Update()

    let &eventignore = ei_bak
endfunction

function! s:vimodoro.Update(requestReload = 0) abort
    if !self.IsVisible()
        return
    endif
    " Do nothing if we're in the vimodoro panel and not requesting reload
    if exists('b:isVimodoroBuffer') && !a:requestReload
        return
    endif
    if (&bt != '' && &bt != 'acwrite') || (&modifiable == 0) || (mode() != 'n')
        if &bt == 'quickfix' || &bt == 'nofile'
            "Do nothing for quickfix and q:
            return
        endif
        if self.targetBufnr == bufnr('%') && self.targetid == w:vimodoro_id && !a:requestReload
            return
        endif
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
    else
        let emptybuf = 0
        "update vimodoro,set focus
        if self.targetBufnr == bufnr('%')
            let self.targetid = w:vimodoro_id
        endif
    endif

    let self.targetBufnr = bufnr('%')
    let self.targetid = w:vimodoro_id
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    "call self.ConvertInput(1) "update all.
    call self.Render(a:requestReload)
    call self.SetFocus()
    call self.Draw()
endfunction

" TODO: Print the tasks list and keep track of the list ID, task series ID, and
" task ID per task.
function! s:vimodoro.Render(requestReload = 0) abort
    if a:requestReload || !self.tasklistloaded
        if a:requestReload
            setlocal modifiable
            setlocal textwidth=0
            " Delete text into blackhole register.
            call s:exec('1,$ d _')
            call s:exec('normal! iReloading...')
            setlocal nomodifiable
        endif

        let rtmFilter = s:pomodoro_rtm_filter

        " Insert task list into s:tasklist
        execute "py3 sys.argv = " . "['" . rtmFilter . "']"
        execute "py3file " . s:getTaskList_py

        call pomodorocommands#logger("g:pomodoro_debug_file", string(s:tasklist))
    endif
endfunction

function! s:vimodoro.Draw() abort
    " remember the current cursor position.
    let savedview = winsaveview()

    setlocal modifiable
    setlocal textwidth=0
    " Delete text into blackhole register.
    call s:exec('1,$ d _')

    call append(0, 'Query> ' .. s:pomodoro_rtm_filter)

    call pomodorocommands#logger("g:pomodoro_debug_file", "s:tasklist = " . string(s:tasklist))

    if len(s:tasklist)
        for key in keys(s:tasklist)
            call pomodorocommands#logger("g:pomodoro_debug_file", "s:tasklist('" . key . "']['type'] = " . s:tasklist[key]['type'])
            if s:tasklist[key]['type'] == 'list'
                call append(line('$'), s:tasklist[key]['label'])
            elseif s:tasklist[key]['type'] == 'taskseries'
                for vdrKey in keys(s:tasklist[key]['tasks'])
                    let delMarker = s:tasklist[key]['tasks'][vdrKey]['completed'] != '' ? '~~' : ''
                    call append(line('$'), delMarker .. vdrKey . ". " . s:tasklist[key]['tasks'][vdrKey]['label'] .. delMarker)
                    "let sT = s:tasklist[key]['tasks'][vdrKey]['completed'] != '' ? &t_Ts : ''
                    "let eT = s:tasklist[key]['tasks'][vdrKey]['completed'] != '' ? &t_Te : ''
                    "call append(line('$'), sT .. vdrKey . ". " . s:tasklist[key]['tasks'][vdrKey]['label'] .. eT)
                endfor
            elseif s:tasklist[key]['type'] == 'blankline'
                call append(line('$'), '')
            endif
        endfor
    else
        call append(line('$'), '🚧 No tasks returned')
    endif

    call self.AppendHelp()

    "remove the last empty line
    "call s:exec('$d _')

    " restore previous cursor position.
    call winrestview(savedview)

    setlocal nomodifiable
endfunction

function! s:vimodoro.AppendHelp() abort
    if self.showHelp
        call append(0,'') "empty line
        for i in s:keymap
            call append(0,'" '.i[1].' : '.i[2])
        endfor
        call append(0,s:helpmore)
    else
        if g:vimodoro_HelpLine
            call append(0,'')
        endif
        call append(0,s:helpless)
    endif
endfunction

function! s:vimodoro.rtm_task_complete() abort
    call pomodorocommands#logger("g:pomodoro_debug_file", "self.bufname = " . self.bufname)
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:vdrId = " . s:vdrId)
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:tasklist = " . string(s:tasklist))
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:rtm_taskname = " . s:rtm_taskname)
    call pomodorocommands#logger("g:pomodoro_debug_file", "GetPomodoroName() = " . GetPomodoroName())

    let tasklistKey = s:getTasklistKey(s:vdrId)

    if tasklistKey && GetPomodoroName() == s:rtm_taskname
        call pomodorocommands#logger("g:pomodoro_debug_file",
                    \ "py3 sys.argv = " .
                    \ "[\"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['lsID'] . "\",
                    \ \"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['tsID'] . "\",
                    \ \"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['ID'] . "\"]")
        execute "py3 sys.argv = " .
                    \ "[\"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['lsID'] . "\",
                    \ \"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['tsID'] . "\",
                    \ \"" . s:tasklist[tasklistKey]['tasks'][s:vdrId]['ID'] . "\"]"
        execute "py3file " . s:setTaskComplete_py
        " TODO: Should check if the mark as done was a success to decide wether
        " or not to reset the s:vdrId variable, etc.
        call remove(s:tasklist[tasklistKey]['tasks'], s:vdrId)
    endif

    " This echo has been done in the above python script, but I don't know why
    " it didn't show up or got cleared.
    echo "The task " . GetPomodoroName() . " has been marked as done."

    call PomodoroUninterrupted(s:pomodoro_secret)

    " Re-initiate these two variables to an empty string so that when starting a
    " new task, the task name will be empty and calling this method won't
    " calling the rtm.tasks.complete method since the s:vdrId has been set to
    " blank -- the task was not interrupted, nor still WIP.
    let s:rtm_taskname = ''
    let s:vdrId = ''
endfunction

" This is as a way to prevent an intercepted RTM task by a non-rtm task will not
" be masked as completed when the non-RTM task marked as done.
function! s:vimodoro.resetRTMTaskKey()
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:vimodoro.resetRTMTaskKey()")
    let s:task_type = s:task_types.manual
    let s:rtm_taskname = ''
    let s:vdrId = ''
endfunction

function! s:exec(cmd) abort
    silent exe a:cmd
endfunction

" Don't trigger any events(like BufEnter which could cause redundant refresh)
function! s:exec_silent(cmd) abort
    let ei_bak= &eventignore
    set eventignore=BufEnter,BufLeave,BufWinLeave,InsertLeave,CursorMoved,BufWritePost
    silent exe a:cmd
    let &eventignore = ei_bak
endfunction

" Return a unique id each time.
let s:cntr = 0
function! s:getUniqueID() abort
    let s:cntr = s:cntr + 1
    return s:cntr
endfunction

function! s:vimodoroAction(action) abort
    if !exists('t:vimodoro')
        echoerr "Fatal: t:vimodoro does not exist!"
        return
    endif
    call t:vimodoro.Action(a:action)
endfunction

function! s:exitIfLast() abort
    let num = 0
    if exists('t:vimodoro') && t:vimodoro.IsVisible()
        let num = num + 1
    endif
    if winnr('$') == num
        if exists('t:vimodoro')
            call t:vimodoro.Hide()
        endif
    endif
endfunction

function! pomodorohandlers#VimodoroUpdate() abort
    if !exists('t:vimodoro')
        return
    endif
    if !exists('w:vimodoro_id')
        let w:vimodoro_id = 'id_'.s:getUniqueID()
    endif
    " assume window layout won't change during updating.
    let thiswinnr = winnr()
    call t:vimodoro.Update()
    " focus moved
    if winnr() != thiswinnr
        call s:exec("norm! ".thiswinnr."\<c-w>\<c-w>")
    endif
endfunction

function! pomodorohandlers#VimodoroToggle() abort
    try
        if !exists('w:vimodoro_id')
            let w:vimodoro_id = 'id_'.s:getUniqueID()
        endif
        if !exists('t:vimodoro')
            let t:vimodoro = s:new(s:vimodoro)
        endif
        call pomodorocommands#logger("g:pomodoro_debug_file", "[pomodorohandlers#VimodoroToggle()] w:vimodoro_id = " . w:vimodoro_id . ", t:vimodoro = " . string(t:vimodoro))
        call t:vimodoro.Toggle()
    catch /^Vim\%((\a\+)\)\?:E11/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
endfunction

function! pomodorohandlers#VimodoroIsVisible() abort
    return (exists('t:vimodoro') && t:vimodoro.IsVisible())
endfunction

function! pomodorohandlers#VimodoroHide() abort
    if pomodorohandlers#VimodoroIsVisible()
        try
            call pomodorohandlers#VimodoroToggle()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    endif
endfunction

function! pomodorohandlers#VimodoroShow(rtmFilter = s:pomodoro_rtm_filter) abort
    try
        if a:rtmFilter == ''
            let rtmFilter = s:pomodoro_default_rtm_filter
        else
            let rtmFilter = a:rtmFilter
        endif
        if rtmFilter !=? s:pomodoro_rtm_filter
            let s:pomodoro_rtm_filter = rtmFilter
            if exists('t:vimodoro')
                " If t:vimodoro exists it meant the panel has been loaded.
                let t:vimodoro.tasklistloaded = 0
                call t:vimodoro.Toggle()
            endif
        endif
        if ! pomodorohandlers#VimodoroIsVisible()
            call pomodorohandlers#VimodoroToggle()
        else
            call t:vimodoro.SetFocus()
        endif
    catch /^Vim\%((\a\+)\)\?:E11/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
endfunction

function! pomodorohandlers#VimodoroFocus() abort
    if pomodorohandlers#VimodoroIsVisible()
        try
            call t:vimodoro.SetFocus()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    endif
endfunction

function! pomodorohandlers#VimodoroGetRTMFilter() abort
    return s:pomodoro_rtm_filter
endfunction
