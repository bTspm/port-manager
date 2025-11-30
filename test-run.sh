#!/bin/bash
echo "Starting Port Manager..."
echo "Click the menu bar icon within 10 seconds..."
./PortManager.app/Contents/MacOS/PortManager 2>&1 &
PID=$!
sleep 10
if ps -p $PID > /dev/null; then
    echo "App is still running, killing it..."
    kill $PID
else
    echo "App crashed or exited"
fi
