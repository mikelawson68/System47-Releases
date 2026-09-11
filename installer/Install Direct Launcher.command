#!/bin/zsh
set -euo pipefail

# Repair an existing native System 47 installation without modifying its signature.
repo_dir=${0:A:h:h}
source_file="$repo_dir/src/launcher/System47Launcher.m"
renderer='/Applications/System 47.app/Contents/MacOS/System47FullScreen'
support="$HOME/Library/Application Support/System47Launcher"
agent_dir="$HOME/Library/LaunchAgents"
agent="$agent_dir/com.mikelawson.system47.launcher.plist"
old_agent="$agent_dir/com.mewho.system47.fullscreen.plist"
label='com.mikelawson.system47.launcher'
user_domain="gui/$(id -u)"

[[ -x "$renderer" && -f "$source_file" ]] || {
    print -u2 'Install the native System 47 app in /Applications first, then run this script from a complete repository checkout.'
    exit 1
}
xcrun --find clang >/dev/null || {
    print -u2 'Install Apple Command Line Tools (xcode-select --install), then try again.'
    exit 1
}

# Compile before changing the existing installation. The temporary binary is
# private to this user; no downloaded installer code or administrator rights.
build_dir=$(mktemp -d "${TMPDIR:-/tmp/}system47-launcher.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
xcrun clang -fobjc-arc -framework AppKit -framework CoreGraphics \
    "$source_file" -o "$build_dir/System47Launcher"
"$build_dir/System47Launcher" --check

mkdir -p "$support" "$agent_dir" "$HOME/Library/Logs"
backup="$support/backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup"
for key in wvous-bl-corner wvous-bl-modifier; do
    defaults read com.apple.dock "$key" > "$backup/$key.txt" 2>/dev/null || print 0 > "$backup/$key.txt"
done
defaults -currentHost read com.apple.screensaver idleTime > "$backup/apple-idleTime.txt" 2>/dev/null || print 0 > "$backup/apple-idleTime.txt"
[[ ! -f "$agent" ]] || cp "$agent" "$backup/"
[[ ! -f "$old_agent" ]] || cp "$old_agent" "$backup/"

launchctl bootout "$user_domain/com.mewho.system47.fullscreen" >/dev/null 2>&1 || true
launchctl bootout "$user_domain/$label" >/dev/null 2>&1 || true
[[ ! -f "$old_agent" ]] || mv "$old_agent" "$backup/disabled-original-agent.plist"
cp "$build_dir/System47Launcher" "$support/System47Launcher"
cp "$source_file" "$support/System47Launcher.m"

# PlistBuddy writes user paths as strings, including names containing spaces or &.
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
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $support/System47Launcher" "$build_dir/agent.plist"
/usr/libexec/PlistBuddy -c "Add :StandardOutPath string $HOME/Library/Logs/System47Launcher.log" "$build_dir/agent.plist"
/usr/libexec/PlistBuddy -c "Add :StandardErrorPath string $HOME/Library/Logs/System47Launcher.log" "$build_dir/agent.plist"
plutil -lint "$build_dir/agent.plist"
cp "$build_dir/agent.plist" "$agent"

# The helper owns the corner and timer. Apple must not cover the renderer with
# its legacy host. This does not alter screen-lock or display-sleep settings.
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 0
defaults write com.mewho.system47.fullscreen idleSeconds -float 10800
killall Dock >/dev/null 2>&1 || true
launchctl bootstrap "$user_domain" "$agent"
print 'Installed: bottom-left hot corner, three idle hours, automatic start at login.'
print 'The signed System 47 app and macOS password requirements were not changed.'
print "Previous settings and launch agents: $backup"
