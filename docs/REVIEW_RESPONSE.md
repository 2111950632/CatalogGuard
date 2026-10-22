# CatalogGuard 第二轮初审补充说明

0.2.1（2026-10-22）继续完成终审工程自查：修复属性 CRLF/CR 规范化、非法语言分组和逆向冲突遗漏。新增 17 个核心回归与 3 个 CLI 场景，当前两后端各 239 项、CLI 32 项；69 个标记矩阵与 729 个小项目的朴素参考对照见 docs/FINAL_REVIEW.md 和对应版本证据。下文保留 0.2.0 初审扩展的历史范围与计数，不将其冒充为新版发布证明。

2026-10-19 · 石子硕 · GitHub 2111950632 · 源码版本 0.2.0

针对“增量有限，至少补充 HTML/XML 标记结构、跨文件一致性及案例”的意见，本次已新增 MoonBit 标记片段解析器、树合同比较、跨文件冲突索引，以及库 API、配置、CLI 和独立参考验证。原有三类格式合同继续保留，共性 PO/POT 功能不申报为独有创新。

## 本次实质新增

| 模块 | 已实现范围 |
|---|---|
| HTML/XML 标记 | 显式分模式，检查配对、交叉闭合、树祖先关系、数量、属性存在性及受保护值；处理引号、实体、注释、XML CDATA、HTML void 元素及资源上限 |
| 合法翻译变化 | 允许同级子树、属性顺序、文本和指定属性值变化，保留链接、资源路径、id 与所属子树的关联；不以简单标签计数代替树比较 |
| 跨文件一致性 | 按 Language/msgctxt/msgid 分组，比较所有译文槽位、复数源文和格式 flags；可选忽略上下文或逆向同译文审阅，报告双方文件和范围 |
| 工程入口 | 新增 check_project 等公开 API、quality 配置、递归目录输入、JSON 项目关联诊断；严格模式和规则严重性一致生效，输入与资源超限明确失败 |

检查核心位于 markup.mbt、consistency.mbt、project.mbt。Node.js 仅负责目录遍历、UTF-8 读写和参数传递；生产代码没有 Python、lxml 或 Translate Toolkit 依赖。

## 合法与错误案例

| 案例 | 源文 / 译文变化 | 实际结果 |
|---|---|---|
| 同级重排 | `<b>One</b><i>Two</i>` → `<i>二</i><b>一</b>` | 通过 |
| 属性重排与翻译 | href 保留，title 翻译，属性换序 | 通过 |
| 错误嵌套 | `<b><i>中</b></i>` | M002 |
| 保护值变化 | href `/help` → `/pay` | M003 |
| 相同计数、祖先变化 | 将 i 从 b 内移到 u 内 | M003 |
| XML 实体 | 译文含未声明实体或 `&#0;` | M002 |
| 同源不同译文 | 两个中文文件 Save → 保存 / 存储 | X002，含双方位置 |
| 语言或上下文不同 | 中文/法文；动词/形容词上下文 | 默认不冲突 |

完整规范案例为 tests/markup-cases.json；另有 26 个项目、配置和资源用例。examples/project-quality 提供 7 个直接运行的 PO 文件、配置和预期结果，正常/错误项目和正常/错误 XML 四个命令预期退出码分别为 0、1、0、1。

## 实际验证和参考边界

222 个核心用例在 JavaScript 与 Wasm GC 各通过，包含此前 133 项、本次 63 个标记案例和 26 个项目/边界用例；29 个 CLI 用例通过。真实压缩包提取后的独立 consumer 同时调用旧 API 和新 API，在两后端各通过；226 项总数含库的 222 项，仅新增 4 个消费探针。

独立验证使用 Translate Toolkit 3.20.0：63 个标签行为观测中 16 项固定预期作断言，另外 47 项只观察；5 个跨文件场景均断言本项目和 poconflicts 的预期。Python ElementTree 另外验证 23 个 XML 目标。原有 96 个格式案例、55 项 Python 运行探针、73 项 GNU 1.0 固定预期及 polib 4 文件/221 条消息对照仍通过，不把重复运行或观察项计作新增通过数。

CGM-1 是受限平衡片段合同，不是浏览器 HTML5 建树、完整 XML 文档、命名空间等价或 DTD/schema 验证；外部实体不展开，范围外构造会明确失败。CGP-1 的冲突是质量审阅线索，不自动裁定哪一种译法正确。完整边界、资源上限及固定参考差异见 docs/PROJECT_QUALITY.md，原有格式终点见 docs/FORMAT_CONTRACTS.md。

本项目允许同级与属性换序，而固定 Toolkit xmltags 在相应案例中拒绝；本项目额外拒绝部分不平衡或非法 XML 实体案例。poconflicts 需要调用者提供单一语言输入，本项目在核心中按 Language 隔离。以上是固定版本的实测差异，不泛化为 Toolkit 全部能力的评价，也不宣称完全兼容。

## 复现与开源说明

```sh
moon build --target js --release
cd examples/project-quality
node ../../cli.mjs valid --recursive --markup html --consistency --strict --json
node ../../cli.mjs broken --recursive --markup html --consistency --strict --json
```

公共仓库 https://github.com/2111950632/CatalogGuard ，模块名继续为 2111950632/szs。本次本地验收见 evidence/VALIDATION-0.2.0.md，独立参考证据为 evidence/quality-conformance-0.2.0.json；对应版本的线上检查与注册表发布以另附交付记录为准。

MoonBit 实现为本项目新编写的代码，未复制 Translate Toolkit 等工具源码。参考标准和测试工具来源、版本及许可证见 THIRD_PARTY.md；生产代码 Apache-2.0。使用 AI 辅助设计、实现、测试和文档，提交者负责理解、验证及维护。本材料用于请求重新审核，不代表已通过复审。
