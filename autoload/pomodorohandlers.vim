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
        let name = '(unnamed)'
    else
        let name = a:name
    endif

    call pomodorocommands#notify()

    AirlineRefresh

    let choice = confirm("Great, pomodoro " . a:name . " is finished!\nNow, take a break for " .
                \ g:pomodoro_time_slack . " minutes", "&OK")

    let g:pomodoro_break_at = localtime()
    let g:pomodoro_started = 2

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " ended. Duration: " .
                \ g:pomodoro_time_work . " minutes.")
    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " break started.")

    let tempTimer = timer_start(g:pomodoro_time_slack * 60 * 1000,
                \ function('pomodorohandlers#restart', [name]))
endfunction


function! pomodorohandlers#restart(name,timer)
    let g:pomodoro_started = 0

    call pomodorocommands#notify()

    AirlineRefresh

    let choice = confirm(g:pomodoro_time_slack .
                \ " minutes break is over... Feeling rested?\nWant to start another pomodoro?",
                \ "&Yes\n&No")

    call pomodorocommands#logger("g:pomodoro_log_file", "Pomodoro " . a:name . " break ended. " .
                \ "Duration: " . g:pomodoro_time_slack . " minutes.")

    if choice == 1
        exec "PomodoroStart " . a:name
    endif
endfunction
