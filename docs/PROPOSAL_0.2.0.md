# CatalogGuard 项目申报书

## 基本信息

- 项目名称：CatalogGuard：MoonBit PO/POT 翻译目录质量检查工具
- 参赛者：石子硕（GitHub ID：2111950632）
- 联系方式：2111950632@qq.com
- GitHub 仓库：https://github.com/2111950632/CatalogGuard
- 项目方向：MoonBit 开发者工具 / 本地化质量检查基础库
- 是否为移植项目：否，原创 MoonBit 实现，参考公开规范与工具行为。

## 项目简介

CatalogGuard 在译文合入前检查格式参数、HTML/XML 标记和跨文件一致性，面向开源软件、文档维护者及本地化团队。0.2.0 针对初审意见新增标记结构解析与树合同、按语言和上下文分组的冲突索引、可运行案例及独立参考验证。

解析、校验、分组和报告核心均由 MoonBit 实现，Node.js 只负责目录遍历与输入输出；同时提供可嵌入库 API 和 CLI/JSON。PO/POT 等共性能力不申报为独有创新。

## 核心功能范围

- HTML/XML 显式分模式，检查开闭配对、交叉嵌套、祖先结构、标签数量、属性存在和受保护值；允许同级子树、属性顺序及指定值翻译。支持范围及资源上限固定为 CGM-1，不宣称完整 HTML5/XML 验证。
- 跨文件按 Language/msgctxt/msgid 分组，报告译文、复数源文和 flags 差异，保留双方位置；隔离不同语言与上下文，排除 fuzzy/obsolete/空译文/POT，可选逆向同译文审阅。
- 保留 C11/POSIX printf、Python 3.12 百分号及 brace 三类格式合同、复数规则、POT 对照和规范化；检查失败给出位置、JSON、退出码及明确原因。
- 222 个核心用例在 JS/Wasm GC 各通过，含 63 个新标记案例和 26 个项目/边界用例；29 个 CLI 用例通过。23 项 XML 独立解析、固定 Toolkit 的 16 项标签和 5 项跨文件预期通过；另 47 项仅观察。提供 7 个 PO 示例及独立打包 API 消费验证。
- 规范、合法/错误案例和差异见 docs/PROJECT_QUALITY.md，复审说明见 docs/REVIEW_RESPONSE.md。源码版本 0.2.0，对应线上与注册表验收另附记录。

## 移植或参考说明

参考 XML/HTML 标准、C11/POSIX、Python 3.12 及 Translate Toolkit 功能概念，未复制其实现。生产代码采用 Apache-2.0，仅依赖 MoonBit 标准库；GPL 的 Toolkit 只作独立测试，不随运行包分发，来源见 THIRD_PARTY.md。

使用 AI 辅助设计、实现、测试和文档，参赛者对成果与维护负责。已实现能力、范围外构造及后续目标分别列明，不以有限案例通过宣称全生态兼容。
