function __fish_change_cmd -d "Change the current command"
    # If there is no commandline, insert the last item from history
    # and *then* toggle
    if not commandline | string length -q
        commandline -r "$history[1]"
    end

    set -l cmd (commandline -po)
    set -l cursor (commandline -C)

    if test (count $cmd) = "1"
        commandline -C 0
    else if test "$cmd[1]" = ""
        commandline -C 0
    else
        commandline -r (string sub --start=(math (string length "$cmd[1]") + 1) (commandline -p))
        commandline -C 0
    end
end

bind --preset -e -M insert \cs
bind -M insert \cs __fish_change_cmd
bind --preset -e -M default \cs
bind -M default \cs __fish_change_cmd
