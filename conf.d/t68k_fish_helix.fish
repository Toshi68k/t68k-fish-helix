# Initialization for t68k-fish-helix

function t68k_fish_helix_enable --description 'Enable Helix keybindings for fish'
    set -g fish_key_bindings fish_helix_key_bindings
    if status is-interactive
        fish_helix_key_bindings
    end
end

function t68k_fish_helix_disable --description 'Disable Helix keybindings and revert to default'
    set -g fish_key_bindings fish_default_key_bindings
    if status is-interactive
        fish_default_key_bindings
    end
end

# Check if fish_key_bindings is set to helix
if test "$fish_key_bindings" = fish_helix_key_bindings
    and status is-interactive
    fish_helix_key_bindings
end

# Auto-detect modern prompt frameworks (Tide, Starship, Hydro, Pure)
if not set -q fish_helix_show_mode_prompt
    if functions -q _tide_item_vi_mode; or type -q starship; or functions -q hydro
        # Modern prompt engines manage modal display or require clean fish_mode_prompt
        set -g fish_helix_show_mode_prompt false
    else
        set -g fish_helix_show_mode_prompt true
    end
end

# Atuin integration settings ('auto', true, false)
if not set -q fish_helix_atuin
    set -g fish_helix_atuin auto
end

if not set -q fish_helix_atuin_up
    set -g fish_helix_atuin_up false
end

# Provide prompt integration if user enables it or if default fish_mode_prompt is used
if not functions -q __fish_helix_original_mode_prompt
    if functions -q fish_mode_prompt
        functions -c fish_mode_prompt __fish_helix_original_mode_prompt
    end
end

function fish_mode_prompt --description 'Helix-aware mode prompt'
    if test "$fish_key_bindings" = fish_helix_key_bindings
        if test "$fish_helix_show_mode_prompt" = true
            fish_helix_mode_prompt
        end
    else if functions -q __fish_helix_original_mode_prompt
        __fish_helix_original_mode_prompt
    end
end

# Uninstall handler for fisher / omf
function _t68k_fish_helix_uninstall --on-event t68k_fish_helix_uninstall
    if test "$fish_key_bindings" = fish_helix_key_bindings
        t68k_fish_helix_disable
    end
    functions -e t68k_fish_helix_enable
    functions -e t68k_fish_helix_disable
    functions -e _t68k_fish_helix_uninstall
end
