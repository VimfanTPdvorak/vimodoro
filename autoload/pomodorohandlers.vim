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

    " Temporarily set the status to inactive so that the SetPomodoroState() will
    " stop the Pomodoro timer.
    call SetPomodoroState(s:pomodoro_secret, 0)

    if s:pomodoro_count == 4
        let s:pomodoro_break_duration = g:pomodoro_long_break
    else
        let s:pomodoro_break_duration = g:pomodoro_short_break
    endif

    call pomodorocommands#logger("g:pomodoro_debug_file", "s:pomodoro_count = " . s:pomodoro_count)
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:pomodoro_break_duration = " . s:pomodoro_break_duration)

    let answer = ''

    while answer != "YES" && answer != "INTERRUPTED" && answer != "DONE"
        redraw
        let answer = input("Great, " . a:name . " #" . s:pomodoro_count . " focus session has ended. Take a break or what's next?\n
                    \Type \"YES\" = Take a " . s:pomodoro_break_duration . "m break,\n
                    \Type \"INTERRUPTED\" = An interruption. Stop the Pomodoro,\n
                    \Type \"DONE\" = Stop the Pomodoro and mark the task as Done.\n
                    \Your answer? ")
    endwhile

    " Set the Pomodoro state to its original state, that is 'focus' state.
    call SetPomodoroState(s:pomodoro_secret, 1)

    if answer == "YES"
        call SetPomodoroBreakAt(s:pomodoro_secret) " Track break at time
        call SetPomodoroState(s:pomodoro_secret, 2) " Switch to break state

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

    " Temporarily set the status to inactive so that the SetPomodoroState() will
    " stop the Pomodoro timer.
    call SetPomodoroState(s:pomodoro_secret, 0)

    let answer = ''

    while answer != "YES" && answer != "INTERRUPTED" && answer != "DONE"
        redraw
        let answer = input(a:name . " " . a:duration . "m break is over... Feeling rested?\nWant to start another Pomodoro?\n
                    \Type \"YES\" = Yes. I'm ready to continue working on the task,\n
                    \Type \"INTERRUPTED\" = An interruption. Stop the Pomodoro,\n
                    \Type \"DONE\" = Stop the Pomodoro and mark the task as Done.\n
                    \Your answer? ")
    endwhile

    " Set the Pomodoro state to its original state, that is 'break' state.
    call SetPomodoroState(s:pomodoro_secret, 2)

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . s:pomodoro_count . " break ended. " .
                \ "Duration: " . pomodorocommands#calculate_duration(GetPomodoroStartedAt(2), localtime()) . ".")

    if answer == "YES"
        if s:pomodoro_count < 4
            let s:pomodoro_count += 1
        else
            let s:pomodoro_count = 1
        endif
        exec "PomodoroStart " . a:name
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

function! pomodorohandlers#rtm_reset_if_non_rtm_task(the_secret, name)
    if a:the_secret == s:pomodoro_secret && s:key != '' && a:name !=# s:taskname
        let s:taskname = ''
        let s:key = ''
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
let s:key = ''
let s:taskname = ''

" Store RTM list ID, task series ID, and task ID
" taskIDs = {
"            '001': {'lsID': '123', 'tsID': '555', 'ID': '544'},
"            '002': {'lsID': '123', 'tsID': '455', 'ID': '444'}
"            }
let s:taskIDs = {}

" Help text
let s:helpmore = ['"   ===== Hotkeys =====']

if !g:undotree_HelpLine
    let s:helpless = []
else
    let s:helpless = ['" Press ? for help.']
endif

" Keymap
let s:keymap = []
" action, key, help.
let s:keymap += [['Help', '?', 'Toggle quick help']]
let s:keymap += [['Close', 'q', 'Close Vimodoro panel']]
let s:keymap += [['Start', 's', 'Start Working on current task']]

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
    " already focused.
    if winnr == winnr()
        return
    endif
    if winnr == -1
        echoerr "Fatal: window does not exist!"
        return
    endif
    " call s:log("SetFocus() winnr:".winnr." bufname:".self.bufname)
    " wincmd would cause cursor outside window.
    call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>")
endfunction

function! s:panel.IsVisible() abort
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:panel.Hide() abort
    " call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
endfunction

let s:vimodoro = s:new(s:panel)

function! s:vimodoro.Init() abort
    let self.bufname = "vimodoro_".s:getUniqueID()
    " Increase to make it unique.
    let self.height = g:vimodoro_SplitHeight
    let self.targetid = -1
    let self.targetBufnr = -1
    let self.rawtasklist = {}  "data passed from undotree()
    let self.tree = {}     "data converted to internal format.
    let self.seq_last = -1
    let self.save_last = -1
    let self.save_last_bak = -1

    " seqs
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    let self.seq_saved = {} "{saved value -> seq} pair

    "backup, for mark
    let self.seq_cur_bak = -1
    let self.seq_curhead_bak = -1
    let self.seq_newhead_bak = -1

    let self.tasklist = []     "output data.
    let self.showHelp = 0
endfunction

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
    " call s:log("vimodoro.Action() ".a:action)
    if !self.IsVisible() || !exists('b:isVimodoroBuffer')
        echoerr "Fatal: window does not exist."
        return
    endif
    if !has_key(self,'Action'.a:action)
        echoerr "Fatal: Action does not exist!"
        return
    endif
    if a:action == "Start"
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
    call pomodorocommands#logger("g:pomodoro_debug_file", string(s:taskIDs))
    let s:key = matchstr(getline('.'), '^\d\{3}')
    if has_key(s:taskIDs, s:key)
        let s:taskname = '[🐮 ' . substitute(matchstr(getline('.'), '\.\s.*$'), '^\.\s', '', '') . ']'
        let choice = confirm("[" . s:taskname . "]\nWant to start working on the selected task?", "&Yes\n&No")
        if choice == 1
            call self.Toggle()
            exec "PomodoroStart " . s:taskname
            call pomodorocommands#logger("g:pomodoro_debug_file",
                        \ "PomodoroStart [" . s:taskIDs[s:key]['lsID'] . ":" .
                        \ s:taskIDs[s:key]['tsID'] . ":" .
                        \ s:taskIDs[s:key]['ID'] . "]")
        endif
    else
        echohl WarningMsg
        echo "Move the cursor to a task you wish to begin, then press the start key."
        echohl None
    endif
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

    " call s:log(self.bufname." Toggle()")
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
    " call s:log("vimodoro.Show()")
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

function! s:vimodoro.Update() abort
    if !self.IsVisible()
        return
    endif
    " do nothing if we're in the vimodoro panel
    if exists('b:isVimodoroBuffer')
        return
    endif
    if (&bt != '' && &bt != 'acwrite') || (&modifiable == 0) || (mode() != 'n')
        if &bt == 'quickfix' || &bt == 'nofile'
            "Do nothing for quickfix and q:
            " call s:log("vimodoro.Update() ignore quickfix")
            return
        endif
        if self.targetBufnr == bufnr('%') && self.targetid == w:vimodoro_id
            " call s:log("vimodoro.Update() invalid buffer NOupdate")
            return
        endif
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
        " call s:log("vimodoro.Update() invalid buffer update")
    else
        let emptybuf = 0
        "update vimodoro,set focus
        if self.targetBufnr == bufnr('%')
            let self.targetid = w:vimodoro_id
            let newrawtasklist = undotree()
            if self.rawtasklist == newrawtasklist
                return
            endif

            " same buffer, but seq changed.
            if newrawtasklist.seq_last == self.seq_last
                " call s:log("vimodoro.Update() update seqs")
                let self.rawtasklist = newrawtasklist
                "call self.ConvertInput(0) "only update seqs.
                "if (self.seq_cur == self.seq_cur_bak) &&
                "            \(self.seq_curhead == self.seq_curhead_bak)&&
                "            \(self.seq_newhead == self.seq_newhead_bak)&&
                "            \(self.save_last == self.save_last_bak)
                "    return
                "endif
                call self.SetFocus()
                call self.UpdateDiff()
                return
            endif
        endif
    endif
    " call s:log("vimodoro.Update() update whole tree")

    let self.targetBufnr = bufnr('%')
    let self.targetid = w:vimodoro_id
    if emptybuf " Show an empty undo tree instead of do nothing.
        let self.rawtasklist = {'seq_last':0,'entries':[],'time_cur':0,'save_last':0,'synced':1,'save_cur':0,'seq_cur':0}
    else
        let self.rawtasklist = undotree()
    endif
    let self.seq_last = self.rawtasklist.seq_last
    let self.seq_cur = -1
    let self.seq_curhead = -1
    let self.seq_newhead = -1
    "call self.ConvertInput(1) "update all.
    call self.Render()
    call self.SetFocus()
    call self.Draw()
endfunction

" TODO: Print the tasks list and keep track of the list ID, task series ID, and
" task ID per task.
function! s:vimodoro.Render() abort
    let rtmFilter = "dueBefore:tomorrow AND status:incomplete"

    " Insert task list into self.tasklist
    execute "py3 sys.argv = " . "['" . rtmFilter . "']"
    execute "py3file " . s:getTaskList_py
endfunction

function! s:vimodoro.Draw() abort
    " remember the current cursor position.
    let savedview = winsaveview()

    setlocal modifiable
    setlocal textwidth=0
    " Delete text into blackhole register.
    call s:exec('1,$ d _')
    call append(0, self.tasklist)

    call self.AppendHelp()

    "remove the last empty line
    call s:exec('$d _')

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
        if g:undotree_HelpLine
            call append(0,'')
        endif
        call append(0,s:helpless)
    endif
endfunction

function! s:vimodoro.rtm_task_complete() abort
    call pomodorocommands#logger("g:pomodoro_debug_file", "has_key(s:taskIDs, s:key) = " . has_key(s:taskIDs, s:key))
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:taskname = " . s:taskname)
    call pomodorocommands#logger("g:pomodoro_debug_file", "GetPomodoroName() = " . GetPomodoroName())
    call pomodorocommands#logger("g:pomodoro_debug_file", "s:taskname = GetPomodoroName() : " . (GetPomodoroName() == s:taskname))

    if has_key(s:taskIDs, s:key) && GetPomodoroName() == s:taskname
        call pomodorocommands#logger("g:pomodoro_debug_file",
                    \ "py3 sys.argv = " .
                    \ "[\"" . s:taskIDs[s:key]['lsID'] . "\",
                    \ \"" . s:taskIDs[s:key]['tsID'] . "\",
                    \ \"" . s:taskIDs[s:key]['ID'] . "\"]")
        execute "py3 sys.argv = " .
                    \ "[\"" . s:taskIDs[s:key]['lsID'] . "\",
                    \ \"" . s:taskIDs[s:key]['tsID'] . "\",
                    \ \"" . s:taskIDs[s:key]['ID'] . "\"]"
        execute "py3file " . s:setTaskComplete_py
        " TODO: Should check if the mark as done was a success to decide wether
        " or not to reset the s:key variable. Not really sure yet.
    endif

    " This echo has been done in the above python script, but I don't know why
    " it didn't show up or got cleared.
    echo "The task " . GetPomodoroName() . " has been marked as done."

    call PomodoroUninterrupted(s:pomodoro_secret)

    " Re-initiate these two variables to an empty string so that when starting a
    " new task, the task name will be empty and calling this method won't
    " calling the rtm.tasks.complete method since the s:key has been set to
    " blank -- the task was not interrupted, nor still WIP.
    let s:taskname = ''
    let s:key = ''
endfunction

function! s:exec(cmd) abort
    " call s:log("s:exec() ".a:cmd)
    silent exe a:cmd
endfunction

" Don't trigger any events(like BufEnter which could cause redundant refresh)
function! s:exec_silent(cmd) abort
    " call s:log("s:exec_silent() ".a:cmd)
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
    " call s:log("vimodoroAction()")
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
        " call s:log("Unique window id assigned: ".w:vimodoro_id)
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
        " call s:log(">>> VimodoroToggle()")
        if !exists('w:vimodoro_id')
            let w:vimodoro_id = 'id_'.s:getUniqueID()
            " call s:log("Unique window id assigned: ".w:vimodoro_id)
        endif
        if !exists('t:vimodoro')
            let t:vimodoro = s:new(s:vimodoro)
        endif
        call t:vimodoro.Toggle()
        " call s:log("<<< VimodoroToggle() leave")
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

function! pomodorohandlers#VimodoroShow() abort
    try
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
