# AICP Shell

## 让 HTML 成为操作系统的跨平台容器。

> **Make HTML Your Operating System** — A cross-platform container that turns HTML into native OS, with 30+ hardware APIs, 7 platforms, and AI-ready architecture.

---
## 自带HTML DEMO

### *HTML-Finder — 在 AICP Shell 里像 macOS 一样浏览本地文件，新建、修改、删除、运行*
![Finder 文件管理器](docs/finder.png)

### *功能测试面板 — 只用 HTML + JS 调用所有平台硬件，挂载在任何地方*
![功能测试面板](docs/func_demo.png)



## 项目核心定位

打破网页与原生系统的壁垒，让 HTML 不再局限于浏览器展示页面，而是拥有完整操控设备底层的能力。

| 使用场景 | 传统方案 | AICP Shell |
|---------|---------|-----------|
| 调用设备硬件 | 单独开发原生 SDK、编写平台专属代码、多端重复编译 | `window.mobile.camera.take()` 一行 JS 调用 |
| 对接 AI 后端服务 | 独立部署 Python 环境、配置依赖、处理跨进程通信 | 标准 fetch 网络请求即可互通 |
| 多终端适配开发 | Android/iOS/Windows/Linux/鸿蒙五套独立工程，多团队维护 | 单套 HTML 代码，一次性适配 7 大平台 |
| 本地系统深度控制 | WSL/Docker 环境部署、编写大量运维脚本 | JS 调用系统进程 API，极简指令完成操作 |

仅使用 HTML/JS，无需额外编译框架，直接操控设备全部底层能力。

---

## 主流开发方案横向对比

| 对比维度 | 原生开发 (Kotlin/Swift/C#) | 普通 Web 网页 | Python/CLI 工具 | Electron | AICP Shell |
|---------|---------------------------|--------------|----------------|----------|------------|
| 开发语言 | 多语言分端开发 | HTML/CSS/JS | Python/NodeJS | HTML/CSS/JS | 统一 HTML/JS |
| 跨平台能力 | 各端完全重写 | 仅浏览器可用 | 桌面端受限 | 仅桌面端 | 7 大平台全覆盖 |
| 原生硬件调用 | 完整支持 | 浏览器严格权限限制 | 无法调用移动端硬件 | 仅少量桌面硬件 | 30+ 全平台硬件 API |
| 系统命令/进程控制 | 支持 | 完全禁止 | 支持桌面 | 有限支持 | 全平台开放调用 |
| 远程网页动态加载 | 不支持 | 原生能力 | 不支持 | 支持 | 原生支持远程页面 |
| 在线热更新 | 应用商店审核，周期长 | 页面刷新即更新 | 无法热更 | 整包更新 | 页面秒级无审核更新 |
| AI 自动生成适配 | 代码复杂 AI 适配差 | 完美适配 AI 生成前端 | 仅后端逻辑 | 可生成页面 | 天生适配 AI 全链路生成 |

**AICP Shell = 原生底层硬件权限 + Web 轻量化灵活迭代 + AI 全链路适配**，三位一体。

---

## 底层架构说明

本项目完全基于自研 [AICP 协议](https://github.com/woozheng/aicp)，由 AI 辅助完成整套架构设计、插件编写、Web 通信桥设计。



单一 Flutter 工程，一套代码编译运行全平台。

---

## 已完整支持平台

| 平台 | 适配状态 | 补充说明 | 下载 |
|-----|---------|---------|------|
| Android | ✅ 完整可用 | 蓝牙、音频、扫码、定位、通知全部插件适配 | [⬇️ APK](链接) |
| HarmonyOS 鸿蒙 | ⏳ 待编译打包 | 权限分层适配，全硬件 API 兼容 | [📖 编译说明](docs/ohos_config.md) |
| Windows | ✅ 完整可用 | 文件系统、进程命令、窗口管理 | [⬇️ EXE](链接) |
| iOS | ⏳ 待编译 | 底层协议已适配 | 待发布 |
| macOS | ⏳ 待编译 | 底层协议已适配 | 待发布 |
| Linux | ⏳ 待编译 | 底层协议已适配 | 待发布 |
| Web | ⏳ 待编译 | 底层协议已适配 | 待发布 |

---

## 🚀 准备好在 AICP Shell 里用 HTML 开发什么应用了么？

- 🤖 **直接操作你电脑的聊天 AI** — 吐出 JS 脚本并直接执行,操控你的任意设备
- 🧠 **集成 Claude Code / Codex / Hermes 的超级 AI 助手** — 直接操控电脑、手机、任何移动设备
- 🖥️ **一个可以跑在任何平台上的 ChromeOS** — 无缝和本地文件集成处理
- 🏢 **企业级秒更新的跨平台系统** — 所有平台全覆盖，数据在本地，AI 分析在任何地方
- ☁️ **通杀本地、云端的超级 AI 应用** 抹平本地、云端的，前后端的超级HTML
- 🧩 **超级桌面** — 云集各种 AI 工具，直接操作本地文件无需上传，秒更新，随时使用

---

**来吧，开发你的想象力。**

## 快速启动

```bash
# 拉取本Shell容器仓库
git clone https://github.com/your-name/aicp_shell.git
cd aicp_shell

# 拉取依赖
flutter pub get

# 直接运行当前平台
flutter run
```

---
## AICP_shell SDK

### AI学习调用硬件的的SDK ，仅仅一个[功能测试html](./assets/god_mode.html)文件，AI 看完秒懂。

### 扩展aicp_shell的底层功能

1、写一个硬件调用插件放到lib\plugins目录
2、在lib\core\register.dart 文件中 import, regist, 增加权限，不会？AI看一眼其他插件秒写
3、不知道如何调用，再让AI看一眼，功能测试HTML，AI秒会



---



## License

MIT — 随便用，随便改，随便炸。🚀

See [LICENSE](LICENSE) for the boring legal stuff.


