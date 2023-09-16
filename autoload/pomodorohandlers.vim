" autoload/pomodorohandlers.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License
" Maintainer: Adelar da Silva Queiróz

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

    let choice = confirm("Great, pomodoro " . a:name . " is finished!\nNow, take a break for " .
                \ g:pomodoro_time_slack . " minutes", "&OK")

    let g:pomodoro_break_at = localtime()
    let g:pomodoro_started = 2

    if exists("g:pomodoro_log_file")
        let logFile = g:pomodoro_log_file
        if filereadable(logFile)
            call writefile(["Pomodoro " . a:name . " ended at " .
                        \ strftime("%c") . ", duration: " .
                        \ g:pomodoro_time_work . " minutes"], logFile, "a")
            call writefile(["Pomodoro " . a:name . " break started at " .
                        \ strftime('%I:%M:%S %d/%m/%Y', g:pomodoro_break_at)], logFile, "a")
        endif
    endif

    let tempTimer = timer_start(g:pomodoro_time_slack * 60 * 1000,
                \ function('pomodorohandlers#restart', [name]))
endfunction


function! pomodorohandlers#restart(name,timer)
    let g:pomodoro_started = 0

    call pomodorocommands#notify()

    let choice = confirm(g:pomodoro_time_slack .
                \ " minutes break is over... Feeling rested?\nWant to start another pomodoro?",
                \ "&Yes\n&No")

    if exists("g:pomodoro_log_file")
        let logFile = g:pomodoro_log_file
        if filereadable(logFile)
            call writefile(["Pomodoro " . a:name . " break ended at " .
                        \ strftime("%c") . ", duration: " .
                        \ g:pomodoro_time_slack . " minutes"], logFile, "a")
        endif
    endif

    if choice == 1
        exec "PomodoroStart"
    endif
endfunction
