# CatalogGuard 项目申报书

## 基本信息

- 项目名称：CatalogGuard：MoonBit PO/POT 翻译目录质量检查工具
- 参赛者：石子硕（GitHub ID：2111950632）
- 联系方式：2111950632@qq.com
- GitHub 仓库链接：https://github.com/2111950632/CatalogGuard
- 项目方向：MoonBit 开发者工具 / 本地化质量检查基础库
- 是否为移植项目：否，原创 MoonBit 实现，参考公开规范与工具行为。

## 项目简介

CatalogGuard 为开源软件、文档维护者和本地化团队提供可嵌入的 MoonBit 检查库及 CLI，在译文合入前发现格式参数、HTML/XML 标记结构和跨文件译文冲突，给出文件、条目及关联位置。解析、校验、分组和报告核心由 MoonBit 实现，Node.js 仅负责参数、目录遍历及 UTF-8 输入输出。当前源码版本 0.2.2，在新增功能基础上持续完成终审自查、边界修复与自动回归。

## 核心功能范围

- HTML/XML：显式选择平衡片段模式，检查配对、嵌套、祖先关系、标签数量、属性存在及受保护值。允许同级子树和属性重排，如 `<b>One</b><i>Two</i>` 可译为 `<i>二</i><b>一</b>`；交叉闭合、改写 href 会报错。支持边界固定为 CGM-1，不宣称完整 HTML5/XML 验证。
- 跨文件：按 Language/msgctxt/msgid 分组，比较全部译文槽位、复数源文和 flags，保留双方位置；隔离语言和上下文，排除 fuzzy/obsolete/空译文/POT。相同中文源文 Save 的“保存/存储”差异会提示冲突；可选逆向同译文审阅。
- 格式及目录：在 CGFC-1 声明范围检查 C11/POSIX printf、Python 3.12 percent/brace 参数身份、用途和类型；提供 UTF-8 PO/POT 解析、头部校验、受限复数求值、POT 对照、统计和规范化。共性 PO/POT 能力不申报为相对既有生态的独有创新。
- 工程入口：提供公开 API、配置、递归输入、文本及版本 1 JSON 报告和退出码 0/1/2；资源超限明确失败。修复行尾、非法语言分组、正逆向冲突遗漏和 HTML C1 数字引用；每项比较每组至多五个见证，正向/逆向分别用朴素参考穷举 768/729 个小项目核对。
- 验证：两后端各通过同一组 256 个核心用例，CLI 37 项；80 个标记案例含 30 项独立 XML 解析、7 项 XML 和 7 项 HTML 属性对照。固定 Toolkit 3.20.0 的 16 项标签预期、5 个跨文件场景通过，64 项标签仅观察；CI 另运行 960 个生成标记输入及 350 个多文件项目的逐条参考检查，均不混算为核心用例。提供 7 个可运行 PO 示例。
- 复现与范围：[README](https://github.com/2111950632/CatalogGuard)、[功能边界](https://github.com/2111950632/CatalogGuard/blob/main/docs/PROJECT_QUALITY.md)、[格式边界](https://github.com/2111950632/CatalogGuard/blob/main/docs/FORMAT_CONTRACTS.md)、[运行案例](https://github.com/2111950632/CatalogGuard/blob/main/examples/project-quality/README.md)和[终审自查记录](https://github.com/2111950632/CatalogGuard/blob/main/docs/FINAL_REVIEW.md)均在仓库。[Mooncakes](https://mooncakes.io/docs/2111950632/szs) 模块 `2111950632/szs@0.2.2` 已发布；独立项目实际下载后两后端各通过 9 项 API 探针，40 个 MoonBit 源文件与发布包及仓库一致。

## 移植或参考说明

参考 GNU gettext、C11/POSIX、Python 3.12、XML/HTML 标准及 Translate Toolkit 的功能概念，未复制其实现。生产代码采用 Apache-2.0，仅依赖 MoonBit 官方标准库。独立测试工具、标准和第三方语料的来源、版本、使用范围与许可证见 [THIRD_PARTY.md](https://github.com/2111950632/CatalogGuard/blob/main/THIRD_PARTY.md)；外部语料不打包分发，不计入项目实现。

使用 AI 辅助设计、代码、测试和文档，参赛者负责理解、验证和维护。已实现范围、范围外构造和参考差异分别列明，不以有限案例通过宣称完整生态兼容。
