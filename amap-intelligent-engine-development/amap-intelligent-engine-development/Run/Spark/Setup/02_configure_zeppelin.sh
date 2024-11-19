#!/bin/bash
set -ex

setup_zeppelin_python3() {
    echo "[INFO] Starting python3 setting for zeppelin python interpreter..."
    ls -la /etc/zeppelin
    ls -la /etc/zeppelin/conf
    ls -la /etc/zeppelin/conf.dist
    sudo cp /etc/zeppelin/conf.dist/interpreter.json /etc/zeppelin/conf.dist/interpreter.json.backup
    sudo jq '.interpreterSettings.python.properties."zeppelin.python".value = "python3"' /etc/zeppelin/conf.dist/interpreter.json | sudo tee /etc/zeppelin/conf.dist/interpreter.json.tmp
    sudo mv /etc/zeppelin/conf.dist/interpreter.json.tmp /etc/zeppelin/conf.dist/interpreter.json

    sudo systemctl restart zeppelin

    echo "[INFO] Zeppelin python interpreter configuration completed..."
}

# ======== MAIN ========

# Execute Functions
echo "[INFO] Starting script..."

setup_zeppelin_python3

echo "[SUCCESS] Script completed"

# EOF