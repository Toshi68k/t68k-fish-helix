function __fish_helix_delete --description 'Helix: delete selection or char under cursor (d)'
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection end-selection repaint-mode
    else
        commandline -f delete-char repaint-mode
    end
    set fish_bind_mode default
end

function __fish_helix_delete_noyank --description 'Helix: delete selection without yanking (Alt-d)'
    if commandline --selection-start >/dev/null 2>&1
        # To delete without overwriting kill ring, delete each char
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l len (math "abs($end - $start)")
        if test $len -eq 0
            set len 1
        end
        commandline -f end-selection
        for i in (seq $len)
            commandline -f delete-char
        end
        commandline -f repaint-mode
    else
        commandline -f delete-char repaint-mode
    end
    set fish_bind_mode default
end
