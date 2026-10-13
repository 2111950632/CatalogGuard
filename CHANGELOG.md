# 更新记录

## 0.1.1 — 2026-10-13

- 修复 CLI 的旧 dist 覆盖本地新构建问题，按本地 release/debug 构建时间选取。
- 修复 `--` 后的 `--help`、`--version` 文件名被误识别问题。
- Content-Type 采用精确 MIME 类型校验，拒绝重复 charset 和残缺引号。
- 规范 Python brace 数字参数/索引的前导零，减少误报。
- 拒绝 command/config 的错误 JSON 类型，保留报告 schema 1 和公开 API。
- 以索引替代格式参数的重复扫描，并加入大量重复参数回归案例。
- 新增一条命令的本地验收、独立压缩包 consumer 验证和四项演示。
- CI 固定 GitHub Actions 到已核验的 commit，隔离 Python 依赖并保留验证产物。
- 修复 GNU 对照默认跳过 fuzzy 译文的问题，补充独立的格式类型错误案例，并支持显式指定 msgfmt 路径；CI 固定 Ubuntu 24.04。
- 外部语料支持 SHA256 验证过的本地缓存，首次下载设有超时；线上对照日志保存为验证产物。

## 0.1.0 — 2026-10-13

首次本地版本：PO/POT 解析、目录/metadata 检查、三种格式合同、复数求值、模板对照、规范化、工作量统计和 MoonBit 核心 CLI。
