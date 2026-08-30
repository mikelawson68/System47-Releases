#!/bin/zsh
set -euo pipefail

package_dir=${0:A:h}
app_source="$package_dir/System 47.app"
saver_source="$package_dir/System 47.saver"
app_destination="/Applications/System 47.app"
legacy_app_destination="$HOME/Applications/System 47.app"
saver_destination="$HOME/Library/Screen Savers/System 47.saver"
agent_destination="$HOME/Library/LaunchAgents/com.mewho.system47.fullscreen.plist"

[[ -d "$app_source" && -d "$saver_source" ]] || {
    echo "The System 47 package is incomplete. Re-download and unzip it before installing."
    exit 1
}

mkdir -p "$HOME/Library/Screen Savers"
launchctl bootout "gui/$UID/com.mewho.system47.fullscreen" >/dev/null 2>&1 || true
/bin/rm -rf "$app_destination" "$legacy_app_destination" "$saver_destination"
ditto "$app_source" "$app_destination"
ditto "$saver_source" "$saver_destination"
/bin/rm -f "$agent_destination"

open "$app_destination"
echo "System 47 is installed. Its settings panel is now open."
