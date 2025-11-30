#!/bin/bash
# Quick test script for web version

echo "🍋 Testing Lemon Math Web Version"
echo "=================================="

cd web || exit 1

# Check if files exist
echo "Checking files..."
[ -f "index.html" ] && echo "✅ index.html exists" || echo "❌ index.html missing"
[ -f "app.js" ] && echo "✅ app.js exists" || echo "❌ app.js missing"
[ -f "styles.css" ] && echo "✅ styles.css exists" || echo "❌ styles.css missing"

# Check for basic functionality
echo ""
echo "Checking JavaScript syntax..."
if command -v node &> /dev/null; then
    node -c app.js && echo "✅ JavaScript syntax valid" || echo "❌ JavaScript syntax error"
else
    echo "⚠️  Node.js not found - skipping JS syntax check"
fi

# Check HTML validity (basic)
echo ""
echo "Checking HTML structure..."
if grep -q "<!DOCTYPE html>" index.html; then
    echo "✅ HTML doctype found"
else
    echo "⚠️  HTML doctype missing"
fi

# Start server if Python available
echo ""
if command -v python3 &> /dev/null; then
    echo "Starting test server on http://localhost:8000"
    echo "Press Ctrl+C to stop"
    python3 -m http.server 8000
else
    echo "⚠️  Python3 not found - cannot start server"
    echo "Install Python or use another HTTP server"
fi

