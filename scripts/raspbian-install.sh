install_wfc() {
    local _arch
    local _binary_url
    local _ui_url
    local _wfc_version
    local _download_dir

    _arch=$(detect_architecture)

    say "Detected architecture: $_arch"
    say "Retrieving latest release from $RELEASE_URL..."

    # Get the binary URL for the detected architecture
    _binary_url=$(ensure curl -s "$RELEASE_URL" | grep -oP "browser_download_url\": \"\\K[^\"]*wifi-connect-$_arch\.tar\.gz")
    
    if [ -z "$_binary_url" ]; then
        err "Could not find wifi-connect binary for architecture: $_arch"
    fi

    # Get the UI URL
    _ui_url=$(ensure curl -s "$RELEASE_URL" | grep -oP 'browser_download_url": "\K[^"]*wifi-connect-ui\.tar\.gz')
    
    if [ -z "$_ui_url" ]; then
        err "Could not find wifi-connect UI package"
    fi

    say "Downloading and extracting $_binary_url..."

    _download_dir=$(ensure mktemp -d)

    # Download and extract the binary
    ensure curl -Ls "$_binary_url" | tar -xz -C "$_download_dir"

    ensure sudo mkdir -p "$INSTALL_BIN_DIR"
    ensure sudo mv "$_download_dir/wifi-connect" "$INSTALL_BIN_DIR"

    # Download and extract the UI
    say "Downloading and extracting UI..."
    ensure curl -Ls "$_ui_url" | tar -xz -C "$_download_dir"

    ensure sudo mkdir -p "$INSTALL_UI_DIR"
    ensure sudo rm -rdf "$INSTALL_UI_DIR"
    ensure sudo mv "$_download_dir/ui" "$INSTALL_UI_DIR"

    ensure rm -rdf "$_download_dir"

    _wfc_version=$(ensure wifi-connect --version)

    say "Successfully installed $_wfc_version"
}
