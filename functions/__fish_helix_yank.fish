function __fish_helix_yank --description 'Helix: yank selection or char under cursor (y)'
    set -g fish_cursor_end_mode exclusive
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection yank end-selection repaint-mode
    else
        # Single char under cursor
        commandline -f begin-selection forward-char kill-selection yank backward-char end-selection repaint-mode
    end
    set -g fish_cursor_end_mode inclusive
    set fish_bind_mode default
end
