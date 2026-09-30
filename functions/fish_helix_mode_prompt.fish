function fish_helix_mode_prompt --description 'Helix-style modal indicator for prompt'
    if test "$fish_key_bindings" != fish_helix_key_bindings
        return
    end

    if set -q fish_helix_show_mode_prompt
        and test "$fish_helix_show_mode_prompt" = false
        return
    end

    set -q fish_helix_mode_prompt_format
    or set -g fish_helix_mode_prompt_format '[%s]'

    switch $fish_bind_mode
        case default
            set_color --bold brblue
            printf $fish_helix_mode_prompt_format 'NOR'
        case insert
            set_color --bold brgreen
            printf $fish_helix_mode_prompt_format 'INS'
        case visual
            set_color --bold brmagenta
            printf $fish_helix_mode_prompt_format 'SEL'
        case helix_replace_one
            set_color --bold bryellow
            printf $fish_helix_mode_prompt_format 'REP'
        case helix_surround_add helix_surround_del helix_surround_rep1 helix_surround_rep2
            set_color --bold brcyan
            printf $fish_helix_mode_prompt_format 'MAT'
        case '*'
            set_color --bold white
            printf $fish_helix_mode_prompt_format '???'
    end
    set_color normal
    echo -n ' '
end
