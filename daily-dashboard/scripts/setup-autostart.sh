#!/bin/bash
PROJECT_DIR="/home/florianh/pr2/src/M122"
MARKER="# AllMyDay autostart"

if grep -q "$MARKER" ~/.bashrc; then
    echo "Autostart ist bereits eingerichtet."
else
    cat >> ~/.bashrc << 'EOF'

# AllMyDay autostart
if ! pgrep -f "http.server 8347" > /dev/null 2>&1; then
    nohup python3 -m http.server 8347 \
        --bind 127.0.0.1 \
        --directory /home/florianh/pr2/src/M122/daily-dashboard \
        > /home/florianh/pr2/src/M122/daily-dashboard/logs/server.log 2>&1 &
    disown
fi
EOF
    echo "Autostart eingerichtet! Ab dem naechsten Ubuntu-Start laeuft der Server automatisch."
    echo "Oder jetzt sofort aktivieren mit: source ~/.bashrc"
fi
