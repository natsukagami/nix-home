alias sue="pls -e"

function pls
    set -l cmd "`"(string join " " -- $argv)"`"
    echo "I-It's not like I'm gonna run "$cmd" for you or a-anything! Baka >:C" >&2
    # Send a notification on password prompt
    if command sudo -vn 2>/dev/null
        # nothing to do, user already authenticated
    else
        # throw a notification
        # notify-send -t 3000 -u critical -i ~/Downloads/harukablush.jpg -h "STRING:command:"$cmd "A-a command requires your p-password" (printf "I-I need your p-password to r-run the following c-command: %s" $cmd)
    end        
    command sudo $argv
end

function sudo
    echo "Not polite enough."
end

function __fish_prepend_pls -d "Prepend 'pls ' to the beginning of the current commandline"
    # If there is no commandline, insert the last item from history
    # and *then* toggle
    if not commandline | string length -q
        commandline -r "$history[1]"
    end

    set -l cmd (commandline -po)
    set -l cursor (commandline -C)

    if test "$cmd[1]" = e
        commandline -C 0
        commandline -i "su"
        commandline -C (math $cursor + 2)
    else if test "$cmd[1]" = sue
        commandline -r (string sub --start=3 (commandline -p))
        commandline -C -- (math $cursor - 2)
    else if test "$cmd[1]" != pls
        commandline -C 0
        commandline -i "pls "
        commandline -C (math $cursor + 4)
    else
        commandline -r (string sub --start=5 (commandline -p))
        commandline -C -- (math $cursor - 4)
    end
end

bind --preset -e -M insert \es
bind -M insert \es __fish_prepend_pls

function __fish_man_page
    # Get all commandline tokens not starting with "-"
    set -l args (commandline -po | string match -rv '^-')

    # If commandline is empty, exit.
    if not set -q args[1]
        printf \a
        return
    end

    #Skip `pls` and display then manpage of following command
    while set -q args[2]
        and string match -qr -- '^(pls|.*=.*)$' $args[1]
        set -e args[1]
    end

    # If there are at least two tokens not starting with "-", the second one might be a subcommand.
    # Try "man first-second" and fall back to "man first" if that doesn't work out.
    set -l maincmd (basename $args[1])
    if set -q args[2]
        # HACK: If stderr is not attached to a terminal `less` (the default pager)
        # wouldn't use the alternate screen.
        # But since we don't know what pager it is, and because `man` is totally underspecified,
        # the best we can do is to *try* the man page, and assume that `man` will return false if it fails.
        # See #7863.
        if man "$maincmd-$args[2]" &>/dev/null
            man "$maincmd-$args[2]"
        else if man "$maincmd" &>/dev/null
            man "$maincmd"
        else
            printf \a
        end
    else
        if man "$maincmd" &>/dev/null
            man "$maincmd"
        else
            printf \a
        end
    end

    commandline -f repaint
end

#
# Completion for pls
#

function __fish_pls_print_remaining_args
    set -l tokens (commandline -opc) (commandline -ct)
    set -e tokens[1]
    # These are all the options mentioned in the man page for Todd Miller's "pls.ws" pls (in that order).
    # If any other implementation has different options, this should be harmless, since they shouldn't be used anyway.
    set -l opts A/askpass b/background C/close-from= E/preserve-env='?'
    # Note that "-h" is both "--host" (which takes an option) and "--help" (which doesn't).
    # But `-h` as `--help` only counts when it's the only argument (`pls -h`),
    # so any argument completion after that should take it as "--host".
    set -a opts e/edit g/group= H/set-home h/host= 1-help
    set -a opts i/login K/remove-timestamp k/reset-timestamp l/list n/non-interactive
    set -a opts P/preserve-groups p/prompt= S/stdin s/shell U/other-user=
    set -a opts u/user= T/command-timeout= V/version v/validate
    argparse -s $opts -- $tokens 2>/dev/null
    # The remaining argv is the subcommand with all its options, which is what
    # we want.
    if test -n "$argv"
        and not string match -qr '^-' $argv[1]
        string join0 -- $argv
        return 0
    else
        return 1
    end
end

function __fish_pls_no_subcommand
    not __fish_pls_print_remaining_args >/dev/null
end

function __fish_complete_pls_subcommand
    set -l args (__fish_pls_print_remaining_args | string split0)
    set -lx -a PATH /usr/local/sbin /sbin /usr/sbin
    __fish_complete_subcommand --commandline $args
end

# All these options should be valid for GNU and OSX pls
complete -c pls -n __fish_no_arguments -s h -d "Display help and exit"
complete -c pls -n __fish_no_arguments -s V -d "Display version information and exit"
complete -c pls -n __fish_pls_no_subcommand -s A -d "Ask for password via the askpass or \$SSH_ASKPASS program"
complete -c pls -n __fish_pls_no_subcommand -s C -d "Close all file descriptors greater or equal to the given number" -xa "0 1 2 255"
complete -c pls -n __fish_pls_no_subcommand -s E -d "Preserve environment"
complete -c pls -n __fish_pls_no_subcommand -s H -d "Set home"
complete -c pls -n __fish_pls_no_subcommand -s K -d "Remove the credential timestamp entirely"
complete -c pls -n __fish_pls_no_subcommand -s P -d "Preserve group vector"
complete -c pls -n __fish_pls_no_subcommand -s S -d "Read password from stdin"
complete -c pls -n __fish_pls_no_subcommand -s b -d "Run command in the background"
complete -c pls -n __fish_pls_no_subcommand -s e -rF -d Edit
complete -c pls -n __fish_pls_no_subcommand -s g -a "(__fish_complete_groups)" -x -d "Run command as group"
complete -c pls -n __fish_pls_no_subcommand -s i -d "Run a login shell"
complete -c pls -n __fish_pls_no_subcommand -s k -d "Reset or ignore the credential timestamp"
complete -c pls -n __fish_pls_no_subcommand -s l -d "List the allowed and forbidden commands for the given user"
complete -c pls -n __fish_pls_no_subcommand -s n -d "Do not prompt for a password - if one is needed, fail"
complete -c pls -n __fish_pls_no_subcommand -s p -d "Specify a custom password prompt"
complete -c pls -n __fish_pls_no_subcommand -s s -d "Run the given command in a shell"
complete -c pls -n __fish_pls_no_subcommand -s u -a "(__fish_complete_users)" -x -d "Run command as user"
complete -c pls -n __fish_pls_no_subcommand -s v -n __fish_no_arguments -d "Validate the credentials, extending timeout"

# Complete the command we are executed under pls
complete -c pls -x -n 'not __fish_seen_argument -s e' -a "(__fish_complete_pls_subcommand)"
