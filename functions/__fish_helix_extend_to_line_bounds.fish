function __fish_helix_extend_to_line_bounds --description 'Helix: extend to line bounds (X)'
    if not commandline --selection-start >/dev/null 2>&1
        commandline -f begin-selection
    end
    commandline -f beginning-of-line swap-selection-start-stop end-of-line repaint-mode
    set fish_bind_mode visual
end
