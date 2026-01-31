#!/bin/bash

# ---- SCRIPT PATH ---
SCRIPT_PATH="$(pwd)/EzWoL.sh"

chmod +x "$SCRIPT_PATH"

# ---- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---- INSTALLATION ---
if ! grep -q "alias ezwol=" ~/.bashrc; then
    echo "alias ezwol='$SCRIPT_PATH'" >> ~/.bashrc
    echo -e "${GREEN}[+] Alias 'ewol' added to ~/.bashrc ${NC}"
else 
    echo -e "${RED}[!] Alias 'ezwol' already exist ${NC}"
fi

echo -e "${YELLOW} Please run : source ~/.bashrc to use 'ezwol' immediately.${NC}"