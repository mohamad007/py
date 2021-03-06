# Launch otouto, after checking for Lua 5.3.
# Restart otouto five seconds after halted.

#!/bin/sh

# Ubuntu 16.04 seems to not link "lua" to lua5.3.
if type lua5.3 >/dev/null 2>/dev/null; then
    while true; do
        lua5.3 main.lua
        echo "otouto has stopped. ^C to exit."
        sleep 5s
    done
else
    echo "Lua 5.3 was not found."
    echo "If you're on Ubuntu 16.04+, try running ./install-dependencies.sh."
fi
