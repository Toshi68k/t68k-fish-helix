function __fish_helix_change --description 'Helix: change selection or char under cursor (c)'
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection end-selection repaint-mode
    else
        commandline -f delete-char repaint-mode
    end
    set fish_bind_mode insert
end

function __fish_helix_change_noyank --description 'Helix: change without yanking (Alt-c)'
    __fish_helix_delete_noyank
    set fish_bind_mode insert
end
