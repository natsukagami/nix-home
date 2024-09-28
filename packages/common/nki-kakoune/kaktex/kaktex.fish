function usage
    echo "Usage: "
    echo "  kaktex set [client] [session]"
    echo "  kaktex jump [file] [line] [column]"
    exit 1
end

if test (count $argv) -lt 3
    usage
end

switch $argv[1]
    case "set"
        set -U _kaktex_client $argv[2]
        set -U _kaktex_session $argv[3]
    case "jump"
        echo "
                 evaluate-commands -client $_kaktex_client %{
                     evaluate-commands -try-client $_kaktex_client %{
                         edit -existing -- $argv[2] $(math $argv[3] + 1) $(math $argv[4] + 1)
                     }
                 }
             " | kak -p $_kaktex_session
    case '*'
        usage
end
