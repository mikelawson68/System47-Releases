# System 47 2.5.02 — Free macOS 27 Background App

This release adapts meWho’s System 47 Viewer 2.5.01 into a lightweight,
screen-saver-style background app for current macOS.

![System 47 LCARS interface preview — original artwork and animation by meWho](https://raw.githubusercontent.com/mikelawson68/System47-Releases/v2.5.02-macos27/images/system47_preview.png)

*Original System 47 LCARS artwork and animation by meWho.*

## Why it is an app instead of a `.saver`

Apple’s legacy third-party screen-saver host does not reliably support System
47’s Web/Ruffle renderer on current macOS. Testing reproduced black screens,
static fallback images, and unwanted login transitions. Version 2.5.02 runs as
a small background app instead, without using ScreenSaverEngine.

## Installation

1. Download `System47-2.5.02-FINAL-macOS27-universal.zip` below.
2. Unzip it and double-click `Install System 47.command`.
3. If blocked, Control-click the installer and choose **Open**, or use **System
   Settings → Privacy & Security → Open Anyway**.
4. Choose a standard **Start after** interval, sound, and starting program for
   each display. Click **Save**.
5. For conflict-free use, set Apple’s separate screen saver to **Never**. The
   installer does not change that setting automatically.

## Operation

- Starts automatically after System 47’s saved idle interval.
- Defaults to **20 minutes**; **Never** disables automatic starting.
- Starts manually after a three-second pointer hold at the **top center**.
- Provides a Dock-free **47** menu-bar icon for Settings, Start Now, and Quit.
- Stops on pointer movement, click, scroll, or key press.
- Can optionally go to the macOS login screen after closing; off by default.
- Starts its lightweight background process automatically at user login.
- Does not change Apple’s timer, Hot Corners, display sleep, or security.

## Compatibility and security

- macOS 15 or later
- Apple Silicon and Intel universal binaries
- Multiple displays
- Developer ID signed, hardened, notarized, and stapled by Apple
- No Adobe Flash requirement; original SWF content runs through Ruffle

## Troubleshooting

- **Both System 47 and Apple’s saver start:** set Apple’s saver to Never.
- **Top-center hold does nothing:** hold at the top edge, centered, for three
  full seconds; rerun the installer if necessary.
- **Automatic start does nothing:** select a non-Never interval and click Save.
- **It will not close:** move the pointer distinctly, click, scroll, or press a
  key.
- **Unwanted sound:** clear the sound checkbox and click Save.
- **More help:** open an issue with Mac model, macOS version, expected and
  actual behavior, and `~/Library/Logs/System47Launcher.log`.

## Original work and attribution

**System 47 is the original creative work of meWho.** meWho created the
original program, LCARS artwork and interface, animations, sounds, and SWF
content. Space images are courtesy NASA/JPL-Caltech. We did not create or claim
authorship of that art, animation, audio, or original program content.

artistpro, LLC and Mike Lawson adapted meWho’s existing free work for current
macOS by replacing the obsolete projector runtime and adding universal macOS
rendering, multi-monitor settings, idle monitoring, and manual launch. This
adaptation is free of charge and provided as is, without warranty.

Visit [mewho.com/system47](https://www.mewho.com/system47/) for the original
releases and to support future System 47 development.

## Checksum

SHA-256: `9bcc11f307232a2b383b127e1b7f08e4af6c0e91e6c3c4c08c4fc1932e4cdfb4`
