#!/bin/zsh
set -euo pipefail

package_dir=${0:A:h}
app_source="$package_dir/System 47.app"
saver_source="$package_dir/System 47.saver"
agent_source="$package_dir/com.mewho.system47.fullscreen.plist"
launcher_source="$app_source/Contents/Helpers/System47Launcher"
app_destination="/Applications/System 47.app"
legacy_app_destination="$HOME/Applications/System 47.app"
saver_destination="$HOME/Library/Screen Savers/System 47.saver"
support_destination="$HOME/Library/Application Support/System47Launcher"
agent_destination="$HOME/Library/LaunchAgents/com.mikelawson.system47.launcher.plist"
old_agent_destination="$HOME/Library/LaunchAgents/com.mewho.system47.fullscreen.plist"
label="com.mikelawson.system47.launcher"
user_domain="gui/$UID"

[[ -d "$app_source" && -d "$saver_source" && -f "$agent_source" && -x "$launcher_source" ]] || {
    echo "The System 47 package is incomplete. Re-download and unzip it before installing."
    exit 1
}

mkdir -p "$HOME/Library/Screen Savers" "$HOME/Library/LaunchAgents" "$support_destination" "$HOME/Library/Logs"
/bin/rm -rf "$app_destination" "$legacy_app_destination" "$saver_destination"
ditto "$app_source" "$app_destination"
ditto "$saver_source" "$saver_destination"
cp "$launcher_source" "$support_destination/System47Launcher"
chmod 755 "$support_destination/System47Launcher"

build_dir=$(mktemp -d "${TMPDIR:-/tmp/}system47-agent.XXXXXX")
trap '/bin/rm -rf "$build_dir"' EXIT
cat > "$build_dir/agent.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.mikelawson.system47.launcher</string>
<key>ProgramArguments</key><array/>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
<key>ProcessType</key><string>Interactive</string>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $support_destination/System47Launcher" "$build_dir/agent.plist"
/usr/libexec/PlistBuddy -c "Add :StandardOutPath string $HOME/Library/Logs/System47Launcher.log" "$build_dir/agent.plist"
/usr/libexec/PlistBuddy -c "Add :StandardErrorPath string $HOME/Library/Logs/System47Launcher.log" "$build_dir/agent.plist"
plutil -lint "$build_dir/agent.plist"
cp "$build_dir/agent.plist" "$agent_destination"

# The native helper owns System 47's top-right corner and idle timer. Disable
# Apple's overlapping screen-saver triggers so it cannot cover System 47 with
# a still preview. Display sleep and screen-lock requirements are unchanged.
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 0
if ! defaults read com.mewho.system47.fullscreen idleSeconds >/dev/null 2>&1; then
    defaults write com.mewho.system47.fullscreen idleSeconds -float 10800
fi
killall Dock >/dev/null 2>&1 || true

launchctl bootout "$user_domain/com.mewho.system47.fullscreen" >/dev/null 2>&1 || true
launchctl bootout "$user_domain/$label" >/dev/null 2>&1 || true
[[ ! -f "$old_agent_destination" ]] || mv "$old_agent_destination" "$support_destination/disabled-original-agent.plist"
launchctl bootstrap "$user_domain" "$agent_destination"
launchctl kickstart -k "$user_domain/$label"

open "$app_destination"
echo "System 47 is installed. Its settings panel is now open."
