# AICP Shell
[中文](README_CN.md) | [English](README.md) 

## Make HTML a Cross-Platform Operating System Container
> **Make HTML Your Operating System** — A cross-platform runtime container that equips plain HTML/JS with full native hardware control. It covers 7 platforms, exposes 30+ hardware APIs, and features an AI-first architecture.

---
## Built-in HTML Demos

### HTML-Finder
Browse local files just like macOS Finder inside AICP Shell. Supports creating, editing, deleting and executing local files.
![Finder File Manager](docs/finder.png)

### Hardware Test Panel
Invoke all platform hardware APIs purely with HTML + JS, embeddable anywhere in your web pages.
![Function Test Panel](docs/func_demo.png)

## Core Project Vision
Break the boundary between web pages and native operating systems. HTML is no longer limited to rendering static content inside browsers — it gains full low-level device control capability.

| Scenario | Traditional Solution | AICP Shell |
|---------|---------------------|-----------|
| Hardware access | Separate native SDKs, platform-specific source code, repetitive multi-platform compilation | One-line JS call: `window.mobile.camera.take()` |
| AI backend integration | Standalone Python environment, complex dependency configuration, cross-process communication handling | Direct standard `fetch()` network requests with zero extra setup |
| Multi-terminal development | Independent projects for Android/iOS/Windows/Linux/HarmonyOS, maintained by multiple teams | Single set of HTML source code, auto-adapts all 7 platforms at once |
| Deep local system control | WSL/Docker deployment, massive operation & maintenance scripts | Minimal JS system process APIs to complete all operations |

Only HTML/JS required, no extra compilation frameworks — full access to all device low-level capabilities.

---
## Horizontal Comparison of Mainstream Development Solutions

| Comparison Item | Native Dev (Kotlin/Swift/C#) | Regular Web Page | Python/CLI Tool | Electron | AICP Shell |
|---------|---------------------------|--------------|----------------|----------|------------|
| Development Language | Separate languages per platform | HTML/CSS/JS | Python/Node.js | HTML/CSS/JS | Unified HTML/JS |
| Cross-platform Coverage | Full rewrite for every OS | Browser-only | Limited to desktop | Desktop-only | Full support for all 7 platforms |
| Native Hardware Access | Full support | Strict browser permission restrictions | No mobile hardware support | Limited desktop peripherals | 30+ cross-platform hardware APIs |
| System Command / Process Control | Supported | Completely blocked | Desktop-only support | Limited functionality | Fully open access across all platforms |
| Remote Dynamic Page Loading | Unsupported | Native feature | Unsupported | Supported | Native built-in support |
| Online Hot Update | Long release cycles with app store review | Instant refresh via page reload | Impossible | Full package replacement | Instant page hot update, no audit required |
| AI Code Generation Compatibility | Complex native logic hard for AI to generate | Perfect match for AI frontend generation | Backend logic only | Pages generatable by AI | Natively compatible with end-to-end AI generation |

**AICP Shell = Full native hardware permissions + Lightweight web fast iteration + Native AI compatibility**, all-in-one runtime solution.

---
## Underlying Architecture
This project is entirely built on our self-developed [AICP Protocol](https://github.com/woozheng/aicp). The full architecture design, plugin modules and Web communication bridge are all assisted by AI.

Single Flutter project, one unified codebase compiles and runs on all supported platforms.

## Fully Supported Platforms (All CI Builds Passed)

> Automatic packaging triggered on every push to `main` branch. Build artifacts are stored for 90 days. Links below point to the latest successful build, no GitHub login required for direct download.

| Platform | Status | Details | Direct Download |
|-----|---------|---------|------|
| Android | ✅ Build Passed | Full plugin support for Bluetooth, audio, QR scan, location & local notifications | [⬇️ Android APK](https://nightly.link/woozheng/aicp_shell/workflows/build-all.yml/main/Android-Release-APK.zip) |
| Windows | ✅ Build Passed | Complete file system, process command & window management | [⬇️ Windows Bundle](https://nightly.link/woozheng/aicp_shell/workflows/build-all.yml/main/Windows-x64-Bundle.zip) |
| Linux x64 | ✅ Build Passed | Fully functional desktop file manager & WebView runtime | [⬇️ Linux Archive](https://nightly.link/woozheng/aicp_shell/workflows/build-all.yml/main/Linux-x64-Bundle.zip) |
| macOS | ✅ Build Passed | Complete Mac desktop runtime & WebView underlying adaptation | [⬇️ macOS App Package](https://nightly.link/woozheng/aicp_shell/workflows/build-all.yml/main/macOS-App.zip) |
| HarmonyOS | ⏳ Local Manual Build | Permission layer adapted, fully compatible with all hardware APIs | [📖 Build Guide](./docs/ohos_config.md) |
| iOS | ⏳ Local Manual Build | All underlying communication protocols fully adapted | Build on demand |
| Web | ⏳ Local Manual Build | AICP communication bridge logic completed | Build on demand |

---
## 🚀 What can you build with HTML on AICP Shell?
- 🤖 Local AI desktop assistant — AI generates JS scripts and executes them with one click to fully control mobile & PC hardware
- 🧠 Super AI terminal integrated with Claude Code / Codex / Hermes — Cross-device full control over local resources and system processes
- 🖥️ Lightweight cross-platform cloud desktop system — ChromeOS-like experience with deep local file read/write integration
- 🏢 Enterprise instant-update client without audit — Local data storage, single page deployed across all platforms, no store review for updates
- ☁️ Unified AI application bridging local & cloud — Eliminates frontend-backend and local-cloud barriers, complete business logic implemented purely with HTML
- 🧩 All-in-one AI tool desktop — No local file upload required, instant hot updates, instant access to all AI capabilities

Unleash your imagination.

## Quick Start
```bash
# Clone the AICP Shell repository
git clone https://github.com/woozheng/aicp_shell.git
cd aicp_shell

# Install dependencies
flutter pub get

# Run directly on your current operating system
flutter run
```
## AICP Shell SDK
### AI-Friendly Hardware Calling SDK
Refer to the built-in demo file [god_mode.html](./assets/god_mode.html). Any AI can master all hardware calling standards after reading it.

### Extend Native Underlying Features of AICP Shell
1. Create new hardware plugins and put them in the `lib/plugins/` directory
2. Complete plugin import, registration and permission declaration in `lib/core/register.dart`. You can refer to existing plugin templates, and AI can generate complete code with one click.
3. Check `god_mode.html` for JS calling examples, AI can automatically generate front-end interaction logic.

## License
MIT — Free to use, modify and rewrite freely. 🚀

Check the full license text at [LICENSE](LICENSE)