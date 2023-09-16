" plugin/pomodoro.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License
" Maintainer: Billy Chamberlain
"
" Vim plugin for the Pomodoro time management technique.
"
" Commands:
"   :PomodoroStart [name]   -   Start a new pomodoro. [name] is optional.
"
" Configuration:
"   g:pomodoro_time_work      -  Duration of a pomodoro
"   g:pomodoro_time_slack     -  Duration of a break
"   g:pomodoro_log_file       -  Path to log file
"   g:pomodoro_icon_inactive  -  Pomodoro inactive icon
"   g:pomodoro_icon_started   -  Pomodoro started icon
"   g:pomodoro_icon_break     -  Pomodoro break icon
"   g:pomodoro_time_format    -  Time on statusbar when pomodoro is inactive.
"   g:pomodoro_timer_duration -  Time on statusbar updated duration.

if &cp || exists("g:pomodoro_loaded") && g:pomodoro_loaded
    finish
endif

let g:pomodoro_loaded = 1
let g:pomodoro_started = 0
let g:pomodoro_started_at = -1
let g:pomodoro_break_at = -1

let g:pomodoro_timer_duration = 15000 "In msec
let g:pomodoro_display_time = 1
let g:pomodoro_time_format =  '%{strftime("%a %b %d, %H:%M:%S")}'
let g:pomodoro_redisplay_status_duration = 2000

let g:airline_section_y = g:pomodoro_time_format

let g:pomodoro_icon_inactive = '🤖'
let g:pomodoro_icon_started = '🍅'
let g:pomodoro_icon_break = '🍕'

if !exists('g:pomodoro_time_work')
    let g:pomodoro_time_work = 25
endif

if !exists('g:pomodoro_time_slack')
    let g:pomodoro_time_slack = 5
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* PomodoroStart call s:PomodoroStart(<q-args>)
command! PomodoroStatus echo PomodoroStatus()

nnoremap <silent><leader>pt
            \ :call PomodoroToggleDisplayTime(g:pomodoro_display_time)<cr>
inoremap <silent><leader>pt
            \ <esc>:call PomodoroToggleDisplayTime(g:pomodoro_display_time)<cr>a

if !exists("g:no_plugin_maps") || g:no_plugin_maps == 0
    nmap <F7> <ESC>:PomodoroStart<CR>
endif

function! PomodoroStatus()
    if g:pomodoro_started == 0
        silent! if exists('g:pomodoro_icon_inactive')
            let the_status =  g:pomodoro_icon_inactive
        else
            let the_status = "Pomodoro inactive"
        endif
    elseif g:pomodoro_started == 1
        silent! if exists('g:pomodoro_icon_started')
            " TODO: Also display WIP task's amount of pomodoros.
            let the_status = g:pomodoro_icon_started
        else
            let the_status = "Pomodoro started"
        endif
        let the_status .= " (Remaining: " . pomodorocommands#remaining_time() . "m)"
    elseif g:pomodoro_started == 2
        silent! if exists('g:pomodoro_icon_break')
            let the_status = g:pomodoro_icon_break
        else
            let the_status = "Pomodoro break started"
        endif
        let the_status .= " (Remaining: " . pomodorocommands#break_remaining_time() . "m)"
    endif

    return the_status
endfunction

function! s:PomodoroStart(name)
    call pomodorocommands#logger("Calling PomodoroStart")
    if g:pomodoro_started != 1
        if a:name == ''
            let name = '(unnamed)'
        else
            let name = a:name
        endif
        let tempTimer = timer_start(g:pomodoro_time_work * 60 * 1000, function('pomodorohandlers#pause', [name]))
        let g:pomodoro_started_at = localtime()
        let g:pomodoro_started = 1
        echom "Pomodoro " . name . " Started at: " . strftime('%I:%M:%S %d/%m/%Y', g:pomodoro_started_at)
        if exists("g:pomodoro_log_file")
            let logFile = g:pomodoro_log_file
            if filereadable(logFile)
                call writefile(["Pomodoro " . name . " Started at " .
                            \ strftime('%I:%M:%S %d/%m/%Y', g:pomodoro_started_at)], logFile, "a")
            endif
        endif
    endif
    if g:pomodoro_display_time == 0
        call pomodorocommands#logger("Set pomodoro_display_time to 1.")
        let g:pomodoro_display_time = 1
        let g:pomodoro_show_time_timer = timer_start(g:pomodoro_timer_duration,
                    \ 's:PomodoroRefreshStatusLine', {'repeat': -1})
    endif
    call pomodorocommands#logger("Set g:airline_section_y to PomodoroStatus.")
    let g:airline_section_y = '%{PomodoroStatus()}'
    AirlineRefresh
endfunction

function! s:PomodoroGetStatus()
    if g:pomodoro_started == 0
        return "inactive"
    elseif g:pomodoro_started == 1
        return "started"
    elseif g:pomodoro_started == 2
        return "break"
    endif
endfunction

function PomodoroToggleDisplayTime(showTime)
    let g:pomodoro_display_time = !a:showTime
    if g:pomodoro_display_time == 1
        let g:airline_section_y = g:pomodoro_time_format
        call pomodorocommands#logger("calling timer_start(g:pomodoro_timer_duration)")
        call s:PomodoroStartsShowTimeTimer(0)
    else
        let g:airline_section_y =
                    \ '%{airline#util#wrap(airline#parts#ffenc(),0)}'
        call pomodorocommands#logger("calling timer_stop(g:pomodoro_show_time_timer)")
        call timer_stop(g:pomodoro_show_time_timer)
        if s:PomodoroGetStatus() !=# "inactive"
            let g:pomodoro_display_time = 1
            let tmpTimer = timer_start(g:pomodoro_redisplay_status_duration,
                        \ 's:PomodoroStartsShowTimeTimer')
        endif
    endif
    AirlineRefresh
endfunc

func s:PomodoroStartsShowTimeTimer(timer)
    call s:PomodoroRefreshStatusLine(0)
    let g:pomodoro_show_time_timer = timer_start(g:pomodoro_timer_duration,
                \ 's:PomodoroRefreshStatusLine',
                \ {'repeat': -1})
endfunction

func s:PomodoroRefreshStatusLine(timer)
    call pomodorocommands#logger("calling s:PomodoroRefreshStatusLine(timer)")
    if g:pomodoro_display_time == 1
        if s:PomodoroGetStatus() == "inactive"
            let g:airline_section_y = g:pomodoro_time_format
        else
            let g:airline_section_y = '%{PomodoroStatus()}'
        endif
        AirlineRefresh
    endif
endfunc

call pomodorocommands#logger("calling timer_start(g:pomodoro_timer_duration) for the first time.")
call s:PomodoroStartsShowTimeTimer(0)
