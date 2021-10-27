# --------------------------------------------------------------------------------------------------- #
# racket source adapted from:
# https://github.com/soegaard/racket-highlight-for-github/blob/master/generate-keywords.rkt
# https://github.com/soegaard/racket-highlight-for-github/blob/master/generate-regular-expressions.rkt
# --------------------------------------------------------------------------------------------------- #
# modified template from: scheme.kak
# https://github.com/mawww/kakoune/blob/master/rc/filetype/scheme.kak
# --------------------------------------------------------------------------------------------------- #
# kak colour codes; value:red, type,operator:yellow, variable,module,attribute:green,
#                   function,string,comment:cyan, keyword:blue, meta:magenta, builtin:default
# --------------------------------------------------------------------------------------------------- #
# NOTE: authors first use of 'awk', refer to scheme.kak
# TODO: extflonum
# --------------------------------------------------------------------------------------------------- #

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](rkt|rktd|rktl) %{
  set-option buffer filetype racket
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=racket %{
  require-module racket

  set-option window static_words %opt{racket_static_words}

  set-option buffer extra_word_chars '_' '-' '!' '%' '?' '<' '>' '='

  set-option buffer comment_line ';'
  set-option buffer comment_block_begin '#|'
  set-option buffer comment_block_end '|#'

  hook window ModeChange pop:insert:.* -group racket-trim-indent lisp-trim-indent
  hook window InsertChar \n -group racket-indent lisp-indent-on-new-line

  hook -once -always window WinSetOption filetype=.* %{ remove-hooks window racket-.+ }
}

hook -group racket-highlight global WinSetOption filetype=racket %{
  add-highlighter window/racket ref racket
  hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/racket }
}

# --------------------------------------------------------------------------------------------------- #
provide-module racket %§

require-module lisp

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/racket regions
add-highlighter shared/racket/code default-region group

add-highlighter shared/racket/string region '"' (?<!\\)(\\\\)*" fill string
add-highlighter shared/racket/comment region ';' '$' fill comment
add-highlighter shared/racket/comment-form region -recurse "\(" "#;\(" "\)" fill comment
add-highlighter shared/racket/comment-block region "#\|" "\|#" fill comment
add-highlighter shared/racket/quoted-form region -recurse "\(" "'\(" "\)" fill variable

add-highlighter shared/racket/code/ regex (#t|#f)\b 0:value
add-highlighter shared/racket/code/ regex \Q#%\E(app|datum|declare|expression|module-begin|plain-app|plain-lambda|plain-module-begin|printing-module-begin|provide|require|stratified-body|top|top-interaction|variable-reference)\b 0:keyword

# racket classes and objects
add-highlighter shared/racket/code/ regex \b(this|writable|printable|object|externalizable|equal)(\Q%\E|<\Q%\E>) 0:keyword

# --------------------------------------------------------------------------------------------------- #
# link to regular expression <https://regex101.com/r/PoJ7wS/2> as at 01/04/2019
# <https://github.com/codemirror/CodeMirror/blob/master/mode/scheme/scheme.js#L46>
# --------------------------------------------------------------------------------------------------- #
# binary
add-highlighter shared/racket/code/ regex %{(#b|#b#(e|i)|#(e|i)#b)(?:[-+]i|[-+][01]+#*(?:/[01]+#*)?i|[-+]?[01]+#*(?:/[01]+#*)?@[-+]?[01]+#*(?:/[01]+#*)?|[-+]?[01]+#*(?:/[01]+#*)?[-+](?:[01]+#*(?:/[01]+#*)?)?i|[-+]?[01]+#*(?:/[01]+#*)?)((?=[()\s;"])|$)} 0:rgb:e8b5ce

# octal
add-highlighter shared/racket/code/ regex %{(#o|#o#(e|i)|#(e|i)#o)(?:[-+]i|[-+][0-7]+#*(?:/[0-7]+#*)?i|[-+]?[0-7]+#*(?:/[0-7]+#*)?@[-+]?[0-7]+#*(?:/[0-7]+#*)?|[-+]?[0-7]+#*(?:/[0-7]+#*)?[-+](?:[0-7]+#*(?:/[0-7]+#*)?)?i|[-+]?[0-7]+#*(?:/[0-7]+#*)?)((?=[()\s;"])|$)} 0:rgb:e8b5ce

# hexadecimal
add-highlighter shared/racket/code/ regex %{(#x|#x#(e|i)|#(e|i)#x)(?:[-+]i|[-+][\da-f]+#*(?:/[\da-f]+#*)?i|[-+]?[\da-f]+#*(?:/[\da-f]+#*)?@[-+]?[\da-f]+#*(?:/[\da-f]+#*)?|[-+]?[\da-f]+#*(?:/[\da-f]+#*)?[-+](?:[\da-f]+#*(?:/[\da-f]+#*)?)?i|[-+]?[\da-f]+#*(?:/[\da-f]+#*)?)((?=[()\s;"])|$)} 0:rgb:e8b5ce

# decimal
add-highlighter shared/racket/code/ regex %{(#d|#d#(e|i)|#(e|i)#d|\b)(?:[-+]i|[-+](?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*)i|[-+]?(?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*)@[-+]?(?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*)|[-+]?(?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*)[-+](?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*)?i|(?:(?:(?:\d+#+\.?#*|\d+\.\d*#*|\.\d+#*|\d+)(?:[esfdl][-+]?\d+)?)|\d+#*/\d+#*))((?=[\s();"])|$)} 0:rgb:e8b5ce

# --------------------------------------------------------------------------------------------------- #
# If your neatness borders on obsessive at times head over to:
# <https://github.com/wlangstroth/vim-racket/blob/master/syntax/racket.vim>
# for some inspiration or a breath of fresh air....hold on tight and scroll.
evaluate-commands %sh{
    exec awk -f - <<'EOF'
    BEGIN{

        split("* + - /", operators);

        split( \
        "-> ->* ->*m ->d ->dm ->i ->m ... :do-in == => _ "\
        "absent abstract all-defined-out all-from-out and any augment augment* "\
        "augment-final augment-final* augride augride* begin begin-for-syntax "\
        "begin0 case case-> case->m case-lambda class class* "\
        "class-field-accessor class-field-mutator class/c class/derived "\
        "combine-in combine-out command-line compound-unit compound-unit/infer "\
        "cond cons/dc contract contract-out contract-pos/neg-doubling "\
        "contract-struct contracted define define-compound-unit "\
        "define-compound-unit/infer define-contract-struct "\
        "define-custom-hash-types define-custom-set-types define-for-syntax "\
        "define-local-member-name define-logger define-match-expander "\
        "define-member-name define-module-boundary-contract "\
        "define-namespace-anchor define-opt/c define-sequence-syntax "\
        "define-serializable-class define-serializable-class* define-signature "\
        "define-signature-form define-struct define-struct/contract "\
        "define-struct/derived define-syntax define-syntax-rule define-syntaxes "\
        "define-unit define-unit-binding define-unit-from-context "\
        "define-unit/contract define-unit/new-import-export define-unit/s "\
        "define-values define-values-for-export define-values-for-syntax "\
        "define-values/invoke-unit define-values/invoke-unit/infer "\
        "define/augment define/augment-final define/augride define/contract "\
        "define/final-prop define/match define/overment define/override "\
        "define/override-final define/private define/public define/public-final "\
        "define/pubment define/subexpression-pos-prop "\
        "define/subexpression-pos-prop/name delay delay/idle delay/name "\
        "delay/strict delay/sync delay/thread do else except except-in "\
        "except-out export extends failure-cont false false/c field "\
        "file flat-murec-contract flat-rec-contract for for* "\
        "for*/and for*/async for*/first for*/fold for*/fold/derived for*/hash "\
        "for*/hasheq for*/hasheqv for*/last for*/list for*/lists "\
        "for*/mutable-set for*/mutable-seteq for*/mutable-seteqv for*/or "\
        "for*/product for*/set for*/seteq for*/seteqv for*/stream for*/sum "\
        "for*/vector for*/weak-set for*/weak-seteq for*/weak-seteqv for-label "\
        "for-meta for-syntax for-template for/and for/async for/first for/fold "\
        "for/fold/derived for/hash for/hasheq for/hasheqv for/last for/list "\
        "for/lists for/mutable-set for/mutable-seteq for/mutable-seteqv for/or "\
        "for/product for/set for/seteq for/seteqv for/stream for/sum for/vector "\
        "for/weak-set for/weak-seteq for/weak-seteqv gen:custom-write gen:dict "\
        "gen:equal+hash gen:set gen:stream generic get-field hash/dc if implies "\
        "import include include-at/relative-to include-at/relative-to/reader "\
        "include/reader inherit inherit-field inherit/inner inherit/super init "\
        "init-depend init-field init-rest inner inspect instantiate interface "\
        "interface* invariant-assertion invoke-unit invoke-unit/infer lambda "\
        "lazy let let* let*-values let-syntax let-syntaxes let-values let/cc "\
        "let/ec letrec letrec-syntax letrec-syntaxes letrec-syntaxes+values "\
        "letrec-values lib link local local-require log-debug log-error "\
        "log-fatal log-info log-warning match match* match*/derived "\
        "match-define match-define-values match-lambda match-lambda* "\
        "match-lambda** match-let match-let* match-let*-values match-let-values "\
        "match-letrec match-letrec-values match/derived match/values "\
        "member-name-key mixin module module* module+ nand new nor "\
        "object-contract object/c only only-in only-meta-in open opt/c or "\
        "overment overment* override override* override-final override-final* "\
        "parameterize parameterize* parameterize-break parametric->/c place "\
        "place* place/context planet prefix prefix-in prefix-out private "\
        "private* prompt-tag/c protect-out provide provide-signature-elements "\
        "provide/contract public public* public-final public-final* pubment "\
        "pubment* quasiquote quasisyntax quasisyntax/loc quote quote-syntax "\
        "quote-syntax/prune recontract-out recursive-contract relative-in "\
        "rename rename-in rename-inner rename-out rename-super require send "\
        "send* send+ send-generic send/apply send/keyword-apply set! "\
        "set!-values set-field! shared stream stream* stream-cons struct "\
        "struct* struct-copy struct-field-index struct-out struct/c struct/ctc "\
        "struct/dc submod super super-instantiate super-make-object super-new "\
        "syntax syntax-case syntax-case* syntax-id-rules syntax-rules "\
        "syntax/loc tag this thunk thunk* time unconstrained-domain-> "\
        "unit unit-from-context unit/c unit/new-import-export unit/s unless "\
        "unquote unquote-splicing unsyntax unsyntax-splicing values/drop when "\
        "with-continuation-mark with-contract with-contract-continuation-mark "\
        "with-handlers with-handlers* with-method with-syntax ~@ λ", keywords);

        split( \
        "*list/c </c <=/c =/c >/c >=/c "\
        "abort-current-continuation abs acos add-between add1 "\
        "alarm-evt always-evt and/c andmap angle any/c append append* "\
        "append-map apply argmax argmin arithmetic-shift arity-at-least "\
        "arity-at-least-value arity-checking-wrapper "\
        "arrow-contract-info arrow-contract-info-accepts-arglist "\
        "arrow-contract-info-chaperone-procedure "\
        "arrow-contract-info-check-first-order asin assf "\
        "assoc assq assv atan bad-number-of-results banner base->-doms/c "\
        "base->-rngs/c between/c bitwise-and bitwise-bit-field "\
        "bitwise-ior bitwise-not bitwise-xor "\
        "blame-add-car-context blame-add-cdr-context blame-add-context "\
        "blame-add-missing-party blame-add-nth-arg-context "\
        "blame-add-range-context blame-add-unknown-context blame-context "\
        "blame-contract blame-fmt->-string blame-negative "\
        "blame-positive blame-replace-negative blame-source "\
        "blame-swap blame-update blame-value box box-cas! box-immutable "\
        "box-immutable/c box/c break-enabled break-thread "\
        "build-chaperone-contract-property build-compound-type-name "\
        "build-contract-property build-flat-contract-property build-list "\
        "build-path build-path/convention-type build-string build-vector "\
        "byte-pregexp byte-regexp bytes bytes->immutable-bytes bytes->list "\
        "bytes->path bytes->path-element bytes->string/latin-1 "\
        "bytes->string/locale bytes->string/utf-8 bytes-append bytes-append* "\
        "bytes-close-converter bytes-convert bytes-convert-end bytes-copy "\
        "bytes-copy! bytes-fill! bytes-join bytes-length bytes-open-converter "\
        "bytes-ref bytes-set! bytes-utf-8-index bytes-utf-8-length "\
        "bytes-utf-8-ref caaaar caaadr caaar caadar caaddr caadr caar cadaar "\
        "cadadr cadar caddar cadddr caddr cadr call-in-nested-thread "\
        "call-with-atomic-output-file call-with-break-parameterization "\
        "call-with-composable-continuation call-with-continuation-barrier "\
        "call-with-continuation-prompt call-with-current-continuation "\
        "call-with-default-reading-parameterization "\
        "call-with-escape-continuation call-with-exception-handler "\
        "call-with-file-lock/timeout call-with-immediate-continuation-mark "\
        "call-with-input-bytes call-with-input-file call-with-input-file* "\
        "call-with-input-string call-with-output-bytes call-with-output-file "\
        "call-with-output-file* call-with-output-string "\
        "call-with-parameterization call-with-semaphore "\
        "call-with-semaphore/enable-break call-with-values call/cc call/ec car "\
        "cartesian-product cdaaar cdaadr cdaar cdadar cdaddr cdadr cdar cddaar "\
        "cddadr cddar cdddar cddddr cdddr cddr cdr ceiling channel-get "\
        "channel-put channel-put-evt channel-try-get channel/c "\
        "chaperone-box chaperone-channel chaperone-continuation-mark-key "\
        "chaperone-evt chaperone-hash chaperone-hash-set chaperone-procedure "\
        "chaperone-procedure* chaperone-prompt-tag "\
        "chaperone-struct chaperone-struct-type chaperone-vector "\
        "chaperone-vector* char->integer char-downcase char-foldcase "\
        "char-general-category char-in char-in/c char-titlecase char-upcase "\
        "char-utf-8-length check-duplicate-identifier check-duplicates "\
        "checked-procedure-check-and-extract choice-evt class->interface "\
        "class-info class-seal class-unseal cleanse-path "\
        "close-input-port close-output-port coerce-chaperone-contract "\
        "coerce-chaperone-contracts coerce-contract coerce-contract/f "\
        "coerce-contracts coerce-flat-contract coerce-flat-contracts "\
        "collect-garbage collection-file-path collection-path combinations "\
        "compile compile-allow-set!-undefined "\
        "compile-context-preservation-enabled compile-enforce-module-constants "\
        "compile-syntax compiled-expression-recompile "\
        "compose compose1 conjoin conjugate cons cons/c const "\
        "continuation-mark-key/c continuation-mark-set->context "\
        "continuation-mark-set->list continuation-mark-set->list* "\
        "continuation-mark-set-first continuation-marks "\
        "contract-continuation-mark-key contract-custom-write-property-proc "\
        "contract-exercise contract-first-order contract-late-neg-projection "\
        "contract-name contract-proc contract-projection "\
        "contract-random-generate contract-random-generate-fail "\
        "contract-random-generate-get-current-environment "\
        "contract-random-generate-stash contract-random-generate/choose "\
        "contract-struct-exercise contract-struct-generate "\
        "contract-struct-late-neg-projection contract-val-first-projection "\
        "convert-stream copy-directory/files copy-file copy-port cos cosh count "\
        "current-blame-format current-break-parameterization "\
        "current-code-inspector current-command-line-arguments current-compile "\
        "current-compile-target-machine current-compiled-file-roots "\
        "current-continuation-marks current-contract-region current-custodian "\
        "current-directory current-directory-for-user current-drive "\
        "current-environment-variables current-error-port current-eval "\
        "current-evt-pseudo-random-generator current-force-delete-permissions "\
        "current-future current-gc-milliseconds "\
        "current-get-interaction-input-port current-inexact-milliseconds "\
        "current-input-port current-inspector current-library-collection-links "\
        "current-library-collection-paths current-load current-load-extension "\
        "current-load-relative-directory current-load/use-compiled "\
        "current-locale current-logger current-memory-use current-milliseconds "\
        "current-module-declare-name current-module-declare-source "\
        "current-module-name-resolver current-module-path-for-load "\
        "current-namespace current-output-port current-parameterization "\
        "current-plumber current-preserved-thread-cell-values current-print "\
        "current-process-milliseconds current-prompt-read "\
        "current-pseudo-random-generator current-read-interaction "\
        "current-reader-guard current-readtable current-seconds "\
        "current-security-guard current-subprocess-custodian-mode "\
        "current-thread current-thread-group current-thread-initial-stack-size "\
        "current-write-relative-directory curry curryr custodian-box-value "\
        "custodian-limit-memory custodian-managed-list custodian-require-memory "\
        "custodian-shutdown-all custom-print-quotable-accessor "\
        "custom-write-accessor custom-write-property-proc", builtins_one);

        split( \
        "date date* date*-nanosecond date*-time-zone-name date-day "\
        "date-hour date-minute date-month date-second date-time-zone-offset "\
        "date-week-day date-year date-year-day datum->syntax "\
        "datum-intern-literal default-continuation-prompt-tag degrees->radians "\
        "delete-directory delete-directory/files delete-file denominator "\
        "dict->list dict-clear dict-clear! dict-copy dict-count dict-for-each "\
        "dict-implements/c dict-iter-contract dict-iterate-first "\
        "dict-iterate-key dict-iterate-next dict-iterate-value "\
        "dict-key-contract dict-keys dict-map dict-ref dict-ref! "\
        "dict-remove dict-remove! dict-set dict-set! dict-set* dict-set*! "\
        "dict-update dict-update! dict-value-contract dict-values "\
        "directory-list disjoin display display-lines display-lines-to-file "\
        "display-to-file displayln drop drop-common-prefix drop-right dropf "\
        "dropf-right dump-memory-stats dup-input-port dup-output-port "\
        "dynamic->* dynamic-get-field dynamic-object/c dynamic-place "\
        "dynamic-place* dynamic-require dynamic-require-for-syntax dynamic-send "\
        "dynamic-set-field! dynamic-wind eighth empty empty-sequence "\
        "empty-stream environment-variables-copy environment-variables-names "\
        "environment-variables-ref environment-variables-set! eof eof-evt "\
        "ephemeron-value eprintf eq-contract-val eq-hash-code eq? "\
        "equal-contract-val equal-hash-code equal-secondary-hash-code recur "\
        "eqv-hash-code error error-display-handler error-escape-handler "\
        "error-print-context-length error-print-source-location "\
        "error-print-width error-value->string-handler eval eval-jit-enabled "\
        "eval-syntax evt/c exact->inexact exact-ceiling exact-floor "\
        "exact-round exact-truncate executable-yield-handler exit "\
        "exit-handler exn exn-continuation-marks exn-message exn:break "\
        "exn:break-continuation exn:break:hang-up exn:break:terminate exn:fail "\
        "exn:fail:contract exn:fail:contract:arity exn:fail:contract:blame "\
        "exn:fail:contract:blame-object exn:fail:contract:continuation "\
        "exn:fail:contract:divide-by-zero exn:fail:contract:non-fixnum-result "\
        "exn:fail:contract:variable exn:fail:contract:variable-id "\
        "exn:fail:filesystem exn:fail:filesystem:errno "\
        "exn:fail:filesystem:errno-errno exn:fail:filesystem:exists "\
        "exn:fail:filesystem:missing-module "\
        "exn:fail:filesystem:missing-module-path exn:fail:filesystem:version "\
        "exn:fail:network exn:fail:network:errno exn:fail:network:errno-errno "\
        "exn:fail:object exn:fail:out-of-memory "\
        "exn:fail:read exn:fail:read-srclocs exn:fail:read:eof "\
        "exn:fail:read:non-char exn:fail:syntax exn:fail:syntax-exprs "\
        "exn:fail:syntax:missing-module exn:fail:syntax:missing-module-path "\
        "exn:fail:syntax:unbound exn:fail:unsupported exn:fail:user "\
        "exn:missing-module-accessor exn:srclocs-accessor exp "\
        "expand expand-once expand-syntax expand-syntax-once "\
        "expand-syntax-to-top-form expand-to-top-form expand-user-path "\
        "explode-path expt failure-result/c field-names fifth "\
        "file->bytes file->bytes-lines file->lines file->list file->string "\
        "file->value file-name-from-path file-or-directory-identity "\
        "file-or-directory-modify-seconds file-or-directory-permissions "\
        "file-position file-position* file-size file-stream-buffer-mode "\
        "file-truncate filename-extension filesystem-change-evt "\
        "filesystem-change-evt-cancel filesystem-root-list filter filter-map "\
        "filter-not filter-read-input-port find-executable-path find-files "\
        "find-library-collection-links find-library-collection-paths "\
        "find-relative-path find-system-path findf first first-or/c "\
        "flat-contract flat-contract-predicate "\
        "flat-contract-with-explanation flat-named-contract "\
        "flatten floating-point-bytes->real floor flush-output "\
        "fold-files foldl foldr for-each force format fourth fprintf "\
        "fsemaphore-count fsemaphore-post fsemaphore-wait future "\
        "gcd generate-member-key generate-temporaries gensym get-output-bytes "\
        "get-output-string get-preference get/build-late-neg-projection "\
        "get/build-val-first-projection getenv global-port-print-handler "\
        "group-by group-execute-bit group-read-bit group-write-bit guard-evt "\
        "handle-evt hash hash->list hash-clear hash-clear! hash-copy "\
        "hash-copy-clear hash-count hash-for-each hash-iterate-first "\
        "hash-iterate-key hash-iterate-key+value hash-iterate-next "\
        "hash-iterate-pair hash-iterate-value hash-keys hash-map hash-ref "\
        "hash-ref! hash-remove hash-remove! hash-set hash-set! hash-set* "\
        "hash-set*! hash-update hash-update! hash-values hash/c hasheq "\
        "hasheqv identifier-binding identifier-binding-symbol "\
        "identifier-label-binding identifier-prune-lexical-context "\
        "identifier-prune-to-source-module "\
        "identifier-remove-from-definition-context identifier-template-binding "\
        "identifier-transformer-binding identity if/c imag-part "\
        "impersonate-box impersonate-channel "\
        "impersonate-continuation-mark-key impersonate-hash "\
        "impersonate-hash-set impersonate-procedure impersonate-procedure* "\
        "impersonate-prompt-tag impersonate-struct impersonate-vector "\
        "impersonate-vector* impersonator-ephemeron "\
        "impersonator-prop:application-mark "\
        "impersonator-prop:blame impersonator-prop:contracted "\
        "in-bytes in-bytes-lines in-combinations in-cycle in-dict in-dict-keys "\
        "in-dict-pairs in-dict-values in-directory in-hash in-hash-keys "\
        "in-hash-pairs in-hash-values in-immutable-hash in-immutable-hash-keys "\
        "in-immutable-hash-pairs in-immutable-hash-values in-immutable-set "\
        "in-indexed in-input-port-bytes in-input-port-chars in-lines in-list "\
        "in-mlist in-mutable-hash in-mutable-hash-keys in-mutable-hash-pairs "\
        "in-mutable-hash-values in-mutable-set in-naturals in-parallel "\
        "in-permutations in-port in-producer in-range in-sequences in-set "\
        "in-slice in-stream in-string in-syntax in-value in-values*-sequence "\
        "in-values-sequence in-vector in-weak-hash in-weak-hash-keys "\
        "in-weak-hash-pairs in-weak-hash-values in-weak-set index-of "\
        "index-where indexes-of indexes-where inexact->exact "\
        "input-port-append instanceof/c integer->char integer->integer-bytes "\
        "integer-bytes->integer integer-in integer-length integer-sqrt "\
        "integer-sqrt/remainder interface->method-names "\
        "internal-definition-context-binding-identifiers "\
        "internal-definition-context-introduce internal-definition-context-seal "\
        "keyword->string keyword-apply keywords-match kill-thread last "\
        "last-pair lcm length list list* list*of list->bytes list->mutable-set "\
        "list->mutable-seteq list->mutable-seteqv list->set list->seteq "\
        "list->seteqv list->string list->vector list->weak-set list->weak-seteq "\
        "list->weak-seteqv list-ref list-set list-tail list-update "\
        "list/c listof load load-extension "\
        "load-on-demand-enabled load-relative load-relative-extension load/cd "\
        "load/use-compiled local-expand local-expand/capture-lifts "\
        "local-transformer-expand local-transformer-expand/capture-lifts "\
        "locale-string-encoding log log-all-levels log-level-evt "\
        "log-max-level log-message logger-name", builtins_two);

        split( \
        "magnitude make-arity-at-least make-base-empty-namespace "\
        "make-base-namespace make-bytes make-channel make-chaperone-contract "\
        "make-continuation-mark-key make-continuation-prompt-tag make-contract "\
        "make-custodian make-custodian-box make-custom-hash "\
        "make-custom-hash-types make-custom-set make-custom-set-types make-date "\
        "make-date* make-derived-parameter make-directory make-directory* "\
        "make-do-sequence make-empty-namespace make-environment-variables "\
        "make-ephemeron make-exn make-exn:break make-exn:break:hang-up "\
        "make-exn:break:terminate make-exn:fail make-exn:fail:contract "\
        "make-exn:fail:contract:arity make-exn:fail:contract:blame "\
        "make-exn:fail:contract:continuation "\
        "make-exn:fail:contract:divide-by-zero "\
        "make-exn:fail:contract:non-fixnum-result "\
        "make-exn:fail:contract:variable make-exn:fail:filesystem "\
        "make-exn:fail:filesystem:errno make-exn:fail:filesystem:exists "\
        "make-exn:fail:filesystem:missing-module "\
        "make-exn:fail:filesystem:version make-exn:fail:network "\
        "make-exn:fail:network:errno make-exn:fail:object "\
        "make-exn:fail:out-of-memory make-exn:fail:read make-exn:fail:read:eof "\
        "make-exn:fail:read:non-char make-exn:fail:syntax "\
        "make-exn:fail:syntax:missing-module make-exn:fail:syntax:unbound "\
        "make-exn:fail:unsupported make-exn:fail:user "\
        "make-file-or-directory-link make-flat-contract make-fsemaphore "\
        "make-generic make-handle-get-preference-locked make-hash "\
        "make-hash-placeholder make-hasheq make-hasheq-placeholder make-hasheqv "\
        "make-hasheqv-placeholder make-immutable-custom-hash "\
        "make-immutable-hash make-immutable-hasheq make-immutable-hasheqv "\
        "make-impersonator-property make-input-port make-input-port/read-to-peek "\
        "make-inspector make-interned-syntax-introducer make-keyword-procedure "\
        "make-known-char-range-list make-limited-input-port make-list "\
        "make-lock-file-name make-log-receiver make-logger make-mixin-contract "\
        "make-mutable-custom-set make-none/c make-object make-output-port "\
        "make-parameter make-parent-directory* make-phantom-bytes make-pipe "\
        "make-pipe-with-specials make-placeholder make-plumber make-polar "\
        "make-prefab-struct make-primitive-class make-proj-contract "\
        "make-pseudo-random-generator make-reader-graph make-readtable "\
        "make-rectangular make-rename-transformer make-resolved-module-path "\
        "make-security-guard make-semaphore make-set!-transformer "\
        "make-shared-bytes make-sibling-inspector make-special-comment "\
        "make-srcloc make-string make-struct-field-accessor "\
        "make-struct-field-mutator make-struct-type make-struct-type-property "\
        "make-syntax-delta-introducer make-syntax-introducer "\
        "make-temporary-file make-tentative-pretty-print-output-port "\
        "make-thread-cell make-thread-group make-vector make-weak-box "\
        "make-weak-custom-hash make-weak-custom-set make-weak-hash "\
        "make-weak-hasheq make-weak-hasheqv make-will-executor map "\
        "match-equality-test max mcar mcdr mcons member "\
        "member-name-key-hash-code memf memq memv merge-input min "\
        "mixin-contract module->exports module->imports "\
        "module->indirect-exports module->language-info module->namespace "\
        "module-compiled-exports module-compiled-imports "\
        "module-compiled-indirect-exports module-compiled-language-info "\
        "module-compiled-name module-compiled-submodules module-path-index-join "\
        "module-path-index-resolve module-path-index-split "\
        "module-path-index-submodule modulo mutable-set "\
        "mutable-seteq mutable-seteqv n->th nack-guard-evt "\
        "namespace-anchor->empty-namespace namespace-anchor->namespace "\
        "namespace-attach-module namespace-attach-module-declaration "\
        "namespace-base-phase namespace-mapped-symbols namespace-module-identifier "\
        "namespace-module-registry namespace-require namespace-require/constant "\
        "namespace-require/copy namespace-require/expansion-time "\
        "namespace-set-variable-value! namespace-symbol->identifier "\
        "namespace-syntax-introduce namespace-undefine-variable! "\
        "namespace-unprotect-module namespace-variable-value "\
        "natural-number/c negate never-evt new-∀/c new-∃/c newline ninth "\
        "non-empty-listof none/c normal-case-path normalize-arity "\
        "normalize-path not not/c null number->string numerator "\
        "object->vector object-info object-interface object-name "\
        "object=-hash-code one-of/c open-input-bytes open-input-file "\
        "open-input-output-file open-input-string open-output-bytes "\
        "open-output-file open-output-nowhere open-output-string or/c "\
        "order-of-magnitude ormap other-execute-bit other-read-bit "\
        "other-write-bit parameter/c parse-command-line partition path->bytes "\
        "path->complete-path path->directory-path path->string "\
        "path-add-extension path-add-suffix path-convention-type "\
        "path-element->bytes path-element->string path-get-extension "\
        "path-list-string->path-list path-only path-replace-extension "\
        "path-replace-suffix pathlist-closure peek-byte peek-byte-or-special "\
        "peek-bytes peek-bytes! peek-bytes!-evt peek-bytes-avail! "\
        "peek-bytes-avail!* peek-bytes-avail!-evt "\
        "peek-bytes-avail!/enable-break peek-bytes-evt "\
        "peek-char peek-char-or-special peek-string peek-string! "\
        "peek-string!-evt peek-string-evt peeking-input-port permutations "\
        "pi pi.f pipe-content-length place-break place-channel "\
        "place-channel-get place-channel-put place-channel-put/get "\
        "place-dead-evt place-kill place-wait placeholder-get placeholder-set! "\
        "plumber-add-flush! plumber-flush-all plumber-flush-handle-remove! "\
        "poll-guard-evt port->bytes port->bytes-lines port->lines "\
        "port->list port->string port-closed-evt port-commit-peeked "\
        "port-count-lines! port-count-lines-enabled port-display-handler "\
        "port-file-identity port-file-unlock port-next-location "\
        "port-print-handler port-progress-evt port-read-handler "\
        "port-write-handler predicate/c prefab-key->struct-type "\
        "prefab-struct-key preferences-lock-file-mode pregexp pretty-display "\
        "pretty-format pretty-print pretty-print-.-symbol-without-bars "\
        "pretty-print-abbreviate-read-macros pretty-print-columns "\
        "pretty-print-current-style-table pretty-print-depth "\
        "pretty-print-exact-as-decimal pretty-print-extend-style-table "\
        "pretty-print-handler pretty-print-newline pretty-print-post-print-hook "\
        "pretty-print-pre-print-hook pretty-print-print-hook "\
        "pretty-print-print-line pretty-print-remap-stylable "\
        "pretty-print-show-inexactness pretty-print-size-hook "\
        "pretty-printing pretty-write primitive-result-arity print "\
        "print-as-expression print-boolean-long-form print-box print-graph "\
        "print-hash-table print-mpair-curly-braces print-pair-curly-braces "\
        "print-reader-abbreviations print-struct print-syntax-width "\
        "print-unreadable print-vector-length printable/c printf "\
        "println procedure->method procedure-arity procedure-arity-includes/c "\
        "procedure-arity-mask procedure-extract-target "\
        "procedure-keywords procedure-reduce-arity "\
        "procedure-reduce-arity-mask procedure-reduce-keyword-arity "\
        "procedure-reduce-keyword-arity-mask procedure-rename "\
        "procedure-result-arity procedure-specialize "\
        "process process* process*/ports process/ports "\
        "processor-count promise/c prop:arity-string prop:arrow-contract "\
        "prop:arrow-contract-get-info prop:authentic "\
        "prop:blame prop:chaperone-contract prop:checked-procedure "\
        "prop:contract prop:contracted prop:custom-print-quotable "\
        "prop:custom-write prop:dict prop:dict/contract prop:equal+hash "\
        "prop:evt prop:exn:missing-module prop:exn:srclocs "\
        "prop:expansion-contexts prop:flat-contract prop:impersonator-of "\
        "prop:input-port prop:liberal-define-context prop:object-name "\
        "prop:orc-contract prop:orc-contract-get-subcontracts "\
        "prop:output-port prop:place-location prop:procedure "\
        "prop:recursive-contract prop:recursive-contract-unroll "\
        "prop:rename-transformer prop:sequence prop:set!-transformer "\
        "prop:stream pseudo-random-generator->vector put-preferences "\
        "putenv quotient quotient/remainder", builtins_three);

        split( \
        "radians->degrees raise raise-argument-error "\
        "raise-arguments-error raise-arity-error raise-arity-mask-error "\
        "raise-blame-error raise-contract-error raise-mismatch-error "\
        "raise-not-cons-blame-error raise-range-error raise-result-arity-error "\
        "raise-result-error raise-syntax-error raise-type-error "\
        "raise-user-error random random-seed range rationalize read "\
        "read-accept-bar-quote read-accept-box read-accept-compiled "\
        "read-accept-dot read-accept-graph read-accept-infix-dot "\
        "read-accept-lang read-accept-quasiquote read-accept-reader read-byte "\
        "read-byte-or-special read-bytes read-bytes! read-bytes!-evt "\
        "read-bytes-avail! read-bytes-avail!* read-bytes-avail!-evt "\
        "read-bytes-avail!/enable-break read-bytes-evt read-bytes-line "\
        "read-bytes-line-evt read-case-sensitive read-cdot read-char "\
        "read-char-or-special read-curly-brace-as-paren "\
        "read-curly-brace-with-tag read-decimal-as-inexact read-eval-print-loop "\
        "read-language read-line read-line-evt read-on-demand-source "\
        "read-square-bracket-as-paren read-square-bracket-with-tag read-string "\
        "read-string! read-string!-evt read-string-evt read-syntax "\
        "read-syntax/recursive read/recursive readtable-mapping "\
        "real->decimal-string real->double-flonum real->floating-point-bytes "\
        "real->single-flonum real-in real-part reencode-input-port "\
        "reencode-output-port regexp regexp-match regexp-match* "\
        "regexp-match-evt regexp-match-peek "\
        "regexp-match-peek-immediate regexp-match-peek-positions "\
        "regexp-match-peek-positions* regexp-match-peek-positions-immediate "\
        "regexp-match-peek-positions-immediate/end "\
        "regexp-match-peek-positions/end regexp-match-positions "\
        "regexp-match-positions* regexp-match-positions/end regexp-match/end "\
        "regexp-max-lookbehind regexp-quote regexp-replace "\
        "regexp-replace* regexp-replace-quote regexp-replaces regexp-split "\
        "regexp-try-match relocate-input-port "\
        "relocate-output-port remainder remf remf* remove remove* "\
        "remove-duplicates remq remq* remv remv* rename-contract "\
        "rename-file-or-directory rename-transformer-target "\
        "replace-evt reroot-path resolve-path resolved-module-path-name "\
        "rest reverse round second seconds->date semaphore-peek-evt semaphore-post "\
        "semaphore-wait semaphore-wait/enable-break sequence->list "\
        "sequence->stream sequence-add-between "\
        "sequence-andmap sequence-append sequence-count sequence-filter "\
        "sequence-fold sequence-for-each sequence-generate sequence-generate* "\
        "sequence-length sequence-map sequence-ormap sequence-ref sequence-tail "\
        "sequence/c set set!-transformer-procedure set->list set->stream "\
        "set-add set-add! set-box! set-box*! set-clear set-clear! set-copy "\
        "set-copy-clear set-count set-first set-for-each set-implements/c "\
        "set-intersect set-intersect! set-map set-mcar! set-mcdr! "\
        "set-phantom-bytes! set-port-next-location! set-remove set-remove! "\
        "set-rest set-subtract set-subtract! set-symmetric-difference "\
        "set-symmetric-difference! set-union set-union! set/c seteq seteqv seventh "\
        "sgn sha1-bytes sha224-bytes sha256-bytes shared-bytes shell-execute "\
        "shrink-path-wrt shuffle simple-form-path simplify-path sin "\
        "sinh sixth sleep some-system-path->string sort special-comment-value "\
        "special-filter-input-port split-at split-at-right split-common-prefix "\
        "split-path splitf-at splitf-at-right sqr sqrt srcloc srcloc->string "\
        "srcloc-column srcloc-line srcloc-position srcloc-source srcloc-span "\
        "stop-after stop-before stream->list stream-add-between "\
        "stream-andmap stream-append stream-count stream-filter "\
        "stream-first stream-fold stream-for-each stream-length stream-map "\
        "stream-ormap stream-ref stream-rest stream-tail stream-take stream/c "\
        "string string->bytes/latin-1 string->bytes/locale "\
        "string->bytes/utf-8 string->immutable-string string->keyword "\
        "string->list string->number string->path string->path-element "\
        "string->some-system-path string->symbol string->uninterned-symbol "\
        "string->unreadable-symbol string-append string-append* "\
        "string-copy string-copy! string-downcase string-fill! string-foldcase "\
        "string-join string-len/c string-length string-locale-downcase "\
        "string-locale-upcase string-normalize-nfc string-normalize-nfd "\
        "string-normalize-nfkc string-normalize-nfkd string-normalize-spaces "\
        "string-ref string-replace string-set! "\
        "string-split string-titlecase string-trim string-upcase "\
        "string-utf-8-length struct->vector struct-info struct-type-info "\
        "struct-type-make-constructor struct-type-make-predicate "\
        "struct-type-property/c struct:arity-at-least "\
        "struct:arrow-contract-info struct:date struct:date* struct:exn "\
        "struct:exn:break struct:exn:break:hang-up struct:exn:break:terminate "\
        "struct:exn:fail struct:exn:fail:contract "\
        "struct:exn:fail:contract:arity struct:exn:fail:contract:blame "\
        "struct:exn:fail:contract:continuation "\
        "struct:exn:fail:contract:divide-by-zero "\
        "struct:exn:fail:contract:non-fixnum-result "\
        "struct:exn:fail:contract:variable struct:exn:fail:filesystem "\
        "struct:exn:fail:filesystem:errno struct:exn:fail:filesystem:exists "\
        "struct:exn:fail:filesystem:missing-module "\
        "struct:exn:fail:filesystem:version struct:exn:fail:network "\
        "struct:exn:fail:network:errno struct:exn:fail:object "\
        "struct:exn:fail:out-of-memory struct:exn:fail:read "\
        "struct:exn:fail:read:eof struct:exn:fail:read:non-char "\
        "struct:exn:fail:syntax struct:exn:fail:syntax:missing-module "\
        "struct:exn:fail:syntax:unbound struct:exn:fail:unsupported "\
        "struct:exn:fail:user struct:srcloc struct:wrapped-extra-arg-arrow "\
        "sub1 subbytes subprocess subprocess-group-enabled subprocess-kill "\
        "subprocess-pid subprocess-status subprocess-wait substring "\
        "suggest/c symbol->string symbols sync sync/enable-break sync/timeout "\
        "sync/timeout/enable-break syntax->datum syntax->list syntax-arm "\
        "syntax-binding-set syntax-binding-set->syntax "\
        "syntax-binding-set-extend syntax-column "\
        "syntax-debug-info syntax-disarm syntax-e syntax-line "\
        "syntax-local-bind-syntaxes syntax-local-certifier syntax-local-context "\
        "syntax-local-expand-expression syntax-local-get-shadower "\
        "syntax-local-identifier-as-binding syntax-local-introduce "\
        "syntax-local-lift-context syntax-local-lift-expression "\
        "syntax-local-lift-module syntax-local-lift-module-end-declaration "\
        "syntax-local-lift-provide syntax-local-lift-require "\
        "syntax-local-lift-values-expression "\
        "syntax-local-make-definition-context "\
        "syntax-local-make-delta-introducer "\
        "syntax-local-module-defined-identifiers syntax-local-module-exports "\
        "syntax-local-module-required-identifiers syntax-local-name "\
        "syntax-local-phase-level syntax-local-submodules "\
        "syntax-local-value syntax-local-value/immediate syntax-position "\
        "syntax-property syntax-property-remove "\
        "syntax-property-symbol-keys syntax-protect syntax-rearm "\
        "syntax-recertify syntax-shift-phase-level syntax-source "\
        "syntax-source-module syntax-span syntax-taint "\
        "syntax-track-origin syntax/c "\
        "system system* system*/exit-code system-idle-evt "\
        "system-language+country system-library-subpath "\
        "system-path-convention-type system-type system/exit-code "\
        "take take-common-prefix take-right takef takef-right "\
        "tan tanh tcp-abandon-port tcp-accept tcp-accept-evt "\
        "tcp-accept/enable-break tcp-addresses tcp-close tcp-connect "\
        "tcp-connect/enable-break tcp-listen "\
        "tentative-pretty-print-port-cancel "\
        "tentative-pretty-print-port-transfer tenth "\
        "the-unsupplied-arg third thread thread-cell-ref thread-cell-set! "\
        "thread-dead-evt thread-receive thread-receive-evt thread-resume "\
        "thread-resume-evt thread-rewind-receive thread-send "\
        "thread-suspend thread-suspend-evt thread-try-receive thread-wait "\
        "thread/suspend-to-kill time-apply touch transplant-input-port "\
        "transplant-output-port true truncate udp-addresses udp-bind! "\
        "udp-close udp-connect! "\
        "udp-multicast-interface udp-multicast-join-group! "\
        "udp-multicast-leave-group! "\
        "udp-multicast-set-interface! udp-multicast-set-loopback! "\
        "udp-multicast-set-ttl! udp-multicast-ttl udp-open-socket udp-receive! "\
        "udp-receive!* udp-receive!-evt udp-receive!/enable-break "\
        "udp-receive-ready-evt udp-send udp-send* udp-send-evt "\
        "udp-send-ready-evt udp-send-to udp-send-to* udp-send-to-evt "\
        "udp-send-to/enable-break udp-send/enable-break "\
        "udp-set-receive-buffer-size! unbox unbox* "\
        "uncaught-exception-handler unquoted-printing-string "\
        "unquoted-printing-string-value "\
        "unspecified-dom use-collection-link-paths "\
        "use-compiled-file-check use-compiled-file-paths "\
        "use-user-specific-search-paths user-execute-bit user-read-bit "\
        "user-write-bit", builtins_four);

        split( \
        "value-blame value-contract values variable-reference->empty-namespace "\
        "variable-reference->module-base-phase "\
        "variable-reference->module-declaration-inspector "\
        "variable-reference->module-path-index "\
        "variable-reference->module-source variable-reference->namespace "\
        "variable-reference->phase variable-reference->resolved-module-path "\
        "vector vector*-length vector*-ref vector*-set! "\
        "vector->immutable-vector vector->list vector->pseudo-random-generator "\
        "vector->pseudo-random-generator! vector->values vector-append "\
        "vector-argmax vector-argmin vector-cas! vector-copy vector-copy! "\
        "vector-count vector-drop vector-drop-right vector-fill! vector-filter "\
        "vector-filter-not vector-immutable vector-immutable/c "\
        "vector-immutableof vector-length vector-map vector-map! vector-member "\
        "vector-memq vector-memv vector-ref vector-set! vector-set*! "\
        "vector-set-performance-stats! vector-sort vector-sort! vector-split-at "\
        "vector-split-at-right vector-take vector-take-right vector/c "\
        "vectorof version void weak-box-value weak-set "\
        "weak-seteq weak-seteqv will-execute will-register "\
        "will-try-execute with-input-from-bytes with-input-from-file "\
        "with-input-from-string with-output-to-bytes with-output-to-file "\
        "with-output-to-string would-be-future wrap-evt wrapped-extra-arg-arrow "\
        "wrapped-extra-arg-arrow-extra-neg-party-argument "\
        "wrapped-extra-arg-arrow-real-func "\
        "write write-byte write-bytes write-bytes-avail write-bytes-avail* "\
        "write-bytes-avail-evt write-bytes-avail/enable-break write-char "\
        "write-special write-special-avail* write-special-evt write-string "\
        "write-to-file writeln xor ~.a ~.s ~.v ~a ~e ~r ~s ~v", builtins_five);

        split("implementation?/c is-a?/c subclass?/c", builtins_six);

        split( \
        "< <= = > >= ~? zero? wrapped-extra-arg-arrow? will-executor? weak-box? "\
        "void? vector? variable-reference? variable-reference-from-unsafe? "\
        "variable-reference-constant? unsupplied-arg? unquoted-printing-string? "\
        "unit? udp? udp-multicast-loopback? udp-connected? udp-bound? thread? "\
        "thread-running? thread-group? thread-dead? thread-cell? "\
        "thread-cell-values? terminal-port? tcp-port? tcp-listener? "\
        "tcp-accept-ready? tail-marks-match? system-big-endian? syntax? "\
        "syntax-transforming? syntax-transforming-with-lifts? "\
        "syntax-transforming-module-expression? syntax-tainted? "\
        "syntax-property-preserved? syntax-original? "\
        "syntax-local-transforming-module-provides? syntax-binding-set? symbol? "\
        "symbol=? symbol<? symbol-unreadable? symbol-interned? subset? "\
        "subprocess? subclass? struct? struct-type? struct-type-property? "\
        "struct-type-property-accessor-procedure? struct-predicate-procedure? "\
        "struct-mutator-procedure? struct-constructor-procedure? "\
        "struct-accessor-procedure? string? string>? string>=? string=? "\
        "string<? string<=? string-suffix? string-prefix? string-port? "\
        "string-no-nuls? string-locale>? string-locale=? string-locale<? "\
        "string-locale-ci>? string-locale-ci=? string-locale-ci<? "\
        "string-environment-variable-name? string-contains? string-ci>? "\
        "string-ci>=? string-ci=? string-ci<? string-ci<=? stream? stream-empty? "\
        "srcloc? special-comment? skip-projection-wrapper? single-flonum? set? "\
        "set=? set-weak? set-mutable? set-member? set-implements? set-eqv? "\
        "set-equal? set-eq? set-empty? set!-transformer? sequence? semaphore? "\
        "semaphore-try-wait? semaphore-peek-evt? security-guard? "\
        "resolved-module-path? rename-transformer? relative-path? regexp? "\
        "regexp-match? regexp-match-exact? real? readtable? rational? "\
        "pseudo-random-generator? pseudo-random-generator-vector? proper-subset? "\
        "prop:recursive-contract? prop:orc-contract? prop:arrow-contract? promise? "\
        "promise/name? promise-running? promise-forced? progress-evt? procedure? "\
        "procedure-struct-type? procedure-impersonator*? "\
        "procedure-closure-contents-eq? procedure-arity? procedure-arity-includes? "\
        "primitive? primitive-closure? pretty-print-style-table? pregexp? "\
        "prefab-key? positive? positive-integer? port? port-writes-special? "\
        "port-writes-atomic? port-try-file-lock? port-provides-progress-evts? "\
        "port-number? port-counts-lines? port-closed? plumber? "\
        "plumber-flush-handle? placeholder? place? place-message-allowed? "\
        "place-location? place-enabled? place-channel? phantom-bytes? path? "\
        "path<? path-string? path-has-extension? path-for-some-system? "\
        "path-element? parameterization? parameter? parameter-procedure=? pair? "\
        "output-port? odd? object? object=? object-or-false=? "\
        "object-method-arity-includes? number? null? normalized-arity? "\
        "nonpositive-integer? nonnegative-integer? non-empty-string? negative? "\
        "negative-integer? natural? nan? namespace? namespace-anchor? mpair? "\
        "module-provide-protected? module-predefined? module-path? "\
        "module-path-index? module-declared? "\
        "module-compiled-cross-phase-persistent? method-in-interface? "\
        "member-name-key? member-name-key=? matches-arity-exactly? logger? "\
        "log-receiver? log-level? listen-port-number? list? list-prefix? "\
        "list-contract? link-exists? liberal-define-context? keyword? keyword<? "\
        "is-a? internal-definition-context? interface? interface-extension? "\
        "integer? inspector? inspector-superior? input-port? infinite? inexact? "\
        "inexact-real? implementation? impersonator? impersonator-property? "\
        "impersonator-property-accessor-procedure? impersonator-of? "\
        "impersonator-contract? immutable? identifier? hash? hash-weak? "\
        "hash-placeholder? hash-keys-subset? hash-has-key? hash-eqv? "\
        "hash-equal? hash-eq? hash-empty? has-contract? has-blame? handle-evt? "\
        "generic? generic-set? futures-enabled? future? fsemaphore? "\
        "fsemaphore-try-wait? free-transformer-identifier=? "\
        "free-template-identifier=? free-label-identifier=? free-identifier=? "\
        "flonum? flat-contract? flat-contract-property? fixnum? "\
        "filesystem-change-evt? file-stream-port? file-exists? field-bound? "\
        "false? exn? exn:srclocs? exn:missing-module? exn:misc:match? exn:fail? "\
        "exn:fail:user? exn:fail:unsupported? exn:fail:syntax? "\
        "exn:fail:syntax:unbound? exn:fail:syntax:missing-module? exn:fail:read? "\
        "exn:fail:read:non-char? exn:fail:read:eof? exn:fail:out-of-memory? "\
        "exn:fail:object? exn:fail:network? exn:fail:network:errno? "\
        "exn:fail:filesystem? exn:fail:filesystem:version? "\
        "exn:fail:filesystem:missing-module? exn:fail:filesystem:exists? "\
        "exn:fail:filesystem:errno? exn:fail:contract? exn:fail:contract:variable? "\
        "exn:fail:contract:non-fixnum-result? exn:fail:contract:divide-by-zero? "\
        "exn:fail:contract:continuation? exn:fail:contract:blame? "\
        "exn:fail:contract:arity? exn:break? exn:break:terminate? "\
        "exn:break:hang-up? exact? exact-positive-integer? "\
        "exact-nonnegative-integer? exact-integer? evt? even? eqv? equal?/equal? "\
        "equal-contract? eq-contract? ephemeron? eof-object? environment-variables? "\
        "empty? double-flonum? directory-exists? dict? dict-mutable? dict-implements? "\
        "dict-has-key? dict-empty? dict-can-remove-keys? dict-can-functional-set? "\
        "date? date-dst? date*? custom-write? custom-print-quotable? custodian? "\
        "custodian-shut-down? custodian-memory-accounting-available? custodian-box? "\
        "contract? contract-struct-list-contract? contract-stronger? "\
        "contract-random-generate-fail? contract-random-generate-env? "\
        "contract-property? contract-first-order-passes? contract-equivalent? "\
        "continuation? continuation-prompt-tag? continuation-prompt-available? "\
        "continuation-mark-set? continuation-mark-key? cons? complex? complete-path? "\
        "compiled-module-expression? compiled-expression? compile-target-machine? "\
        "class? char? char>? char>=? char=? char<? char<=? char-whitespace? "\
        "char-upper-case? char-title-case? char-symbolic? char-ready? "\
        "char-punctuation? char-numeric? char-lower-case? char-iso-control? "\
        "char-graphic? char-ci>? char-ci>=? char-ci=? char-ci<? char-ci<=? "\
        "char-blank? char-alphabetic? chaperone? chaperone-of? chaperone-contract? "\
        "chaperone-contract-property? channel? channel-put-evt? bytes? bytes>? "\
        "bytes=? bytes<? bytes-no-nuls? bytes-environment-variable-name? "\
        "bytes-converter? byte? byte-regexp? byte-ready? byte-pregexp? "\
        "break-parameterization? box? bound-identifier=? boolean? boolean=? "\
        "blame? blame-swapped? blame-original? blame-missing-party? "\
        "bitwise-bit-set? base->? arrow-contract-info? arity=? arity-includes? "\
        "arity-at-least? absolute-path?", predicates);

        non_word_chars="[\\s\\(\\)\\[\\]\\{\\};\\|]";

        normal_identifiers="-!$%&\\*\\+\\./:<=>\\?\\^_~a-zA-Z0-9";
        identifier_chars="[" normal_identifiers "][" normal_identifiers ",#]*";
    }
    function add_highlighter(regex, highlight) {
        printf("add-highlighter shared/racket/code/ regex \"%s\" %s\n", regex, highlight);
    }
    function quoted_join(words, quoted, first) {
        first=1
        for (i in words) {
            if (!first) { quoted=quoted "|"; }
            quoted=quoted "\\Q" words[i] "\\E";
            first=0;
        }
        return quoted;
    }
    function add_word_highlighter(words, face, regex) {
        regex = non_word_chars "+(" quoted_join(words) ")" non_word_chars;
        add_highlighter(regex, "1:" face);
    }
    function print_words(words) {
        for (i in words) { printf(" %s", words[i]); }
    }

    BEGIN {
        printf("declare-option str-list racket_static_words ");
        print_words(operators);
        print_words(keywords);
        print_words(builtins_one);
        print_words(builtins_two);
        print_words(builtins_three);
        print_words(builtins_four);
        print_words(builtins_five);
        print_words(builtins_six);
        print_words(predicates);
        printf("\n");

        add_word_highlighter(operators, "operator");
        add_word_highlighter(keywords, "keyword");
        add_word_highlighter(builtins_one, "meta");
        add_word_highlighter(builtins_two, "meta");
        add_word_highlighter(builtins_three, "meta");
        add_word_highlighter(builtins_four, "meta");
        add_word_highlighter(builtins_five, "meta");
        add_word_highlighter(builtins_six, "meta");
        add_word_highlighter(predicates, "value");

        add_highlighter(non_word_chars "+('" identifier_chars ")", "1:attribute");
        add_highlighter("\\(define\\W+\\((" identifier_chars ")", "1:attribute");
        add_highlighter("\\(define\\W+(" identifier_chars ")\\W+\\(lambda", "1:attribute");
    }
EOF
}
# --------------------------------------------------------------------------------------------------- #
§
