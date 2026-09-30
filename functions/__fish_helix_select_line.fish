function __fish_helix_select_line --description 'Helix: select line or extend line below (x)'
    set -l is_selected 0
    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
    end

    if test $is_selected -eq 1
        # Selection already active: extend line down
        commandline -f end-of-line forward-char end-of-line repaint-mode
    else
        # Select current line
        commandline -f beginning-of-line begin-selection end-of-line repaint-mode
    end

    set fish_bind_mode visual
end
