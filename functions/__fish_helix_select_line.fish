function __fish_helix_select_line --description 'Helix: select line or extend line below (x)'
    set -l count (__fish_helix_consume_count)
    set -l is_selected 0
    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
    end

    if test $is_selected -eq 1
        # Selection already active: extend line down by count lines
        for i in (seq $count)
            commandline -f end-of-line forward-char end-of-line
        end
    else
        # Select current line and extend if count > 1
        commandline -f beginning-of-line begin-selection end-of-line
        if test $count -gt 1
            for i in (seq (math $count - 1))
                commandline -f end-of-line forward-char end-of-line
            end
        end
    end

    set fish_bind_mode visual
    commandline -f repaint-mode
end
