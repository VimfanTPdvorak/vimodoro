" Avoid installing twice.
if exists('g:autoloaded_vimodoro')
    finish
endif

let g:autoloaded_vimodoro = 0

let s:rtmREST = "https://api.rememberthemilk.com/services/rest/"

let s:plugin_root = expand("<sfile>:h:h")
let s:getTaskList_py = s:plugin_root . "/py/getTaskList.py"

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
    let self.taskIDs = []       "Store RTM list ID, task series ID, and task ID
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
    silent exec 'call self.Action'.a:action.'()'
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
    call pomodorocommands#logger("g:pomodoro_debug_file", join(self.taskIDs, ', '))
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
            exec "au! ".auEvents." * call vimodoro#VimodoroUpdate()"
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
    setlocal statusline=%!t:vimodoro.GetStatusLine()
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

function! s:vimodoro.Index2Screen(index) abort
    " index starts from zero
    let index_padding = 1
    let empty_line = 1
    let lineNr = a:index + index_padding + empty_line
    " calculate line number according to the help text.
    " index starts from zero and lineNr starts from 1
    if self.showHelp
        let lineNr += len(s:keymap) + len(s:helpmore)
    else
        let lineNr += len(s:helpless)
        if !g:vimodoro_HelpLine
            let lineNr -= empty_line
        endif
    endif
    return lineNr
endfunction

" <0 if index is invalid. e.g. current line is in help text.
function! s:vimodoro.Screen2Index(line) abort
    let index_padding = 1
    let empty_line = 1
    let index = a:line - index_padding - empty_line

    if self.showHelp
        let index -= len(s:keymap) + len(s:helpmore)
    else
        let index -= len(s:helpless)
        if !g:vimodoro_HelpLine
            let index += empty_line
        endif
    endif
    return index
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

function! vimodoro#VimodoroUpdate() abort
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

function! vimodoro#VimodoroToggle() abort
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

function! vimodoro#VimodoroIsVisible() abort
    return (exists('t:vimodoro') && t:vimodoro.IsVisible())
endfunction

function! vimodoro#VimodoroHide() abort
    if vimodoro#VimodoroIsVisible()
        try
            call vimodoro#VimodoroToggle()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    endif
endfunction

function! vimodoro#VimodoroShow() abort
    try
        if ! vimodoro#VimodoroIsVisible()
            call vimodoro#VimodoroToggle()
        else
            call t:vimodoro.SetFocus()
        endif
    catch /^Vim\%((\a\+)\)\?:E11/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
endfunction

function! vimodoro#VimodoroFocus() abort
    if vimodoro#VimodoroIsVisible()
        try
            call t:vimodoro.SetFocus()
        catch /^Vim\%((\a\+)\)\?:E11/
            echohl ErrorMsg
            echom v:exception
            echohl NONE
        endtry
    endif
endfunction
