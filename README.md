<p align="center">
  <img src="images/system47_logo.png" width="240" alt="System 47 Logo">
</p>

# System 47
Welcome to the official release repository for **System 47** on GitHub. 

This repository is used to host downloads, track bugs, and distribute test builds for the System 47 Screensaver and companion Viewer programs.

### Available Programs:
* **System 47 Screensaver** (Windows)
* **System 47 Viewer** (Windows)
* **System 47 Viewer** (Mac)
* **System 47 Screen Saver — modern macOS adaptation** (macOS 27, Apple Silicon and Intel)

## Downloads
* **Static-image hot-corner repair:** if the corner shows a still image while
  the app's Preview works, use the [direct launcher repair](src/launcher/README.md).
  It adds a bottom-left hot corner and three-hour timer to an existing native
  installation. The published release ZIP is unchanged.
* Versions previously released in 2021-2022, visit this **[Release](../../releases/tag/v2.5.1)** page.
* Latest **Test Version** ⚠️ (July 8, 2026), please visit this **[Test Release](../../releases/tag/v2.5.2-test3)** page.
* **macOS 27 Screen Saver:** download the notarized universal package from the **[macOS 27 Release](../../releases/tag/v2.5.01-macos27)** page.
* *If you encounter any issues (such as the black screen bug), please don't hesitate to report it.*

## Modern Screen Saver for macOS 27

**New August 2026 macOS adaptation:** this is no longer an Adobe Flash Player
or Flash Projector application and does not require Adobe Flash. The obsolete
2022 projector runtime has been replaced by the actively maintained Ruffle
runtime plus new native macOS components.

For accuracy, meWho’s original System 47 Viewer 2.5.01 SWF remains the preserved
program-content format; Ruffle executes that content without Adobe Flash. This
edition installs an actual macOS Screen Saver component and adds native
multi-monitor configuration, current Apple Silicon support, Developer ID
signing, hardened runtime and Apple notarization.

### Compatibility

* macOS 26/27 or later Untested with earlier but likely works)
* Apple Silicon: M1, M2, M3, M4, M5 and later families
* Intel Macs capable of running macOS 26/27
* Universal `arm64` and `x86_64` native binaries
* Multiple displays with an independently assigned starting LCARS program

### Installation

1. Download `System47-2.5.01-FINAL-macOS27-universal.zip` from the
   **[macOS release page](../../releases/tag/v2.5.01-macos27)**.
2. Unzip it before running the installer.
3. Double-click `Install System 47.command`.
4. If macOS blocks the installer script, Control-click it, select **Open**, and
   click **Open** once. The application and Screen Saver components themselves
   are Developer ID signed, hardened, notarized and stapled by Apple.
5. If it is still blocked, open **System Settings → Privacy & Security**, scroll
   to **Security**, click **Open Anyway** for `Install System 47.command`,
   authenticate when prompted, and confirm **Open**. Only approve the installer
   from this official System 47 download.
6. Choose sound, timing and the starting program for each display in the
   System 47 settings panel.
7. Open **System Settings → Wallpaper → Screen Saver** and select **System 47**
   under **Other**.

The current package includes an animated System Settings preview, a closable
Options sheet, direct native-saver launch of the full-screen companion, and a
per-user watcher for System 47's idle timer and bottom-right hot corner. During
installation, only a competing Apple “Start Screen Saver” assignment on that
corner is removed; all other hot-corner assignments are preserved.

SHA-256:
`17b7a59ef7c5641cb8d86ab87eff920530e75e4c4d41efe3adf4fd0957df72c4`

Original System 47 program and content by **meWho**. Space images courtesy
NASA/JPL-Caltech. System 47 is freeware, provided “as is,” without warranty of
any kind. Modern macOS adaptation and packaging freely contributed by
**artistpro, LLC — Mike Lawson**.

The August 2026 package uses Ruffle and newly written native macOS integration
rather than the original Shockpkg/Adobe Flash Projector. Visit
[mewho.com/system47](https://www.mewho.com/system47/) for the original releases
and to support future System 47 development.

<br>

---
🧡**Built with Love** [Support my projects on Patreon](https://patreon.com/mewho) • [Ko-Fi](https://ko-fi.com/system47) \
💬**Stay connected** [Bluesky](https://bsky.app/profile/mewho-rob.bsky.social) | [Facebook](https://www.facebook.com/mewhoRob/) | [Mastodon](https://mastodon.social/@mewho) | [Discord](https://discord.gg/SnRdmSmnjK)

Cheers🖖 ~ meWho•Rob
