#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Starting Python API Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python 3 is not installed!${NC}"
    echo "Please install Python 3.8+ first."
    exit 1
fi

# Check if Flask is installed
if ! python3 -c "import flask" &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Python dependencies...${NC}"
    cd python_api
    pip3 install -r requirements.txt
    cd ..
fi

# Get local IP
echo -e "${GREEN}📡 Detecting local IP address...${NC}"
LOCAL_IP=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)

if [ -z "$LOCAL_IP" ]; then
    echo -e "${YELLOW}⚠️  Could not detect local IP${NC}"
    LOCAL_IP="localhost"
fi

echo -e "${GREEN}✅ Local IP: ${LOCAL_IP}${NC}"
echo ""
echo -e "${BLUE}📱 Use this URL in your Flutter app:${NC}"
echo -e "${GREEN}   http://${LOCAL_IP}:5000${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Start the server
cd python_api
python3 server.py
