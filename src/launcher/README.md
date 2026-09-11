# Direct launcher repair

The published macOS package can show the bridge's static preview when Apple's
**Start Screen Saver** hot corner is used, even though **Preview** inside the
System 47 app animates correctly. This helper uses that working renderer path:
`System47FullScreen --show`.

## Install on an existing native System 47 installation

1. Install the native System 47 app in `/Applications`.
2. Download or clone this entire repository. Keep `installer` and `src` together.
3. Install Apple's Command Line Tools if necessary: `xcode-select --install`.
4. Run `installer/Install Direct Launcher.command`.

The repair compiles the helper locally and installs a per-user LaunchAgent. It
replaces the package's background watcher, takes over the bottom-left corner,
and sets the idle interval to three hours. Apple’s competing corner assignment
and screensaver timer are disabled; the helper provides both triggers instead.
Consequently, Apple's Hot Corners panel shows no assignment for that corner,
and its screen-saver timer shows Never. This is expected.

Move the pointer into the bottom-left corner of any connected display to start
the animation on all displays. Leave the corner before triggering it again.
The helper prevents duplicate launches while its renderer is running and waits
briefly after dismissal before accepting another trigger. Display coordinates
are refreshed each poll, including displays positioned left of or below the
main screen. No keyboard content is read or recorded.

The native app retains its sound and per-display program settings. To change
the three-hour interval later, choose a new interval in System 47 Settings and
click Save. The helper reads `com.mewho.system47.fullscreen` → `idleSeconds`.
It runs at login after a reboot and is restarted by launchd if it exits.

## Passwords and sleep

The renderer is a full-screen application, not a lock screen. Dismissing this
animation does not itself require a password. The repair **does not disable
macOS authentication**, unlock an already locked session, or change display
sleep settings. A lock or display sleep can still require authentication, and
display sleep may occur before the three-hour timer.

## Verification and maintenance

The installed helper and source are in
`~/Library/Application Support/System47Launcher`. Logs are written to
`~/Library/Logs/System47Launcher.log`. Run the helper with `--check` for a
read-only display/corner check, or `--trigger` to request a playback test from
the running helper. A successful load reports `SYSTEM47_FULLSCREEN_READY`
with the display count and `SYSTEM47_WEB_READY` for each display.

The repair was tested on macOS 26.5.2 with Apple Silicon and five displays,
using the v2.5.01-macos27 app. The helper has not been reboot-tested or tested on
Intel. The installer requires Apple Command Line Tools; the signed and
notarized System 47 app is not changed or re-signed.

The installer saves prior corner settings, Apple's idle interval, and existing
launch-agent files under `~/Library/Application Support/System47Launcher/backups`.
To stop the helper, run:

```sh
launchctl bootout "gui/$(id -u)/com.mikelawson.system47.launcher"
```

Move `~/Library/LaunchAgents/com.mikelawson.system47.launcher.plist` out of that
folder to prevent restart at next login. Restore the saved corner and idle
values in System Settings if reverting to Apple's host. Restore and bootstrap
the original agent only if returning to the original package watcher; do not
run both watchers at once.

This source repair does not replace the existing signed release ZIP or change
its checksum. Re-running the original package installer re-enables its watcher;
run this repair again afterward if retaining direct-launch behavior.
