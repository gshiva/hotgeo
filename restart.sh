#!/bin/bash

# HotGeo Flutter Restart Script
# Reliably kills all flutter processes and restarts on port 3000

echo "🛑 Stopping all Flutter processes..."
pkill -9 -f "flutter run" 2>/dev/null || true
pkill -9 -f "dart:io" 2>/dev/null || true

echo "🔌 Clearing port 3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

echo "⏳ Waiting for cleanup..."
sleep 3

echo "🚀 Starting Flutter on port 3000..."
flutter run -d chrome --web-port=3000
