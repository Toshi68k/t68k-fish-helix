function __fish_helix_trim_selection --description 'Helix: trim whitespace from active selection (_)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l buf (string join \n -- (commandline -b))
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

    # In inclusive mode, sel_end is max_pos + 1 (exclusive)
    set -l last_pos
    if test "$fish_cursor_selection_mode" = exclusive
        set last_pos $max_pos
    else
        set last_pos (math "$max_pos - 1")
    end

    # Advance min_pos past leading whitespace
    while test $min_pos -le $last_pos
        set -l ch (string sub -s (math $min_pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set min_pos (math $min_pos + 1)
    end

    # Retreat last_pos past trailing whitespace
    while test $last_pos -ge $min_pos
        set -l ch (string sub -s (math $last_pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set last_pos (math $last_pos - 1)
    end

    if test $min_pos -gt $last_pos
        # Selection was purely whitespace: collapse selection
        commandline -f end-selection
        commandline -C $min_pos
        commandline -f repaint-mode
        return
    end

    set -l diff (math "$last_pos - $min_pos")
    commandline -f end-selection
    commandline -C $min_pos
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end
