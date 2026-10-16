# CatalogGuard 项目申报书

## 基本信息

- 项目名称：CatalogGuard：MoonBit PO/POT 翻译目录检查工具
- 参赛者：石子硕（GitHub ID：2111950632）
- 联系方式：2111950632@qq.com
- GitHub 仓库：https://github.com/2111950632/CatalogGuard
- 项目方向：MoonBit 开发者工具 / 翻译格式参数合同检查
- 是否为移植项目：否，原创 MoonBit 实现，参考公开规范及可观察行为。

## 项目简介

CatalogGuard 在译文合入前检查格式参数合同。本次相对 moongettext 的净增范围是 C printf、Python str 百分号格式和 str.format 三类检查器，识别参数缺失、多余、用途变化及非法语法，允许保持身份和用途的合法重排。PO/POT、目录校验、复数、统计和模板处理是共性能力，不申报为独有创新。

检查核心由 MoonBit 实现，Node.js 负责文件与命令行输入输出。本次源码版本为 0.1.2，发布和线上状态另附验收记录。

## 核心功能范围

- C 目标为 C11 N1570 7.21.6.1 的 printf 静态合同，加 POSIX 编号参数；检查顺序/显式身份、length、转换族、动态宽度精度及已知未定义组合。
- Python 目标为 3.12 的 str 百分号和 str.format 内建语法；检查字典/顺序实参、重复用途、自动路径、Unicode 身份及一层嵌套依赖，拒绝已知非法选项。
- 按“身份到用途集合”比较，输出公开 API、源码位置、JSON 和失败退出码。完整兼容终点为 CGFC-1 所列语法产式、类型组合与边界的实现及分支验收，并在两后端和发布消费项目中复验；目前不宣称全规范兼容已完成。
- 新增 96 个案例，连同原有用例共 133 项，在 JS/Wasm GC 各通过；19 项 CLI、独立打包 consumer、55 项 CPython 3.12.14 探针通过。GNU 1.0 的 73 项固定预期通过，另外 23 项仅观察，规范差异明确列出。
- 原样 moongettext 固定提交四探针通过：三类格式错配在其校验范围之外，本项目报告 F005，重复键控制确认校验有效。提供 10 个直接运行的 PO 示例。完整标准、净增对照、合法重排和边界案例见 docs/FORMAT_CONTRACTS.md 与 docs/REVIEW_RESPONSE.md。

## 移植或参考说明

参考 C11/POSIX、Python 3.12 及 gettext 概念，未复制 GNU gettext、polib、moongettext 或 Translate Toolkit 实现。项目采用 Apache-2.0，第三方工具和语料仅作独立对照。

使用 AI 辅助设计、实现、测试和文档，提交者对成果及维护负责。材料区分已实现能力与后续目标，有限案例通过不代表全语言兼容。
