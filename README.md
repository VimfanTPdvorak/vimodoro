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
new pomodoro.  The parameter `pomodoro_name` is optional. After a pomodoro has
ended, a confirmation dialog will remind you to take a break. When the break has
ended, another dialog will ask you if you want to start a new pomodoro.
Furthermore, the remaining time of a pomodoro can be displayed in the statusline
of vim.

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
Remaining time displayed in statusline

![Remaining Time](http://dl.dropbox.com/u/531773/vim-pomodoro/vim-pomodoro-remaining.png)

Pomodoro finished, let's take a break!

![Pomodoro Finished](http://dl.dropbox.com/u/531773/vim-pomodoro/vim-pomodoro-finished.png)

Take another turn?

![Pomodoro Restart](http://dl.dropbox.com/u/531773/vim-pomodoro/vim-pomodoro-break.png)

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


### Bells and Whistles
Notifications outside vim can be enabled through the option `g:pomodoro_notification_cmd`.
For instance, to play a soundfile after each completed pomodoro or break, add something like

    let g:pomodoro_notification_cmd = "mpg123 -q ~/.vim/pomodoro-notification.mp3"

to your `~/.vimrc`. System-wide notifications can, for instance, be done via zenity and
the option

    let g:pomodoro_notification_cmd = 'zenity --notification --text="Pomodoro finished"''

Installation
------------
Use your favorite plugin manager such as pathogen.
