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
5. Configure each display in the System 47 settings panel.
6. Select **System 47** in **System Settings → Wallpaper → Screen Saver**.

## August 30 maintenance update

- The System Settings preview now renders the live System 47 animation instead
  of a static image.
- The Options sheet now closes normally with its Done button or window close
  control.
- The native screen saver launches the full-screen companion directly, so it
  works without a background watcher or LaunchAgent.
- Existing installations remove the obsolete watcher during upgrade.

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
`804ee5b436e526837f7d876bc1a4109875ed100284a564b8b8b072b4cc799f23`
