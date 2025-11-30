#!/bin/bash
echo "Starting Port Manager with logging..."
./PortManager.app/Contents/MacOS/PortManager > /tmp/portmanager-debug.log 2>&1 &
APP_PID=$!
echo "App started with PID: $APP_PID"
echo "Log file: /tmp/portmanager-debug.log"
echo ""
echo "Now click the menu bar icon..."
echo "Watching for 15 seconds..."

for i in {1..15}; do
    sleep 1
    if ! ps -p $APP_PID > /dev/null 2>&1; then
        echo ""
        echo "❌ App crashed after $i seconds!"
        echo ""
        echo "=== LOG OUTPUT ==="
        cat /tmp/portmanager-debug.log
        echo "=================="
        exit 1
    fi
    echo -n "."
done

echo ""
echo "✅ App is still running after 15 seconds"
echo ""
echo "=== LOG OUTPUT ==="
cat /tmp/portmanager-debug.log
echo "=================="

kill $APP_PID 2>/dev/null
