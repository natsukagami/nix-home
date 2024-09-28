## Author: @natsukagami (https://github.com/natsukagami)
## 
## To activate, source the file into kakrc and add:
###    require-module latex-kak
##
## NOTE: This overrides <a-o>, so if you don't like it, remove it.

# Create a simple begin block, put the cursors in and remove multi-cursor on exit.
define-command -hidden create-begin-block %{
    execute-keys "<esc>i\begin{b0}<ret>\end{b0}<esc>"
    execute-keys "<a-/>b0<ret><a-N>"
    execute-keys -with-hooks -with-maps "c"
    hook -once buffer ModeChange .*:normal %{
        execute-keys -with-maps ",gl"
    }
}
# Create a begin block with the given parameter as block name.
define-command -params 1 create-begin-block-with %{
    execute-keys "<esc>i\begin{b0}<ret>\end{b0}<esc>"
    execute-keys "<a-/>b0<ret><a-N>c%arg{1}<esc>,"
    execute-keys "o<esc>k"
    execute-keys -with-maps "gl"
}
# Create a \param{} block and put the cursor in the middle.
define-command -params 2 -hidden create-delims %{
    execute-keys "<esc>i%arg{1}<esc>hZa%arg{2}<esc>zl"
    execute-keys -with-hooks -with-maps "i"
}
define-command -params 1 create-block-with %{
    create-delims "\%arg{1}{" "}"
}

# The font-menu
declare-user-mode latex-font
## Semantics
map -docstring "Text"                 global latex-font t ": create-block-with text<ret>"
map -docstring "Emphasize (emph)"     global latex-font e ": create-block-with emph<ret>"
## Shape
map -docstring "Italics (textit)"     global latex-font i ": create-block-with textit<ret>"
map -docstring "Upright (textup)"     global latex-font u ": create-block-with textup<ret>"
# map -docstring "Slanted (textsl)"     global latex-font S ": create-block-with textsl<ret>"
# map -docstring "Swash font (textsw)"  global latex-font W ": create-block-with textsw<ret>"
# map -docstring "Small caps (textsc)"  global latex-font C ": create-block-with textsc<ret>"
# Weight
map -docstring "Bold text (textbf)"   global latex-font b ": create-block-with textbf<ret>"
# map -docstring "Medium bold (textmd)" global latex-font M ": create-block-with textmd<ret>"
# map -docstring "Normal (textnormal)"  global latex-font N ": create-block-with textnormal<ret>"
## Family 
# map -docstring "Serif font (textsf)"  global latex-font s ": create-block-with textsf<ret>"
# map -docstring "Roman text (textrm)"  global latex-font r ": create-block-with textrm<ret>"
map -docstring "Monospace (texttt)"   global latex-font m ": create-block-with texttt<ret>"
## Math styles
map -docstring "Math Calligraphic (mathcal)" global latex-font <a-c> ": create-block-with mathcal<ret>"
map -docstring "Math Blackboard (mathbb)"    global latex-font <a-b> ": create-block-with mathbb<ret>"
# map -docstring "Math Fraktur (mathfr)"       global latex-font <a-F> ": create-block-with mathfr<ret>"
# map -docstring "Math Roman (mathrm)"         global latex-font <a-r> ": create-block-with mathrm<ret>"
# map -docstring "Math Italics (mathit)"       global latex-font <a-i> ": create-block-with mathit<ret>"
# map -docstring "Math Bold (mathbf)"          global latex-font <a-B> ": create-block-with mathbf<ret>"
# map -docstring "Serif font (mathsf)"         global latex-font <a-s> ": create-block-with mathsf<ret>"
map -docstring "Math Monospace (mathtt)"     global latex-font <a-m> ": create-block-with mathtt<ret>"
map -docstring "Math Fraktur (mathfrak)"     global latex-font f ": create-block-with mathfrak<ret>"

# "Insert block" menu
declare-user-mode latex-insert-block
## Common normal text blocks
map -docstring "Unordered list" global latex-insert-block u ": create-begin-block-with itemize<ret>"
map -docstring "Ordered list"   global latex-insert-block o ": create-begin-block-with enumerate<ret>"
## Common math blocks
map -docstring "Theorem"        global latex-insert-block t ": create-begin-block-with theorem<ret>"
map -docstring "Definition"     global latex-insert-block d ": create-begin-block-with definition<ret>"
map -docstring "Lemma"          global latex-insert-block l ": create-begin-block-with lemma<ret>"
map -docstring "Example"        global latex-insert-block e ": create-begin-block-with example<ret>"
map -docstring "Proof"          global latex-insert-block p ": create-begin-block-with proof<ret>"
map -docstring "Remark"         global latex-insert-block r ": create-begin-block-with remark<ret>"
map -docstring "Proposition"    global latex-insert-block <a-p> ": create-begin-block-with proposition<ret>"
map -docstring "Corollary"      global latex-insert-block C ": create-begin-block-with corollary<ret>"
## Common environments
map -docstring "align*"         global latex-insert-block a ": create-begin-block-with align*<ret>"
map -docstring "align"          global latex-insert-block <a-a> ": create-begin-block-with align<ret>"
map -docstring "equation"       global latex-insert-block E ": create-begin-block-with equation<ret>"
map -docstring "equation*"      global latex-insert-block <a-e> ": create-begin-block-with equation*<ret>"
map -docstring "Matrix"         global latex-insert-block m ": create-begin-block-with bmatrix<ret>"
map -docstring "Cases"          global latex-insert-block C ": create-begin-block-with cases<ret>"
map -docstring "Table"          global latex-insert-block T ": create-begin-block-with tabular<ret>"
## Custom
map -docstring "Custom"         global latex-insert-block c ": create-begin-block<ret>"

# Pairs of delimiters
declare-user-mode latex-insert-delims
map -docstring "Grouping"          global latex-insert-delims g ": create-delims { }<ret>"
map -docstring "Parentheses"       global latex-insert-delims p ": create-delims ( )<ret>"
map -docstring "Large Parentheses" global latex-insert-delims P ": create-delims \left( \right)<ret>"
map -docstring "Brackets"          global latex-insert-delims b ": create-delims \left[ \right]<ret>"
map -docstring "Sets"              global latex-insert-delims s ": create-delims \{ \}<ret>"
map -docstring "Large Sets"        global latex-insert-delims S ": create-delims \left\{ \right\}<ret>"


hook global WinSetOption filetype=(tex|latex) %{
    ## Create delims (shortcuts)
    map buffer normal <a-1> ": enter-user-mode latex-insert-delims<ret>p"
    map buffer insert <a-1> "<esc>: enter-user-mode latex-insert-delims<ret>p"
    map buffer normal <a-2> ": enter-user-mode latex-insert-delims<ret>g"
    map buffer insert <a-2> "<esc>: enter-user-mode latex-insert-delims<ret>g"
    map buffer normal <a-3> "i\(\)<esc>Zhhi"
    map buffer insert <a-3> "\(\)<a-;>Z<a-;>2h"
    map buffer normal <a-4> "i\[\]<esc>Zhhi"
    map buffer insert <a-4> "\[\]<a-;>Z<a-;>2h"
    map buffer normal <a-5> ": enter-user-mode latex-insert-delims<ret>"
    map buffer insert <a-5> "<esc>: enter-user-mode latex-insert-delims<ret>"

    ## Quickly create begin/end blocks
    map buffer normal <c-n> ": create-begin-block<ret>"
    map buffer insert <c-n> "<esc>: create-begin-block<ret>"

    ## Font menu
    map buffer normal <c-b> ": enter-user-mode latex-font<ret>"
    map buffer insert <c-b> "<esc>: enter-user-mode latex-font<ret>"

    ## Insert menu
    map buffer normal <a-b> ": enter-user-mode latex-insert-block<ret>"
    map buffer insert <a-b> "<esc>: enter-user-mode latex-insert-block<ret>"

    ## Select math equations and environment blocks
    map buffer object e -docstring "Inline Math equation \( \)" "c\\\\\\(,\\\\\\)<ret>"
    map buffer object E -docstring "Display Math equation \[ \]" "c\\\\\\[,\\\\\\]<ret>"
    map buffer object v -docstring "Simple environment \env{}" "c\\\\\\w+\\{,\\}<ret>"
    map buffer object V -docstring "Full environment \begin{env}\end{env}" "c\\\\begin\\{\\w+\\}(?:\\{[\\w\\s]*\\})*(?:\\[[\\w\\s]*\\])*,\\\\end\\{\\w+\\}<ret>"

    ## Quickly get a new item
    map buffer normal <a-o> "o\item "
    map buffer insert <a-ret> "<esc>o\item "
}

