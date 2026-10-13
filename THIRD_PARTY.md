# 来源与许可证

本项目 MoonBit 实现为新编写的代码，未复制下列同类工具实现。使用 AI 协助设计与开发；提交者负责验证及维护。

| 来源 | 使用方式 |
|---|---|
| [MoonBit core](https://github.com/moonbitlang/core) | 官方标准库 JSON、UTF-8、Debug trait；Apache-2.0 |
| [GNU gettext 手册](https://www.gnu.org/software/gettext/manual/gettext.html) | PO/POT、格式 flags、plural 概念与行为参考；不包含其源码 |
| [polib](https://polib.readthedocs.io/) | 独立测试工具，固定版本 1.2.0；不作为运行时依赖，不打包其实现 |
| [Translate Toolkit 检查项](https://docs.translatehouse.org/projects/translate-toolkit/en/latest/commands/pofilter_tests.html) | 同类功能研究与项目定位参考；不复制实现 |
| [MoonBit 官方文档测试语料](https://github.com/moonbitlang/moonbit-docs/tree/8d9f3ba206eb17f80ee1836e4c1139068d1351b5/next/locales) | 固定提交的中日文 PO，测试脚本下载并核验 SHA-256，忽略目录中临时保存；不分发、不计入本项目代码 |

官方文档的 [许可证](https://github.com/moonbitlang/moonbit-docs/blob/8d9f3ba206eb17f80ee1836e4c1139068d1351b5/LICENSE.md) 区分文本与示例：2024-07-04 起新增文本为 CC BY-SA 4.0，更早文本保留版权；代码示例为 Apache-2.0。不能把整份历史文档概括为统一 Apache 许可证，因此项目不将外部 PO 打包或重新许可。测试清单仅记录公开 URL 与摘要。

`examples/` 的 PO/POT 均为本项目编写。仓库 LICENSE 适用于本项目代码，不改变外部工具、语料或标准库的许可证。运行包中的编译 JS 包含标准库代码，按 Apache-2.0 保留其归属；标准库版权主体为 International Digital Economy Academy。
