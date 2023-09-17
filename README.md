vim-pomodoro
============

vim-pomodoro is a [Vim](http://www.vim.org) plugin for the [Pomodoro time management technique](http://www.pomodorotechnique.com/).

This Vim-Pomodoro plugin originated from [adelarsq](https://github.com/adelarsq/vim-pomodoro), which in turn originated
from [mnick/vim-pomodoro](https://github.com/mnick/vim-pomodoro).

This is my first time working on a Vim plugin, so I forked mnick's Vim-Pomodoro
and added the modified version from Adelarsq's in order to keep track of the
complete changes history within this repository for learning purposes and to
show appreciation for their work.

Usage
-----
The usage of vim-pomodoro is simple. `:PomodoroStart [pomodoro_name]` starts a
new Pomodoro. The parameter `pomodoro_name` is optional. After a Pomodoro has
ended, a confirmation will remind you to take a break. When the break has ended,
it will prompt you if you wish to start a new Pomodoro.

Also, in addition to the default notifications inside vim, vim-pomodoro allows
you to add further external notifications, such as sounds, system-notification
popups etc.

Currently, this version of Vim-Pomodoro is solely dependent on the [Vim-Airline](https://github.com/vim-airline/vim-airline)
plugin. Once the plugin installed, it will display current time in the
`g:airline_section_y` statusline. To toggle that section to display the
currently opened file encoding[fileformat] type `<leader>pt`.

If the Pomodoro has been running, then executing the toggle will display the
file encoding within approximately two seconds, followed by the Pomodoro status
being displayed again.

Screenshots
-----------
The current time is displayed in the `g:airline_section_y` section if Pomodoro
has not activated yet, either started or break.

![Current Time](img/ShowCurrentTime.png)

Started remaining time displayed in statusline

![Started Remaining Time](img/StartedRemainingTime.png)

Break remaining time displayed in statusline

![Break Remaining Time](img/BreakRemainingTime.png)

Pomodoro finished, let's take a break!

![Pomodoro Finished](img/LetsTakeABreak.png)

Take another turn?

![Pomodoro Restart](img/PomodoroRestart.png)

Configuration
-------------
Add the following options to your `~/.vimrc` to configure vim-pomodoro

    " Duration of a pomodoro in minutes (default: 25)
    let g:pomodoro_time_work = 25

    " Duration of a break in minutes (default: 5)
    let g:pomodoro_time_slack = 5

    " Path to the pomodoro log file (default: not defined)
    let g:pomodoro_log_file = "/tmp/pomodoro.log"

    " Path to the pomodoro debug log file (default: not defined)
    let g:pomodoro_debug_file = "/tmp/pomodoro.debug.log"

    " Pomodoro started icon (default: "🍅")
    let g:pomodoro_icon_started = "🍅"

    " Pomodoro break icon (default: "🍕")
    let g:pomodoro_icon_break = "🍕"

    " Pomodoro status/time updates duration in second (default: 15)
    let g:pomodoro_status_refresh_duration = 15

    " Time format display on statusbar (default:'%{strftime("%a %b %d, %H:%M:%S")}')
    let g:pomodoro_time_format = '%{strftime("%a %b %d, %H:%M:%S")}'

    " Display time for n milliseconds then followed by Pomodoro status being displayed again,
    " or display file format for n milliseconds then back to display Pomodoro status.
    let g:pomodoro_redisplay_status_duration = 2000


### Bells and Whistles
Notifications outside vim can be enabled through the option `g:pomodoro_notification_cmd`.
For instance, to play a soundfile after each completed pomodoro or break, add something like

    let g:pomodoro_notification_cmd = "mpg123 -q ~/.vim/pomodoro-notification.mp3"

to your `~/.vimrc`. System-wide notifications can, for instance, be done via zenity and
the option

    let g:pomodoro_notification_cmd = 'zenity --notification --text="Pomodoro finished"''

You can also use `g:pomodoro_work_end_notification_cmd` and `g:pomodoro_break_end_notification_cmd`
that will be executed exclusively when work is done and when a break is done.  For instance,
users on macOS can define the two variables like this:

    let g:pomodoro_work_end_notification_cmd = "say 'Pomodoro focus time has ended.'"
    let g:pomodoro_break_end_notification_cmd = "say 'Pomodoro break time has ended.'"

The `g:pomodoro_notification_cmd` will be executed when either work or break
time has ended, provided the specific notification variable is not set.

Installation
------------
Use your favorite plugin manager such as pathogen.
