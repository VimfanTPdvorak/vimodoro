" autoload/pomodorocommands.vim
" Author:   Maximilian Nickel <max@inmachina.com>
" License:  MIT License
" Maintainer: Billy Chamberlain

if exists("g:loaded_autoload_pomodorocommands") || &cp
    " requires nocompatible and clientserver
    " also, don't double load
    finish
endif

let g:loaded_autoload_pomodorocommands = 1

function! pomodorocommands#notify()
    if exists("g:pomodoro_work_end_notification_cmd")
        if g:pomodoro_started == 1 " Pomodoro work done.
            call system(g:pomodoro_work_end_notification_cmd)
        endif
    endif
    if exists("g:pomodoro_break_end_notification_cmd")
        if g:pomodoro_started == 2 " Pomodoro break done.
            call system(g:pomodoro_break_end_notification_cmd)
        endif
    endif
    if exists("g:pomodoro_notification_cmd")
        if g:pomodoro_started == 1 && !exists("g:pomodoro_work_end_notification_cmd") ||
                g:pomodoro_started == 2 && !exists("g:pomodoro_break_end_notification_cmd")
            call system(g:pomodoro_notification_cmd)
        endif
    endif
endfunction

function! pomodorocommands#get_remaining(given_duration, start_at_time)
    let s:time_difference = abs(localtime() - a:start_at_time)
    let s:minutes = (a:given_duration * 60 - s:time_difference) / 60
    let s:seconds = (a:given_duration * 60 - s:time_difference) % 60
    return printf('%dm%ds', s:minutes, s:seconds)
endfunction

function! pomodorocommands#logger(strVarName, msg)
    if exists(a:strVarName)
        let logFile = a:strVarName
        if filereadable(eval(logFile))
            call writefile([strftime("%c") . " - " . a:msg], eval(logFile), "a")
        endif
    endif
endfunction

function! pomodorocommands#calculate_duration(start_time, end_time)
    let s:time_difference = abs(a:end_time - a:start_time)
    let s:minutes = s:time_difference / 60
    let s:seconds = s:time_difference % 60
    return printf('%dm%ds', s:minutes, s:seconds)
endfunction
