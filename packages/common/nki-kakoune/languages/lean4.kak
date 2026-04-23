# https://lean-lang.org/

hook global WinSetOption filetype=lean %{
    require-module lean4

    set-option window comment_line '--'
    set-option window comment_block_begin '/-'
    set-option window comment_block_end '-/'

    set-option window extra_word_chars '_' "'"

    set-option -add window matching_pairs '⦃' '⦄' '⟦' '⟧' '⟨' '⟩' '‹' '›' '«' '»' '⁅' '⁆' '‖' '‖'
    set-option -add window matching_pairs '⌊' '⌋' '⌈' '⌉' '⦋' '⦌' '⟪' '⟫'

    hook window ModeChange pop:insert:.* -group lean4-trim-indent lean4-trim-indent
    hook window InsertChar \n -group lean4-insert lean4-insert-on-new-line
    # hook window InsertChar \n -group lean4-indent lean4-indent-on-new-line

    hook -group lean4-infoview window BufReload  .* %{ lean4_update_infoview } 
    hook -group lean4-infoview window NormalIdle .* %{ lean4_update_infoview } 
    hook -group lean4-infoview window InsertIdle .* %{ lean4_update_infoview }

    # hook -group lean4-abbreviations window ModeChange pop:insert:.* %{ lean4_replace_abbreviations }
    # hook -group lean4-abbreviations window InsertKey <ret> %{ lean4_replace_abbreviations }

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window lean4-.+ }
}

hook -group lean4-highlight global WinSetOption filetype=lean %{
    add-highlighter window/lean4 ref lean4
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/lean4 }
}

provide-module lean4 %[

add-highlighter shared/lean4 regions
add-highlighter shared/lean4/code default-region group
# TODO: support for s! and r! strings
add-highlighter shared/lean4/string region (?<!'\\)(?<!')" (?<!\\)(\\\\)*" fill string
add-highlighter shared/lean4/line_comment region -- $ fill comment
add-highlighter shared/lean4/block_comment region -recurse /- /-  -/ fill comment

add-highlighter shared/lean4/code/ regex (?<!')\b0x+[A-Fa-f0-9]+ 0:value
add-highlighter shared/lean4/code/ regex (?<!')\b\d+([.]\d+)? 0:value

# Infoview
define-command -hidden lean4_update_infoview %{
    lean-get-goal *lean-infoview*
    lean-get-term-goal *lean-infoview-term*
}

# Abbreviations
# define-command -hidden lean4_replace_abbreviations %{
#     execute-keys -draft %{
#         %|python $kak_config/lean4-replace-abbreviations.py<ret>
#     }
# }

# Indentation
# Taken explicitly from rc/filetype/haskell.kak
# https://github.com/mawww/kakoune/blob/master/rc/filetype/haskell.kak
define-command -hidden lean4-trim-indent %{
    try %{ execute-keys -draft -itersel x s \h+$ <ret> d }
}

define-command -hidden lean4-insert-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy -- comments prefix and following white spaces
        try %{ execute-keys -draft k x s ^\h*\K--\h* <ret> y gh j P }
    }
}

define-command -hidden lean4-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # align to first clause
        try %{ execute-keys -draft <semicolon> k x X s ^\h*(if|then|else)?\h*(([\w']+\h+)+=)?\h*(case\h+[\w']+\h+of|do|let|where)\h+\K.* <ret> s \A|.\z <ret> & }
        # filter previous line
        try %{ execute-keys -draft k : lean4-trim-indent <ret> }
        # indent after lines beginning with condition or ending with expression or =(
        try %{ execute-keys -draft <semicolon> k x <a-k> ^\h*if|[=(]$|\b(case\h+[\w']+\h+of|do|let|where)$ <ret> j <a-gt> }
    }
}

]
