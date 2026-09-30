function __fish_helix_replace_with_yanked --description 'Helix: replace selection or char with yanked text (R)'
    set -l is_selected 0
    set -l len 1
    set -l pos (commandline -C)

    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l max_pos (math "max($start, $end)")
        set len (math "$max_pos - $min_pos")
        if test $len -eq 0
            set len 1
        end
        set pos $min_pos
        commandline -f end-selection
    end

    commandline -C $pos
    for i in (seq $len)
        commandline -f delete-char
    end
    commandline -f yank repaint-mode
    set fish_bind_mode default
end
