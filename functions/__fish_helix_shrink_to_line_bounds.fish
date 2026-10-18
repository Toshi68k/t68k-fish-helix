function __fish_helix_shrink_to_line_bounds --description 'Helix: shrink to line bounds (Alt-x)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l buf (commandline -b | string collect)
    set -l lines (string split \n -- "$buf")
    set -l num_lines (count $lines)
    if test $num_lines -eq 0
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

    set -l line_starts
    set -l line_ends
    set -l cur_pos 0
    for i in (seq $num_lines)
        set -a line_starts $cur_pos
        set -l line_len (string length -- "$lines[$i]")
        set -l end_pos (math "$cur_pos + $line_len")
        set -a line_ends $end_pos
        set cur_pos (math "$end_pos + 1")
    end

    set -l L_start 1
    for i in (seq $num_lines)
        if test $min_pos -ge $line_starts[$i]
            set L_start $i
        end
    end

    set -l L_end 1
    for i in (seq $num_lines)
        if test $max_pos -ge $line_starts[$i]
            set L_end $i
        end
    end

    set -l shrunk_start_line $L_start
    if test $min_pos -gt $line_starts[$L_start]
        set shrunk_start_line (math "$L_start + 1")
    end

    set -l shrunk_end_line $L_end
    if test $max_pos -lt $line_ends[$L_end]
        set shrunk_end_line (math "$L_end - 1")
    end

    if test $shrunk_start_line -le $shrunk_end_line -a $shrunk_start_line -le $num_lines -a $shrunk_end_line -ge 1
        set -l new_start $line_starts[$shrunk_start_line]
        set -l new_end $line_ends[$shrunk_end_line]
        set -l diff (math "$new_end - $new_start")

        commandline -f end-selection
        commandline -C $new_start
        commandline -f begin-selection
        for i in (seq $diff)
            commandline -f forward-char
        end
        set fish_bind_mode visual
        commandline -f repaint-mode
    else
        commandline -f end-selection
        set fish_bind_mode default
        commandline -f repaint-mode
    end
end
