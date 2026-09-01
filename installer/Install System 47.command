#!/bin/zsh
set -euo pipefail

package_dir=${0:A:h}
app_source="$package_dir/System 47.app"
saver_source="$package_dir/System 47.saver"
agent_source="$package_dir/com.mewho.system47.fullscreen.plist"
app_destination="/Applications/System 47.app"
legacy_app_destination="$HOME/Applications/System 47.app"
saver_destination="$HOME/Library/Screen Savers/System 47.saver"
agent_destination="$HOME/Library/LaunchAgents/com.mewho.system47.fullscreen.plist"

[[ -d "$app_source" && -d "$saver_source" && -f "$agent_source" ]] || {
    echo "The System 47 package is incomplete. Re-download and unzip it before installing."
    exit 1
}

mkdir -p "$HOME/Library/Screen Savers" "$HOME/Library/LaunchAgents"
/bin/rm -rf "$app_destination" "$legacy_app_destination" "$saver_destination"
ditto "$app_source" "$app_destination"
ditto "$saver_source" "$saver_destination"
cp "$agent_source" "$agent_destination"

# System 47's full-screen watcher owns the bottom-right hot corner. If macOS is
# also configured to start its legacy Screen Saver host there, that host can
# cover System 47 with the bridge's static preview until the user dismisses it.
# Remove only that conflicting assignment and preserve every other hot corner.
bottom_right_action=$(defaults read com.apple.dock wvous-br-corner 2>/dev/null || echo 0)
if [[ "$bottom_right_action" == "5" ]]; then
    defaults write com.apple.dock wvous-br-corner -int 0
    defaults write com.apple.dock wvous-br-modifier -int 0
    killall Dock >/dev/null 2>&1 || true
    echo "Removed the conflicting macOS Screen Saver action from the System 47 hot corner."
fi

launchctl bootout "gui/$UID/com.mewho.system47.fullscreen" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID" "$agent_destination"
launchctl kickstart -k "gui/$UID/com.mewho.system47.fullscreen"

open "$app_destination"
echo "System 47 is installed. Its settings panel is now open."
