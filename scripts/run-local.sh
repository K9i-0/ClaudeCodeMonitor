#!/bin/bash

# Script to run the app locally with helper

echo "🚀 Starting Claude Code Monitor (Development Mode)"

# Kill any existing instances
echo "Cleaning up existing processes..."
killall ClaudeCodeMonitor 2>/dev/null || true
killall ClaudeMonitorHelper 2>/dev/null || true

# Wait a bit for processes to fully terminate
sleep 1

# Check if app bundle exists
if [ ! -d "ClaudeCodeMonitor.app" ]; then
  echo "❌ App bundle not found. Please run ./scripts/build-local.sh first"
  exit 1
fi

# Start the helper in background
echo "Starting helper service..."
./ClaudeCodeMonitor.app/Contents/Library/LaunchServices/ClaudeMonitorHelper &
HELPER_PID=$!

# Wait for helper to start
sleep 2

# Check if helper is running
if ! kill -0 $HELPER_PID 2>/dev/null; then
  echo "❌ Failed to start helper service"
  exit 1
fi

# Check helper health
if curl -s http://127.0.0.1:8456/health | grep -q "ok"; then
  echo "✅ Helper service is running"
else
  echo "⚠️  Helper service started but not responding"
fi

# Start the main app
echo "Starting main application..."
open ClaudeCodeMonitor.app

echo ""
echo "✅ Application started!"
echo ""
echo "To stop both processes:"
echo "  killall ClaudeCodeMonitor ClaudeMonitorHelper"
echo ""
echo "Helper PID: $HELPER_PID"
echo ""
echo "Script completed. Processes are running in the background."