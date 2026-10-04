#!/usr/bin/env fish
# Test suite for t68k-fish-helix

set -l script_path (status filename)
set -l test_dir (path dirname (path resolve $script_path))
set -l plugin_dir (path dirname $test_dir)

set -g passed 0
set -g failed 0

function assert_equal --argument-names actual expected message
    if test "$actual" = "$expected"
        set -g passed (math $passed + 1)
        set_color green
        echo "  ✓ PASS: $message"
        set_color normal
    else
        set -g failed (math $failed + 1)
        set_color red
        echo "  ✗ FAIL: $message"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        set_color normal
    end
end

function assert_contains --argument-names haystack needle message
    if string match -q "*$needle*" -- "$haystack"
        set -g passed (math $passed + 1)
        set_color green
        echo "  ✓ PASS: $message"
        set_color normal
    else
        set -g failed (math $failed + 1)
        set_color red
        echo "  ✗ FAIL: $message"
        echo "    String did not contain '$needle'"
        echo "    Actual string: '$haystack'"
        set_color normal
    end
end

echo "=== Testing t68k-fish-helix Keybindings & Helix Authenticity ==="
echo

# 1. Source all plugin functions
for f in $plugin_dir/functions/*.fish
    source $f
end
source $plugin_dir/conf.d/t68k_fish_helix.fish

# 2. Activate keybindings
fish_helix_key_bindings default

# 3. Verify Helix vs Vim Differences
echo "--- Testing Core Helix Philosophy vs Vim Regressions ---"

# x MUST select line in Helix, NEVER delete character like Vim
set -l bind_x (bind -M default x | string trim)
assert_contains "$bind_x" "__fish_helix_select_line" "x in normal mode selects line (Helix), NOT delete-char (Vim)"

# % MUST select buffer in Helix, NEVER jump bracket like Vim
set -l bind_percent (bind -M default % | string trim)
assert_contains "$bind_percent" "begin-selection" "% in normal mode selects buffer (Helix), NOT jump bracket (Vim)"

# mm jumps matching bracket in Helix (Vim uses %)
set -l bind_mm (bind -M default m,m | string trim)
assert_contains "$bind_mm" "jump-to-matching-bracket" "mm in normal mode jumps matching bracket (Helix)"

# Undo / Redo: u is undo, U is redo (Helix)
set -l bind_u (bind -M default u | string trim)
assert_contains "$bind_u" "undo" "u is undo"
set -l bind_U (bind -M default U | string trim)
assert_contains "$bind_U" "redo" "U is redo (Helix), NOT vim Ctrl-r"

# Selection collapse: ; collapses selection in Helix
set -l bind_semi (bind -M default ';' | string trim)
assert_contains "$bind_semi" "end-selection" "; collapses selection (Helix)"

# Selection flip: Alt-; flips selection direction in Helix
set -l bind_alt_semi (bind -M default \e\; | string trim)
assert_contains "$bind_alt_semi" "swap-selection-start-stop" "Alt-; swaps selection head and anchor (Helix)"

# Goto mode: gh is line start, gl is line end (Helix)
set -l bind_gh (bind -M default g,h | string trim)
assert_contains "$bind_gh" "beginning-of-line" "gh goes to line start (Helix)"

set -l bind_gl (bind -M default g,l | string trim)
assert_contains "$bind_gl" "end-of-line" "gl goes to line end (Helix)"

set -l bind_gs (bind -M default g,s | string trim)
assert_contains "$bind_gs" "__fish_helix_goto_first_nonwhitespace" "gs goes to first non-whitespace (Helix)"

set -l bind_gg (bind -M default g,g | string trim)
assert_contains "$bind_gg" "beginning-of-buffer" "gg goes to start of buffer (Helix)"

set -l bind_ge (bind -M default g,e | string trim)
assert_contains "$bind_ge" "end-of-buffer" "ge goes to end of buffer (Helix)"

# Replace with yanked: R
set -l bind_R (bind -M default R | string trim)
assert_contains "$bind_R" "__fish_helix_replace_with_yanked" "R replaces with yanked text (Helix)"

# Selection-first delete (d) and change (c)
set -l bind_d (bind -M default d | string trim)
assert_contains "$bind_d" "__fish_helix_delete" "d operates on selection/char (Helix selection-first)"

set -l bind_c (bind -M default c | string trim)
assert_contains "$bind_c" "__fish_helix_change" "c changes selection/char into insert mode (Helix)"

# Space mode bindings
set -l bind_sp_y (bind -M default ' ',y | string trim)
assert_contains "$bind_sp_y" "fish_clipboard_copy" "<space>y copies to clipboard (Helix Space mode)"

set -l bind_sp_p (bind -M default ' ',p | string trim)
assert_contains "$bind_sp_p" "fish_clipboard_paste" "<space>p pastes from clipboard (Helix Space mode)"

# Search / History in Normal mode
set -l bind_slash (bind -M default / | string trim)
assert_contains "$bind_slash" "__fish_helix_history_search" "/ in normal mode invokes history search dispatcher"

set -l bind_qmark (bind -M default \? | string trim)
assert_contains "$bind_qmark" "__fish_helix_history_search" "? in normal mode invokes history search dispatcher"

set -l bind_ctrl_r (bind -M default ctrl-r | string trim)
assert_contains "$bind_ctrl_r" "__fish_helix_history_search" "Ctrl-r in normal mode invokes history search dispatcher"

set -l bind_sp_b (bind -M default ' ',b | string trim)
assert_contains "$bind_sp_b" "__fish_helix_history_search" "<space>b in normal mode invokes history search dispatcher"

set -l bind_n (bind -M default n | string trim)
assert_contains "$bind_n" "history-search-backward" "n in normal mode searches history backward (Helix search_next)"

set -l bind_N (bind -M default N | string trim)
assert_contains "$bind_N" "history-search-forward" "N in normal mode searches history forward (Helix search_prev)"

# Insert mode history search (Ctrl-r) & Up arrow
set -l bind_ins_ctrl_r (bind -M insert ctrl-r | string trim)
assert_contains "$bind_ins_ctrl_r" "__fish_helix_history_search" "Ctrl-r in insert mode invokes history search dispatcher"

set -l bind_ins_up (bind -M insert up | string trim)
assert_contains "$bind_ins_up" "__fish_helix_up" "Up in insert mode invokes up dispatcher"

# Insert mode transitions
set -l bind_i (bind -M default i | string trim)
assert_contains "$bind_i" "insert" "i enters insert mode"

set -l bind_a (bind -M default a | string trim)
assert_contains "$bind_a" "forward-char" "a appends after cursor"

set -l bind_I (bind -M default I | string trim)
assert_contains "$bind_I" "beginning-of-line" "I inserts at beginning of line"

set -l bind_A (bind -M default A | string trim)
assert_contains "$bind_A" "end-of-line" "A inserts at end of line"

# Insert mode deletion keys
set -l bind_bs (bind -M insert backspace | string trim)
assert_contains "$bind_bs" "backward-delete-char" "backspace in insert mode deletes char backward"

set -l bind_del (bind -M insert delete | string trim)
assert_contains "$bind_del" "delete-char" "delete in insert mode deletes char forward"

set -l bind_cw (bind -M insert ctrl-w | string trim)
assert_contains "$bind_cw" "backward-kill-word" "ctrl-w in insert mode deletes word backward"

set -l bind_cu (bind -M insert ctrl-u | string trim)
assert_contains "$bind_cu" "backward-kill-line" "ctrl-u in insert mode deletes line backward"

# Word motions in Normal mode (Helix: motions select/replace the range!)
set -l bind_w (bind -M default w | string trim)
assert_contains "$bind_w" "__fish_helix_normal_w" "w in normal mode selects next word (Helix)"

set -l bind_b (bind -M default b | string trim)
assert_contains "$bind_b" "__fish_helix_normal_b" "b in normal mode selects previous word (Helix)"

set -l bind_e (bind -M default e | string trim)
assert_contains "$bind_e" "__fish_helix_normal_e" "e in normal mode selects to word end (Helix)"

# Char motions in Normal mode (Helix: collapse selection and move)
set -l bind_h (bind -M default h | string trim)
assert_contains "$bind_h" "__fish_helix_normal_h" "h in normal mode collapses selection and moves left (Helix)"

set -l bind_l (bind -M default l | string trim)
assert_contains "$bind_l" "__fish_helix_normal_l" "l in normal mode collapses selection and moves right (Helix)"

set -l bind_k (bind -M default k | string trim)
assert_contains "$bind_k" "__fish_helix_normal_k" "k in normal mode collapses selection and moves up (Helix)"

set -l bind_j (bind -M default j | string trim)
assert_contains "$bind_j" "__fish_helix_normal_j" "j in normal mode collapses selection and moves down (Helix)"

# Verify k and j execution does not throw 'Unknown input function' error
set -l exec_output (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    fish_helix_key_bindings default
    __fish_helix_normal_k
    __fish_helix_normal_j
" 2>&1)
set -l err_match (string match "*Unknown input function*" -- "$exec_output")
assert_equal "$err_match" "" "Executing normal mode k and j does not trigger Unknown input function error"

# Indent / Unindent
set -l bind_indent (bind -M default \> | string trim)
assert_contains "$bind_indent" "__fish_helix_indent" "> indents line"

set -l bind_unindent (bind -M default \< | string trim)
assert_contains "$bind_unindent" "__fish_helix_unindent" "< unindents line"

# Multi-line indent/unindent with flag-like lines
set -l multiline_indent_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls \\\n-l'
    commandline -C 5
    __fish_helix_indent
    commandline -b
" 2>&1 | string match "*ls*-l*" | string length)
if test -n "$multiline_indent_res" -a "$multiline_indent_res" -gt 0
    set -g passed (math $passed + 1)
    set_color green
    echo "  ✓ PASS: Indenting multi-line commands with leading flags succeeds without option errors"
    set_color normal
else
    set -g failed (math $failed + 1)
    set_color red
    echo "  ✗ FAIL: Indenting multi-line commands with leading flags failed"
    set_color normal
end

# 4. Verify Visual (Select / Extend) Mode bindings
echo
echo "--- Testing Select / Extend Mode (visual) ---"
set -l bind_vis_d (bind -M visual d | string trim)
assert_contains "$bind_vis_d" "kill-selection" "d in visual mode kills selection"

set -l bind_vis_c (bind -M visual c | string trim)
assert_contains "$bind_vis_c" "kill-selection" "c in visual mode kills selection and enters insert"

set -l bind_vis_semi (bind -M visual ';' | string trim)
assert_contains "$bind_vis_semi" "end-selection" "; in visual mode collapses selection"

set -l bind_vis_gh (bind -M visual g,h | string trim)
assert_contains "$bind_vis_gh" "beginning-of-line" "gh in visual mode extends to line start"

set -l bind_vis_gl (bind -M visual g,l | string trim)
assert_contains "$bind_vis_gl" "end-of-line" "gl in visual mode extends to line end"

# Jump motions in visual mode (v-t-<char> and v-t-enter)
set -l bind_vis_t (bind -M visual t | string trim)
assert_contains "$bind_vis_t" "forward-jump-till" "t in visual mode is forward-jump-till"

set -l bind_vis_t_enter (bind -M visual t,enter | string trim)
assert_contains "$bind_vis_t_enter" "end-of-line" "v-t-enter in visual mode extends selection to end-of-line"

set -l bind_vis_f_enter (bind -M visual f,enter | string trim)
assert_contains "$bind_vis_f_enter" "end-of-line" "v-f-enter in visual mode extends selection to end-of-line"

# Search / History in visual mode
set -l bind_vis_slash (bind -M visual / | string trim)
assert_contains "$bind_vis_slash" "__fish_helix_history_search" "/ in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_slash" "end-selection" "/ in visual mode collapses selection"

set -l bind_vis_qmark (bind -M visual \? | string trim)
assert_contains "$bind_vis_qmark" "__fish_helix_history_search" "? in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_qmark" "end-selection" "? in visual mode collapses selection"

set -l bind_vis_ctrl_r (bind -M visual ctrl-r | string trim)
assert_contains "$bind_vis_ctrl_r" "__fish_helix_history_search" "Ctrl-r in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_ctrl_r" "end-selection" "Ctrl-r in visual mode collapses selection"

set -l bind_vis_sp_b (bind -M visual ' ',b | string trim)
assert_contains "$bind_vis_sp_b" "__fish_helix_history_search" "<space>b in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_sp_b" "end-selection" "<space>b in visual mode collapses selection"

set -l bind_vis_n (bind -M visual n | string trim)
assert_contains "$bind_vis_n" "history-search-backward" "n in visual mode searches history backward"

set -l bind_vis_N (bind -M visual N | string trim)
assert_contains "$bind_vis_N" "history-search-forward" "N in visual mode searches history forward"

# 5. Verify Mode Prompt
echo
echo "--- Testing Mode Prompt ---"
set -g fish_key_bindings fish_helix_key_bindings
set -g fish_helix_show_mode_prompt true

set -g fish_bind_mode default
set -l prompt_norm (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_norm" "[NOR]" "Normal mode displays [NOR]"

set -g fish_bind_mode insert
set -l prompt_ins (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_ins" "[INS]" "Insert mode displays [INS]"

set -g fish_bind_mode visual
set -l prompt_sel (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_sel" "[SEL]" "Select mode displays [SEL]"

set -g fish_bind_mode helix_replace_one
set -l prompt_rep (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_rep" "[REP]" "Replace mode displays [REP]"

# Test disabling prompt output (e.g. for Tide / Starship)
set -g fish_helix_show_mode_prompt false
set -l prompt_disabled (fish_helix_mode_prompt | string trim)
assert_equal "$prompt_disabled" "" "Prompt output is empty when fish_helix_show_mode_prompt is false"
set -g fish_helix_show_mode_prompt true

# 6. Verify Helper Logic
echo
echo "--- Testing Helper Functions ---"
set -l pair_paren (__fish_helix_get_surround_pair '(')
assert_equal "$pair_paren[1]" "(" "Surround open paren"
assert_equal "$pair_paren[2]" ")" "Surround close paren"

set -l pair_quote (__fish_helix_get_surround_pair '"')
assert_equal "$pair_quote[1]" '"' "Surround open quote"
assert_equal "$pair_quote[2]" '"' "Surround close quote"

# Count consumption
set -g __fish_helix_count "12"
set -l consumed (__fish_helix_consume_count)
assert_equal "$consumed" "12" "Count accumulation consumed correctly"
assert_equal "$__fish_helix_count" "" "Count reset after consumption"

# 7. Verify Atuin & History Search Integration
echo
echo "--- Testing Atuin & History Search Integration ---"

# Atuin enable check
set -l orig_atuin $fish_helix_atuin
set -g fish_helix_atuin false
set -l disabled_res 0
if not __fish_helix_is_atuin_enabled
    set disabled_res 1
end
assert_equal "$disabled_res" "1" "fish_helix_atuin=false correctly disables atuin"

set -g fish_helix_atuin true
set -l enabled_res 0
if __fish_helix_is_atuin_enabled
    set enabled_res 1
end
assert_equal "$enabled_res" "1" "fish_helix_atuin=true enables atuin when binary or function present"

# Atuin keymap mode spoofing (default mode -> vim-normal, insert mode -> vim-insert)
set -l spoof_res (fish --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    set -g fish_key_bindings fish_helix_key_bindings
    set -g fish_bind_mode default
    function _atuin_search
        set -l keymap_mode
        switch \$fish_key_bindings
            case fish_vi_key_bindings fish_hybrid_key_bindings
                switch \$fish_bind_mode
                    case default
                        set keymap_mode vim-normal
                    case insert
                        set keymap_mode vim-insert
                end
            case '*'
                set keymap_mode emacs
        end
        echo \$keymap_mode
    end
    __fish_helix_atuin_search
" 2>&1 | string trim)
assert_equal "$spoof_res" "vim-normal" "Atuin search receives vim-normal mode in default mode"

set -l spoof_res_ins (fish --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    set -g fish_key_bindings fish_helix_key_bindings
    set -g fish_bind_mode insert
    function _atuin_search
        set -l keymap_mode
        switch \$fish_key_bindings
            case fish_vi_key_bindings fish_hybrid_key_bindings
                switch \$fish_bind_mode
                    case default
                        set keymap_mode vim-normal
                    case insert
                        set keymap_mode vim-insert
                end
            case '*'
                set keymap_mode emacs
        end
        echo \$keymap_mode
    end
    __fish_helix_atuin_search
" 2>&1 | string trim)
assert_equal "$spoof_res_ins" "vim-insert" "Atuin search receives vim-insert mode in insert mode"

# Restore original atuin setting
set -g fish_helix_atuin $orig_atuin

# 8. Verify Match Mode Extensions (Textobjects & Surround Delete/Replace)
echo
echo "--- Testing Match Mode Extensions (Textobjects & Surround) ---"

# Key bindings in default mode
set -l bind_md (bind -M default m,d | string trim)
assert_contains "$bind_md" "helix_surround_delete" "md in normal mode enters surround delete"

set -l bind_mr (bind -M default m,r | string trim)
assert_contains "$bind_mr" "helix_surround_replace_old" "mr in normal mode enters surround replace"

set -l bind_mi (bind -M default m,i | string trim)
assert_contains "$bind_mi" "helix_textobject_inside" "mi in normal mode enters textobject inside"

set -l bind_ma (bind -M default m,a | string trim)
assert_contains "$bind_ma" "helix_textobject_around" "ma in normal mode enters textobject around"

# Key bindings in visual mode
set -l bind_vis_md (bind -M visual m,d | string trim)
assert_contains "$bind_vis_md" "helix_surround_delete" "md in visual mode enters surround delete"

set -l bind_vis_mr (bind -M visual m,r | string trim)
assert_contains "$bind_vis_mr" "helix_surround_replace_old" "mr in visual mode enters surround replace"

set -l bind_vis_mi (bind -M visual m,i | string trim)
assert_contains "$bind_vis_mi" "helix_textobject_inside" "mi in visual mode enters textobject inside"

set -l bind_vis_ma (bind -M visual m,a | string trim)
assert_contains "$bind_vis_ma" "helix_textobject_around" "ma in visual mode enters textobject around"

# Sub-mode transitions and actions
set -l bind_sub_md (bind -M helix_surround_delete '' | string trim)
assert_contains "$bind_sub_md" "__fish_helix_surround_delete" "helix_surround_delete invokes __fish_helix_surround_delete"

set -l bind_sub_mr_old (bind -M helix_surround_replace_old '' | string trim)
assert_contains "$bind_sub_mr_old" "__fish_helix_surround_save_old" "helix_surround_replace_old saves old char"

set -l bind_sub_mr_new (bind -M helix_surround_replace_new '' | string trim)
assert_contains "$bind_sub_mr_new" "__fish_helix_surround_replace" "helix_surround_replace_new invokes replace"

set -l bind_sub_mi (bind -M helix_textobject_inside '' | string trim)
assert_contains "$bind_sub_mi" "__fish_helix_textobject i" "helix_textobject_inside invokes __fish_helix_textobject i"

set -l bind_sub_ma (bind -M helix_textobject_around '' | string trim)
assert_contains "$bind_sub_ma" "__fish_helix_textobject a" "helix_textobject_around invokes __fish_helix_textobject a"

# Helper: __fish_helix_get_surround_pair with aliases (b, r, B)
set -l pair_b (__fish_helix_get_surround_pair 'b')
assert_equal "$pair_b[1]" "(" "b resolves to ("
assert_equal "$pair_b[2]" ")" "b resolves to )"

set -l pair_r (__fish_helix_get_surround_pair 'r')
assert_equal "$pair_r[1]" "[" "r resolves to ["
assert_equal "$pair_r[2]" "]" "r resolves to ]"

set -l pair_B (__fish_helix_get_surround_pair 'B')
assert_equal "$pair_B[1]" "{" "B resolves to {"
assert_equal "$pair_B[2]" "}" "B resolves to }"

# Helper: __fish_helix_find_pair
set -l quote_pair (__fish_helix_find_pair '"' 'git commit -m "initial commit"' 18)
assert_equal "$quote_pair[1]" "14" "find_pair double quote open index"
assert_equal "$quote_pair[2]" "29" "find_pair double quote close index"

set -l paren_nested (__fish_helix_find_pair '(' 'echo (math (expr 1 + 2))' 18)
assert_equal "$paren_nested[1]" "11" "find_pair nested paren inner open index"
assert_equal "$paren_nested[2]" "22" "find_pair nested paren inner close index"

# Helper: __fish_helix_find_word_bounds
set -l word_bounds_in (__fish_helix_find_word_bounds 'w' 'i' 'git commit -m "initial"' 6)
assert_equal "$word_bounds_in[1]" "4" "find_word_bounds commit start"
assert_equal "$word_bounds_in[2]" "10" "find_word_bounds commit end"

set -l word_bounds_ar (__fish_helix_find_word_bounds 'w' 'a' 'git commit -m "initial"' 6)
assert_equal "$word_bounds_ar[1]" "4" "find_word_bounds commit around start"
assert_equal "$word_bounds_ar[2]" "11" "find_word_bounds commit around end (with space)"

# Interactive execution tests: Surround Delete
set -l test_del_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m \"initial commit\"'
    commandline -C 18
    __fish_helix_surround_delete '\"'
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_del_res" 'git commit -m initial commit' "Surround delete removes double quotes"

set -l test_del_paren (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo (pwd)'
    commandline -C 7
    __fish_helix_surround_delete '('
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_del_paren" 'echo pwd' "Surround delete removes parentheses"

# Interactive execution tests: Surround Replace
set -l test_rep_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo \"hello world\"'
    commandline -C 7
    set -g __fish_helix_surround_old '\"'
    __fish_helix_surround_replace \"'\"
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_res" "echo 'hello world'" "Surround replace converts double quotes to single quotes"

set -l test_rep_paren (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo (pwd)'
    commandline -C 7
    set -g __fish_helix_surround_old 'b'
    __fish_helix_surround_replace 'r'
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_paren" 'echo [pwd]' "Surround replace converts parens (b) to square brackets (r)"

# Interactive execution tests: Textobject selection
set -l test_to_mode (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo \"hello world\"'
    commandline -C 7
    __fish_helix_textobject i '\"'
    echo \$fish_bind_mode
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_to_mode" "visual" "Textobject selection sets visual mode"

echo
echo "================================================="
echo "Results: $passed Passed, $failed Failed"
echo "================================================="

if test $failed -gt 0
    exit 1
else
    exit 0
end
