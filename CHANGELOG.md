# 更新记录

## 0.2.0 - 2026-10-19

- 新增 MoonBit HTML/XML 平衡片段解析和树合同：检查嵌套、数量、属性与受保护值，允许同级及属性重排，区分两种模式的 void、大小写和实体语法。
- 新增按 Language/context/msgid 分组的跨文件译文、复数源文、格式 flags 冲突，以及可选的逆向同译文审阅；保留冲突双方文件和字段位置。
- 新增 ProjectPolicy/check_project 公开 API、quality 配置、CLI 项目开关与递归目录输入，保持旧 Options/Policy 和 JSON schema 1 兼容。
- 新增 63 个标记案例、26 个项目/配置/资源用例和 10 个 CLI 用例，固定 Translate Toolkit 3.20.0 及独立 XML 解析对照。
- 补充 7 个可运行 PO、两分钟演示、独立包新旧 API 消费、规范边界、维护者讲解与第二轮复审材料。
- 不宣称完整 HTML5/XML 或 Translate Toolkit 兼容；范围外和超限构造明确失败。

## 0.1.2 — 2026-10-16

- 明确相对 moongettext 固定提交的净增范围与三类标准、兼容终点和已知差异。
- 增加 96 个格式合同案例：合法重排、重复用途、动态依赖、Unicode 数字及边界语法。
- 修复 Python 空映射键、同一参数多种用途被误拒；按排序后的用途集合比较合同。
- 支持 brace 自动路径、Unicode 字段与数字身份以及合法的字面下标内容。
- 拒绝过深嵌套、转换后数值规格、内建类型非法选项及 C11 未定义组合。
- 加入 CPython 3.12/GNU 独立验收与原样 moongettext 基线四探针对照，保存可复核证据。
- 更新 GitHub 仓库路径及展示名称；保留 Mooncakes 模块名和 JSON schema 1。

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
