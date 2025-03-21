hook global WinSetOption filetype=(markdown) %{
    map buffer normal <c-b> ": enter-user-mode markdown-menu<ret>"
}

# A menu for common markdown actions
declare-user-mode markdown-menu

map -docstring "Toggle the checkboxes on the same line" global markdown-menu t ": markdown-toggle-checkbox<ret>"

define-command -hidden markdown-toggle-checkbox %{
    try %{
        execute-keys -draft "xs^\s*- \[( |x)\]<ret>h: markdown-toggle-checkbox-selections<ret>"
    }
}

define-command -hidden markdown-toggle-checkbox-selections %{
    try %{
        execute-keys -draft -itersel ": markdown-toggle-checkbox-one<ret>"
    }
}

define-command -hidden markdown-toggle-checkbox-one %{
    try %{
        execute-keys -draft "sx<ret>r "
    } catch %{
        execute-keys -draft "s <ret>rx"
    }
}

