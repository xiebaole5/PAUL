#!/bin/bash
echo "=== Service Status ==="
ps aux | grep "python.*app.py" | grep -v grep || echo "Service not found"
echo ""
echo "=== Port 8080 ==="
netstat -tlnp 2>/dev/null | grep 8080 || ss -tlnp 2>/dev/null | grep 8080 || echo "Port 8080 not listening"
echo ""
echo "=== Health Check ==="
curl -s http://localhost:8080/health || echo "Health check failed"
