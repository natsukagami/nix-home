if test (pwd) = "/home/natsukagami/.config/kak"
    exit 0
end

while true
    set kakrc (pwd)/.kakrc
    if test -f $kakrc
        echo source $kakrc
    end
    if test (pwd) = "/"
        exit 0
    end
    cd ..
end
