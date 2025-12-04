#!/bin/bash

# Mobile Iframe Testing Setup Script
# Tests Twake Chat smart banner in cross-origin iframe on mobile devices
# Uses local network (same WiFi) - no external services required

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
FLUTTER_PORT=8080
PARENT_PORT=8081
FLUTTER_PID_FILE="/tmp/twake_flutter_web.pid"
PARENT_PID_FILE="/tmp/twake_parent_server.pid"
TEMP_PARENT_HTML="/tmp/twake_iframe_parent.html"
LOCAL_IP=""

# Cleanup function
cleanup() {
  echo ""
  echo -e "${YELLOW}Cleaning up...${NC}"

  if [ -f "$FLUTTER_PID_FILE" ]; then
    FLUTTER_PID=$(cat "$FLUTTER_PID_FILE")
    if ps -p "$FLUTTER_PID" > /dev/null 2>&1; then
      echo "Stopping Flutter web server..."
      kill "$FLUTTER_PID" 2>/dev/null || true
    fi
    rm -f "$FLUTTER_PID_FILE"
  fi

  if [ -f "$PARENT_PID_FILE" ]; then
    PARENT_PID=$(cat "$PARENT_PID_FILE")
    if ps -p "$PARENT_PID" > /dev/null 2>&1; then
      echo "Stopping parent server..."
      kill "$PARENT_PID" 2>/dev/null || true
    fi
    rm -f "$PARENT_PID_FILE"
  fi

  rm -f "$TEMP_PARENT_HTML"
  echo -e "${GREEN}Cleanup complete!${NC}"
}

# Check dependencies and get local IP
check_dependencies() {
  echo -e "${BLUE}[1/5]${NC} Getting local IP address..."
  LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

  if [ -z "$LOCAL_IP" ]; then
    echo -e "${RED}✗ Could not determine local IP address${NC}"
    echo "Make sure you're connected to WiFi"
    exit 1
  fi
  echo -e "${GREEN}✓ Local IP: $LOCAL_IP${NC}"

  echo -e "${BLUE}[2/5]${NC} Checking for Flutter..."
  if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Flutter is available${NC}"
}

# Check if ports are available
check_ports() {
  echo -e "${BLUE}[3/5]${NC} Checking if ports are available..."
  for port in $FLUTTER_PORT $PARENT_PORT; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
      echo -e "${YELLOW}⚠ Port $port is already in use${NC}"
      lsof -ti:$port | xargs kill -9 2>/dev/null || true
      sleep 1
    fi
  done
  echo -e "${GREEN}✓ Ports are available${NC}"
}

# Start Flutter web server
start_flutter_server() {
  echo -e "${BLUE}[4/5]${NC} Starting Flutter web server on port $FLUTTER_PORT..."
  echo -e "${YELLOW}This may take a minute...${NC}"

  flutter run -d web-server \
    --web-hostname=0.0.0.0 \
    --web-port=$FLUTTER_PORT \
    > /tmp/flutter_web.log 2>&1 &

  FLUTTER_PID=$!
  echo $FLUTTER_PID > "$FLUTTER_PID_FILE"
  echo -e "${GREEN}✓ Flutter server started (PID: $FLUTTER_PID)${NC}"

  echo -e "${BLUE}Waiting for Flutter to be ready...${NC}"
  local max_wait=60
  local waited=0

  while [ $waited -lt $max_wait ]; do
    if grep -q "Serving" /tmp/flutter_web.log 2>/dev/null || \
       curl -s http://localhost:$FLUTTER_PORT >/dev/null 2>&1; then
      echo -e "${GREEN}✓ Flutter web server is ready${NC}"
      return 0
    fi

    if ! ps -p $FLUTTER_PID > /dev/null 2>&1; then
      echo -e "${RED}✗ Flutter server failed to start${NC}"
      cat /tmp/flutter_web.log
      exit 1
    fi

    sleep 1
    waited=$((waited + 1))
    printf "."
  done

  echo -e "${RED}✗ Timeout waiting for Flutter server${NC}"
  exit 1
}

# Create parent HTML page
create_parent_page() {
  echo ""
  echo -e "${BLUE}[5/5]${NC} Creating iframe parent page..."
  local flutter_url="http://$LOCAL_IP:$FLUTTER_PORT"

  cat > "$TEMP_PARENT_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Twake Chat - Iframe Test</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 10px;
    }
    .container { max-width: 100%; margin: 0 auto; }
    .header {
      background: rgba(255, 255, 255, 0.95);
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 15px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .header h1 { font-size: 20px; color: #333; margin-bottom: 5px; }
    .header p { font-size: 14px; color: #666; }
    .info-box {
      background: rgba(255, 243, 205, 0.95);
      border: 2px solid #ffc107;
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 15px;
      font-size: 14px;
      line-height: 1.6;
    }
    .info-box strong { color: #f57c00; display: block; margin-bottom: 8px; }
    .info-box ul { margin-left: 20px; margin-top: 8px; }
    .info-box li { margin-bottom: 5px; }
    .sandbox-info {
      background: rgba(232, 245, 253, 0.95);
      border: 2px solid #2196F3;
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 15px;
      font-size: 13px;
    }
    .sandbox-info .label { font-weight: bold; color: #1976D2; margin-bottom: 5px; }
    .sandbox-info .value {
      color: #666;
      font-family: monospace;
      font-size: 12px;
      background: white;
      padding: 8px;
      border-radius: 5px;
      margin-top: 5px;
      overflow-x: auto;
    }
    .controls {
      background: rgba(255, 255, 255, 0.95);
      padding: 15px;
      border-radius: 10px;
      margin-bottom: 15px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .controls label {
      display: block;
      margin-bottom: 10px;
      font-size: 14px;
      font-weight: 600;
      color: #333;
    }
    .controls select {
      width: 100%;
      padding: 10px;
      border: 2px solid #ddd;
      border-radius: 5px;
      font-size: 14px;
      background: white;
    }
    .controls button {
      width: 100%;
      background: #667eea;
      color: white;
      border: none;
      padding: 12px;
      border-radius: 5px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 10px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    .controls button:active { transform: translateY(1px); }
    .iframe-container {
      background: white;
      border-radius: 10px;
      overflow: hidden;
      box-shadow: 0 8px 16px rgba(0,0,0,0.2);
    }
    .iframe-label {
      background: #333;
      color: white;
      padding: 8px 15px;
      font-size: 12px;
      font-weight: 600;
    }
    iframe {
      width: 100%;
      height: calc(100vh - 420px);
      min-height: 500px;
      border: none;
      display: block;
    }
    @media (min-width: 768px) {
      body { padding: 20px; }
      .header h1 { font-size: 24px; }
      iframe { height: calc(100vh - 450px); }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🧪 Third-Party Iframe Test</h1>
      <p>Testing Twake Chat in cross-origin iframe</p>
    </div>
    <div class="info-box">
      <strong>📱 What to test:</strong>
      <ul>
        <li>Click the smart banner's "Open" button below</li>
        <li>Check if a new tab/window opens</li>
        <li>Try different sandbox policies to see behavior changes</li>
      </ul>
    </div>
    <div class="sandbox-info">
      <div class="label">Current Sandbox Policy:</div>
      <div class="value" id="currentPolicy">Loading...</div>
    </div>
    <div class="controls">
      <label>🔒 Iframe Sandbox Policy:</label>
      <select id="sandboxPolicy">
        <option value="allow-same-origin allow-scripts allow-forms">
          Restrictive (no popups) - Most realistic
        </option>
        <option value="allow-same-origin allow-scripts allow-forms allow-popups">
          Allow popups
        </option>
        <option value="allow-same-origin allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox">
          Allow popups + escape sandbox
        </option>
        <option value="">No sandbox (full permissions)</option>
      </select>
      <button onclick="reloadIframe()">🔄 Apply & Reload</button>
    </div>
    <div class="iframe-container">
      <div class="iframe-label">⬇️ Twake Chat (Embedded in Iframe)</div>
      <div id="iframeContainer"></div>
    </div>
  </div>
  <script>
    const FLUTTER_URL = 'FLUTTER_URL_PLACEHOLDER';
    function reloadIframe() {
      const sandbox = document.getElementById('sandboxPolicy').value;
      const container = document.getElementById('iframeContainer');
      const policyDisplay = document.getElementById('currentPolicy');
      container.innerHTML = '';
      const iframe = document.createElement('iframe');
      iframe.src = FLUTTER_URL;
      if (sandbox) {
        iframe.setAttribute('sandbox', sandbox);
        policyDisplay.textContent = sandbox;
      } else {
        policyDisplay.textContent = 'None (full access)';
      }
      iframe.setAttribute('allow', 'camera; microphone; fullscreen');
      container.appendChild(iframe);
      console.log(`[Parent] Iframe reloaded with sandbox: ${sandbox || 'none'}`);
    }
    window.addEventListener('load', () => { reloadIframe(); });
  </script>
</body>
</html>
HTMLEOF

  sed -i '' "s|FLUTTER_URL_PLACEHOLDER|$flutter_url|g" "$TEMP_PARENT_HTML"
  echo -e "${GREEN}✓ Parent page created${NC}"
}

# Start parent server
start_parent_server() {
  echo -e "${BLUE}Starting parent page server on port $PARENT_PORT...${NC}"

  cd /tmp
  python3 -m http.server $PARENT_PORT --bind 0.0.0.0 > /tmp/parent_server.log 2>&1 &
  PARENT_PID=$!
  echo $PARENT_PID > "$PARENT_PID_FILE"

  sleep 2
  echo -e "${GREEN}✓ Parent server started (PID: $PARENT_PID)${NC}"
}

# Display instructions
display_instructions() {
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║            🎉 Setup Complete!                  ║${NC}"
  echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
  echo ""
  echo -e "${BLUE}📱 Mobile URL (same WiFi):${NC}"
  echo -e "${GREEN}http://$LOCAL_IP:$PARENT_PORT/twake_iframe_parent.html${NC}"
  echo ""
  echo -e "${BLUE}🖥️  Desktop URL:${NC}"
  echo -e "http://localhost:$PARENT_PORT/twake_iframe_parent.html"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Testing Instructions:${NC}"
  echo "1. Connect phone to SAME WiFi as this computer"
  echo "2. Open the mobile URL above"
  echo "3. Click the smart banner's 'Open' button"
  echo "4. Try different sandbox policies from the dropdown"
  echo ""
  echo -e "${BLUE}Console Logs:${NC}"
  echo "  iOS: Safari → Develop → [Your iPhone] → [Page]"
  echo "  Android: chrome://inspect on desktop Chrome"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${RED}Press Ctrl+C to stop${NC}"
  echo ""
}

# Main execution
main() {
  echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║   Twake Chat - Mobile Iframe Testing          ║${NC}"
  echo -e "${BLUE}║        (Local Network - No ngrok)              ║${NC}"
  echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
  echo ""

  trap cleanup EXIT INT TERM

  check_dependencies
  check_ports
  start_flutter_server
  create_parent_page
  start_parent_server
  display_instructions

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Flutter Web Server Logs (live):${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  tail -f /tmp/flutter_web.log
}

main
