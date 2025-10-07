#!/usr/bin/env bash

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

# Optional step - it takes couple of seconds (or longer) to establish a WiFi connection
# sometimes. In this case, following checks will fail and wifi-connect
# will be launched even if the device will be able to connect to a WiFi network.
# If this is your case, you can wait for a while and then check for the connection.
# sleep 15

# Choose a condition for running WiFi Connect according to your use case:

# 1. Is there a default gateway?
# ip route | grep default

# 2. Is there Internet connectivity?
# nmcli -t g | grep full

# 3. Is there Internet connectivity via a google ping?
# wget --spider http://google.com 2>&1

# 4. Is there an active WiFi connection?
iwgetid -r

if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'

    # Start wifi-connect and capture its output
    sudo wifi-connect 2>&1 | while IFS= read -r line; do
        echo "$line"

        # Parse the "Starting HTTP server on" line to extract gateway and port
        if echo "$line" | grep -q "Starting HTTP server on"; then
            ADDRESS=$(echo "$line" | sed -n 's/.*Starting HTTP server on \([0-9.:]*\).*/\1/p')
            GATEWAY=$(echo "$ADDRESS" | cut -d':' -f1)
            LISTENING_PORT=$(echo "$ADDRESS" | cut -d':' -f2)

            # Build the UI URL
            if [ "$LISTENING_PORT" = "80" ]; then
                UI_URL="http://${GATEWAY}"
            else
                UI_URL="http://${GATEWAY}:${LISTENING_PORT}"
            fi

            # Get SSID and passphrase from environment or use defaults
            SSID="${PORTAL_SSID:-WiFi Connect}"
            PASSPHRASE="${PORTAL_PASSPHRASE:-}"

            # Display connection information
            echo ""
            echo "=========================================="
            echo "WiFi Connect Portal Active"
            echo "=========================================="
            echo "SSID: ${SSID}"
            if [ -n "$PASSPHRASE" ]; then
                echo "Password: ${PASSPHRASE}"
            else
                echo "Password: (none - open network)"
            fi
            echo ""
            echo "Connect to the WiFi network above, then"
            echo "visit: ${UI_URL}"
            echo "=========================================="

            # Generate and display WiFi QR code if qrencode is available
            if command -v qrencode &> /dev/null; then
                echo ""
                echo "Scan QR code to connect to WiFi:"

                # Build WiFi QR code string
                # Format: WIFI:T:<encryption>;S:<SSID>;P:<password>;H:<hidden>;;
                if [ -n "$PASSPHRASE" ]; then
                    WIFI_QR="WIFI:T:WPA;S:${SSID};P:${PASSPHRASE};;"
                else
                    WIFI_QR="WIFI:T:nopass;S:${SSID};;"
                fi

                qrencode -t ANSIUTF8 "${WIFI_QR}"
                echo ""
                echo "After connecting, open: ${UI_URL}"
                echo ""
            else
                echo ""
                echo "Install 'qrencode' to display a WiFi QR code"
                echo "sudo apt-get update && sudo apt-get install -y qrencode"
                echo ""
            fi
        fi
    done
fi

# Start your application here.
sleep infinity
