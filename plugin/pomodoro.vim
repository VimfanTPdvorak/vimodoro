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
"   g:pomodoro_work_duration           -  Duration of a pomodoro
"   g:pomodoro_short_break             -  Duration of a break
"   g:pomodoro_log_file                -  Path to log file
"   g:pomodoro_icon_inactive           -  Pomodoro inactive icon
"   g:pomodoro_icon_started            -  Pomodoro started icon
"   g:pomodoro_icon_break              -  Pomodoro break icon
"   g:pomodoro_time_format             -  Time format display on statusbar.
"   g:pomodoro_status_refresh_duration -  Pomodoro/time refresh duration in second.

if &cp || exists("g:pomodoro_loaded") && g:pomodoro_loaded
    finish
endif

call pomodorocommands#logger("g:pomodoro_debug_file", "Loading pomodoro...")

" User configurable variables

let g:pomodoro_time_format =  '%{strftime("%a %b %d, %H:%M:%S")}'
let g:pomodoro_redisplay_status_duration = 2000
let g:pomodoro_status_refresh_duration = 15 " In second

let g:pomodoro_icon_inactive = '🤖'
let g:pomodoro_icon_started = '🍅'
let g:pomodoro_icon_break = '🍕'

if !exists('g:pomodoro_work_duration')
    let g:pomodoro_work_duration = 25
endif

if !exists('g:pomodoro_short_break')
    let g:pomodoro_short_break = 5
endif

if !exists('g:pomodoro_long_break')
    let g:pomodoro_long_break = 15
endif

" Variables should not be touched by users

let s:pomodoro_secret = rand()

call pomodorohandlers#get_secret(s:pomodoro_secret)

let g:pomodoro_break_duration = g:pomodoro_short_break
let g:pomodoro_name = ''
let g:pomodoro_interrupted = 0

let g:pomodoro_loaded = 1
let g:pomodoro_started = 0
let g:pomodoro_started_at = -1
let g:pomodoro_break_at = -1

let g:pomodoro_display_time = 1
let s:pomodoro_timer_duration = g:pomodoro_status_refresh_duration * 1000 "In msec

" TODO: Should make it configurable so that section_y can be use for something
" else, and be more flexible where user wanted to display the Pomodoro status.
let g:airline_section_y = g:pomodoro_time_format

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* PomodoroStart call s:PomodoroStart(<q-args>)
command! PomodoroStatus echo PomodoroStatus(1)

" If the last running task was forced stopped or interrupted, then pressing `<leader>ps` will prompt for restarting
" the last interrupted task.
nnoremap <leader>ps :PomodoroStart <C-R>=g:pomodoro_interrupted == 1 ? g:pomodoro_name : ''<CR>
inoremap <leader>ps <Esc>li<C-g>u<Esc>l:PomodoroStart <C-R>=g:pomodoro_interrupted == 1 ? g:pomodoro_name : ''<CR>

nnoremap <silent><leader>pt
            \ :call PomodoroToggleDisplayTime(g:pomodoro_display_time)<cr>
inoremap <silent><leader>pt
            \ <esc>:call PomodoroToggleDisplayTime(g:pomodoro_display_time)<cr>a
nnoremap <silent><leader>pm :call PomodoroDisplayTime()<cr>
inoremap <silent><leader>pm <esc>:call PomodoroDisplayTime()<cr>a
nnoremap <silent><leader>pf :call PomodoroStop()<CR>
inoremap <silent><leader>pf <Esc>:call PomodoroStop()<CR>a

if !exists("g:no_plugin_maps") || g:no_plugin_maps == 0
    nmap <F7> <ESC>:PomodoroStart<CR>
endif

function! PomodoroStatus(full)
    if g:pomodoro_started == 0
        silent! if exists('g:pomodoro_icon_inactive')
            let the_status =  g:pomodoro_icon_inactive
        else
            let the_status = "Pomodoro inactive"
        endif
    elseif g:pomodoro_started == 1
        silent! if exists('g:pomodoro_icon_started')
            let the_status = repeat(g:pomodoro_icon_started, pomodorohandlers#get_pomodoro_count()) . " "
        else
            let the_status = "Pomodoro started"
        endif
        let the_status .= pomodorocommands#get_remaining(g:pomodoro_work_duration, g:pomodoro_started_at)
    elseif g:pomodoro_started == 2
        silent! if exists('g:pomodoro_icon_break')
            let the_status = repeat(g:pomodoro_icon_break, pomodorohandlers#get_pomodoro_count()) . " "
        else
            let the_status = "Pomodoro break started"
        endif
        let the_status .= pomodorocommands#get_remaining(g:pomodoro_break_duration, g:pomodoro_break_at)
    endif

    if a:full
        let the_status = g:pomodoro_name . " " .the_status
    endif

    return the_status
endfunction

function! s:PomodoroStart(name)
    call pomodorocommands#logger("g:pomodoro_debug_file", "Calling PomodoroStart")
    if g:pomodoro_started == 0 " Pomodoro Inactive
        call s:PomodoroGo(a:name)
    else
        let choice = confirm("Do you really wanted to stop the current running Pomodoro and start a new one?", "&Yes\n&No")
        if choice == 1
            call pomodorohandlers#reset_pomodoro_count(s:pomodoro_secret)
            call timer_stop(g:pomodoro_run_timer)
            call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . g:pomodoro_name . " #" . pomodorohandlers#get_pomodoro_count() .
                        \ " focus stopped. Duration: " .
                        \ pomodorocommands#calculate_duration(g:pomodoro_started_at, localtime()) . ".")

            call s:PomodoroGo(a:name)
        endif
    endif
endfunction

function! s:PomodoroGo(name)
    if a:name == ''
        let g:pomodoro_name = '[Miscellaneous Task]'
    else
        let g:pomodoro_name = a:name
    endif

    let g:pomodoro_run_timer = timer_start(g:pomodoro_work_duration * 60 * 1000, function('pomodorohandlers#pause', [a:name]))
    let g:pomodoro_started_at = localtime()
    let g:pomodoro_started = 1

    echom "Pomodoro " . g:pomodoro_name . " #" . pomodorohandlers#get_pomodoro_count() . " started at: " . strftime('%c', g:pomodoro_started_at)

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . g:pomodoro_name . " #" . pomodorohandlers#get_pomodoro_count() . " focus started.")

    if g:pomodoro_display_time == 0
        call pomodorocommands#logger("g:pomodoro_debug_file", "Set pomodoro_display_time to 1.")
        let g:pomodoro_display_time = 1
        let g:pomodoro_show_time_timer = timer_start(s:pomodoro_timer_duration,
                    \ 's:PomodoroRefreshStatusLine', {'repeat': -1})
    endif

    call pomodorocommands#logger("g:pomodoro_debug_file", "Set g:airline_section_y to PomodoroStatus.")

    let g:airline_section_y = '%{PomodoroStatus(0)}'

    AirlineRefresh
endfunction

function! g:PomodoroStop()
    if g:pomodoro_started != 0 " Pomodoro Active (Started/Break)
        let choice = confirm("Do you want to stop the running Pomodoro?", "&Yes\n&No")
        if choice == 1
            call timer_stop(g:pomodoro_run_timer)
            let g:airline_section_y = g:pomodoro_time_format
            call s:PomodoroStartsShowTimeTimer(0)
            if g:pomodoro_started == 1 " Started (Focus mode)
                call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . g:pomodoro_name . " #" . pomodorohandlers#get_pomodoro_count() .
                            \ " focus stopped. Duration: " .
                            \ pomodorocommands#calculate_duration(g:pomodoro_started_at, localtime()) . ".")
            else " The g:pomodoro_started == 2 (break mode)
                call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . g:pomodoro_name . " #" . pomodorohandlers#get_pomodoro_count() .
                            \ " break stopped. Duration: " .
                            \ pomodorocommands#calculate_duration(g:pomodoro_break_at, localtime()) . ".")
            endif
            let g:pomodoro_started = 0
            call pomodorohandlers#reset_pomodoro_count(s:pomodoro_secret)
            let g:pomodoro_interrupted = 1
        endif
    endif
endfunction

" Toggle display time/file format when Pomodoro is inactive, or toggle between
" display Pomodoro status/file format for g:pomodoro_redisplay_status_duration
" milliseconds then back to Pomodoro status if Pomodoro is running.
function! PomodoroToggleDisplayTime(showTime)
    let g:pomodoro_display_time = !a:showTime
    if g:pomodoro_display_time == 1
        let g:airline_section_y = g:pomodoro_time_format
        call pomodorocommands#logger("g:pomodoro_debug_file", "calling timer_start(s:pomodoro_timer_duration)")
        call s:PomodoroStartsShowTimeTimer(0)
    else
        let g:airline_section_y =
                    \ '%{airline#util#wrap(airline#parts#ffenc(),0)}'
        call pomodorocommands#logger("g:pomodoro_debug_file", "calling timer_stop(g:pomodoro_show_time_timer)")
        call timer_stop(g:pomodoro_show_time_timer)
        if g:pomodoro_started != 0
            let g:pomodoro_display_time = 1
            let tmpTimer = timer_start(g:pomodoro_redisplay_status_duration,
                        \ 's:PomodoroStartsShowTimeTimer')
        endif
    endif
    AirlineRefresh
endfunc

" Toggle display time for g:pomodoro_redisplay_status_duration milliseconds when
" Pomodoro is running or when status line is displaying file encoding.
function! PomodoroDisplayTime()
    if g:pomodoro_display_time != 1 || g:pomodoro_started > 0
        call pomodorocommands#logger("g:pomodoro_debug_file", "Executing PomodoroDisplayTime()")
        let g:airline_section_y = g:pomodoro_time_format
        call timer_stop(g:pomodoro_show_time_timer)
        let tmpTimer = timer_start(g:pomodoro_redisplay_status_duration,
                    \ 's:PomodoroStartsShowTimeTimer')
        AirlineRefresh
    endif
endfunction

function! s:PomodoroStartsShowTimeTimer(timer)
    call s:PomodoroRefreshStatusLine(0)
    let g:pomodoro_show_time_timer = timer_start(s:pomodoro_timer_duration,
                \ 's:PomodoroRefreshStatusLine',
                \ {'repeat': -1})
endfunction

function! s:PomodoroRefreshStatusLine(timer)
    call pomodorocommands#logger("g:pomodoro_debug_file", "calling s:PomodoroRefreshStatusLine(timer)")
    if g:pomodoro_display_time == 1
        if g:pomodoro_started == 0
            let g:airline_section_y = g:pomodoro_time_format
        else
            let g:airline_section_y = '%{PomodoroStatus(0)}'
        endif
        AirlineRefresh
    endif
endfunc

call pomodorocommands#logger("g:pomodoro_debug_file",
            \ "calling timer_start(s:pomodoro_timer_duration) for the first time.")
call s:PomodoroStartsShowTimeTimer(0)
