function __fish_helix_ensure_forward_selection --description 'Helix: ensure selection direction is forward (Alt+:)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l cursor (commandline -C)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

    # If cursor is at min_pos and selection spans more than 1 char, selection is backward
    if test "$cursor" = "$min_pos" -a "$max_pos" -gt "$min_pos"
        commandline -f swap-selection-start-stop repaint-mode
    end
end
