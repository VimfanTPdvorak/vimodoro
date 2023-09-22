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


function! pomodorohandlers#pause(name,timer)
    if a:name == ''
        let g:pomodoro_name = '(unnamed)'
    else
        let g:pomodoro_name = a:name
    endif

    call pomodorocommands#notify()

    AirlineRefresh

    if g:pomodoro_count == 4
        let g:pomodoro_count = 1
        let g:pomodoro_break_duration = g:pomodoro_long_break
    else
        let g:pomodoro_break_duration = g:pomodoro_short_break
    endif

    call pomodorocommands#logger("g:pomodoro_debug_file", "g:pomodoro_count = " . g:pomodoro_count)
    call pomodorocommands#logger("g:pomodoro_debug_file", "g:pomodoro_break_duration = " . g:pomodoro_break_duration)

    let choice = confirm("Great, pomodoro " . a:name . " is finished!\nNow, take a break for " .
                \ g:pomodoro_break_duration . " minutes.", "&OK")

    let g:pomodoro_break_at = localtime()
    let g:pomodoro_started = 2

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " #" . g:pomodoro_count .
                \ " ended. Duration: " . pomodorocommands#calculate_duration(g:pomodoro_started_at, localtime()) . ".")
    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " break started.")


    let g:pomodoro_run_timer = timer_start(g:pomodoro_break_duration * 60 * 1000,
                \ function('pomodorohandlers#restart', [a:name, g:pomodoro_break_duration]))
endfunction


function! pomodorohandlers#restart(name, duration, timer)
    call pomodorocommands#notify()

    let g:pomodoro_started = 0

    AirlineRefresh

    let choice = confirm(a:duration .
                \ " minutes break is over... Feeling rested?\nWant to start another pomodoro?",
                \ "&Yes\n&No")

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " break ended. " .
                \ "Duration: " . pomodorocommands#calculate_duration(g:pomodoro_break_at, localtime()) . ".")

    if choice == 1
        if g:pomodoro_count < 4
            let g:pomodoro_count += 1
        endif
        exec "PomodoroStart " . a:name
    endif
endfunction
