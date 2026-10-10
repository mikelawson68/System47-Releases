# System 47 Screen Saver — Modern macOS 27 Adaptation

This is the new August 2026 macOS adaptation of meWho’s System 47 Viewer 2.5.01.

It is no longer an Adobe Flash Player or Flash Projector application and does
not require Adobe Flash. The obsolete 2022 projector runtime has been replaced
by Ruffle and newly written native macOS Screen Saver, full-screen,
multi-monitor and settings components.

For accuracy, the original System 47 SWF remains the preserved program-content
format. Ruffle executes it without Adobe Flash.

## Compatibility

- macOS 27 or later
- Apple Silicon: M1, M2, M3, M4, M5 and later families
- Intel Macs capable of running macOS 27
- Universal `arm64` and `x86_64` native binaries
- Multiple displays with independent starting-program assignments

## Installation

1. Download `System47-2.5.01-FINAL-macOS27-universal.zip` below.
2. Unzip it.
3. Double-click `Install System 47.command`.
4. If macOS blocks the installer script, Control-click it, choose **Open**, and
   click **Open** once.
5. If it is still blocked, open **System Settings → Privacy & Security**, scroll
   to **Security**, click **Open Anyway** for `Install System 47.command`,
   authenticate when prompted, and confirm **Open**. Only approve the installer
   from this official System 47 download.
6. Configure each display in the System 47 settings panel.
7. Select **System 47** in **System Settings → Wallpaper → Screen Saver**.

## October 9 maintenance update

- The System Settings preview now renders the live System 47 animation instead
  of a static image.
- The Options sheet now closes normally with its Done button or window close
  control.
- The native screen saver launches the full-screen companion directly, while a
  signed per-user launcher provides System 47's idle timer and top-right hot
  corner without requiring Xcode or Apple Command Line Tools.
- Installation disables Apple's overlapping screen-saver corner and idle timer,
  preventing the static bridge preview from covering System 47. Display sleep
  and screen-lock requirements are unchanged.
- **Never** stores a true zero interval and no longer falls back to ten minutes.
  While Never is selected, the launcher also prevents Apple's separate idle
  screen from appearing behind the disabled System 47 timer.
- Screen Sharing pointer updates no longer dismiss the full-screen animation.
- The animation loader uses IPv6 loopback, fixing the permanent white screen
  seen on Macs where IPv4 loopback is unavailable or filtered.
- Existing installations replace and restart the System 47 watcher during
  upgrade.

The application and Screen Saver components are Developer ID signed by
artistpro, LLC, use hardened runtime, and are notarized and stapled by Apple.

## Credits

Original System 47 program and content by **meWho**. Space images courtesy
NASA/JPL-Caltech. System 47 is freeware, provided “as is,” without warranty of
any kind.

Modern macOS adaptation and packaging freely contributed by
**artistpro, LLC — Mike Lawson**.

Visit [mewho.com/system47](https://www.mewho.com/system47/) for the original
releases and to support future System 47 development.

## Checksum

SHA-256:
`e1ce3ff63abc0225037dbf6bd8ff87b9f92f217829d800084de5fd8535737859`
