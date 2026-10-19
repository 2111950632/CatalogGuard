# CGM-1 标记结构与 CGP-1 跨文件检查

版本 0.2.0，2026-10-19。本次针对第二轮初审意见新增 MoonBit 实现，扩展此前的三类格式合同检查。Node.js 只遍历目录、读取 UTF-8 文件和输出结果。新功能参考 Translate Toolkit 的功能划分，由本项目重新实现，不将已有工具的能力描述为全球首创。

## 两分钟运行

```sh
moon build --target js --release
node cli.mjs examples/project-quality/valid --recursive --markup html --consistency --strict --json
node cli.mjs examples/project-quality/broken --recursive --markup html --consistency --strict --json
node cli.mjs examples/project-quality/xml-good.po --markup xml --strict --json
node cli.mjs examples/project-quality/xml-broken.po --markup xml --strict --json
```

退出码依次为 0、1、0、1。错误示例包含 M002、M003、X002，JSON 的 project_findings.related 给出另一个文件、条目及范围。检查不修改原文件。

## CGM-1：翻译标记合同

目标是开发期的**平衡片段合同**，借用 [XML 1.0](https://www.w3.org/TR/xml/) 的名称、配对、引号、实体和 CDATA 约束，以及 [HTML 语法](https://html.spec.whatwg.org/multipage/syntax.html) 的大小写、void 元素和属性规则；它不是完整 XML 文档验证器或浏览器 HTML5 建树器。

- 显式选择 html 或 xml，默认 off。普通文本中的 `<Error>`、数学小于号不会自动触发推测检查；选择片段模式后，这些内容须按相应语法转义。
- 检查开闭配对、交叉闭合、缺失闭合、标签树祖先关系、标签数目及属性重复/缺失。通过长度前缀编码及同级子树排序比较合同，允许同级子树重排，仍保留属性与所属子树的绑定关系；仅比较标签计数不足以覆盖这些情况。
- 文本可翻译，属性顺序可改变。默认仅 alt、title、aria-label、placeholder、lang、xml:lang 的值可翻译，其属性存在性仍须保留；其他属性的值受保护，包括 href、src、id、class 及命名空间声明。可在配置中替换可翻译属性列表。
- HTML 使用 ASCII 大小写不敏感的名称、13 个当前标准 void 元素、引号/非引号属性及空值布尔属性。要求非 void 标签显式成对，不实现可省略闭合、错误修复、内容模型、raw-text、template、SVG/MathML 解析。布尔属性的非空值仍按字面合同比较。
- XML 名称区分大小写；支持 Unicode 名称、显式成对/自闭合等价、注释、CDATA、五种预定义实体和有效的十/十六进制字符引用；属性的字面换行/制表符按空格规范化。限定名按字面保存，**不做命名空间 URI 等价或 schema/DTD 验证**。
- DTD、外部实体、声明和处理指令明确报“范围外”；不会请求网络或展开实体。HTML 中五种预定义实体、nbsp 与数字引用参与属性值规范化，其他命名实体按原样保留，不宣称完整 HTML 实体表验证。
- 单复数源文须具有同一标记合同，不能根据 msgstr[0] 猜测任意语言的单数语义。源合同不同报 M004，不静默选择其中一个。空译文沿用原有空译文规则，obsolete 跳过；fuzzy 译文仍检查标记安全性。

| 代码 | 含义 |
|---|---|
| M001 | 源标记语法错误、范围外构造或资源限制 |
| M002 | 译文标记语法错误、范围外构造或资源限制 |
| M003 | 树结构、属性存在性或受保护值变化 |
| M004 | 单复数源标记合同不同 |

默认每个字符串最多 262144 个 UTF-16 单元、4096 个元素、64 层；可配置的绝对上限为 1048576、16384、128。到达限制会明确失败，不以截断后的结果充作通过。MarkupError.offset 为解码后 Unicode 字符偏移；PO 诊断范围定位到包含它的源/译文字段，不伪造转义和续行后的精确原始字符位置。

## CGP-1：跨文件一致性

采用 [poconflicts](https://docs.translatehouse.org/projects/translate-toolkit/en/latest/commands/poconflicts.html) 的冲突审阅概念，默认保持文本和大小写精确匹配，另加显式语言与上下文隔离：

1. 按 Language、msgctxt、msgid 建索引。Language 仅规范化大小写和 `_`/`-`，不合并 zh-CN/zh-TW 或 fr/de；缺失或非法语言产生 X001，文件不加入猜测的语言组。
2. 比较所有 msgstr 索引和值：同键不同译文为 X002；不同 msgid_plural 为 X003；format flags 差异为 X004。不同文件之间比较，单文件重复仍由原有 C001 负责。
3. `--ignore-context` 显式合并上下文；`--inverse-consistency` 另检查同一译文对应不同源文（X005）。这两项会扩大人工审阅范围，默认不开启。
4. fuzzy、obsolete、空译文、损坏的解析结果及 POT 不作为译文冲突证据。空目录、非法配置和重复输入路径以调用错误处理。
5. X002/X004/X005 是可配置 warning，因为用词差异可能有意；严格模式使 warning 导致退出 1，也可将 X002 提升为 error。X003 和资源错误不能关闭。检查不自动选“正确译法”。

每请求最多 1000 个文件，输入累计最多 32 MiB，跨文件默认最多 100000 个条目（含头部），可设 1..1000000；超限 X009，停止该项目比较。目录遍历只选 PO/POT，排序稳定，跳过符号链接与常见缓存，遍历最多 32 层。索引避免对全部条目两两比较。

## 配置与公开 API

```json
{
  "schema_version": 1,
  "options": { "strict": true },
  "quality": {
    "markup": { "mode": "html" },
    "consistency": { "enabled": true, "ignore_context": false, "inverse": false }
  },
  "rules": { "X002": "error" }
}
```

执行 `node cli.mjs DIR --recursive --config examples/project-quality/ci.json --json`。CLI 显式选项覆盖配置。配置的未知字段、错误类型和越界值会失败。

库 API：markup_contract、check_markup_catalog、check_consistency、parse_project_policy、check_project、project_finding_json。旧 Options、Policy、parse_policy 和 check_catalog 接口保持不变；新 ProjectPolicy 将它们组合起来。JSON schema_version 继续为 1，新增 project_findings；旧 files[].diagnostics 也包含项目诊断，related 的跨文件位置位于 project_findings 中，避免将另一个文件的范围误解为当前文件。

## 与固定参考的实际关系

参考工具为 **Translate Toolkit 3.20.0**，公共接口 StandardChecker.xmltags 与 poconflicts。该版本 StandardChecker 不提供旧文档中的 validxml 方法；XML 有效性另用 Python ElementTree 独立验证。

| 案例 | CatalogGuard | Toolkit 3.20.0 xmltags 观测 |
|---|---|---|
| `<b>x</b>` → `<b>中</b>` | 通过 | 通过 |
| `<b>x</b>` → `中` | M003 | 拒绝 |
| 同级 `<b>…</b><i>…</i>` 重排 | 通过 | 拒绝 |
| 同一 `<a>` 的 href/class 属性重排 | 通过 | 拒绝 |
| href 改写 | M003 | 拒绝 |
| `<br>` → `<br></br>` | HTML 模式 M002 | 接受 |
| XML 未声明实体或 NUL 字符引用 | M002 | 接受 |

以上是固定版本、固定案例的实际行为，不泛化为全部 Toolkit 工具的能力评价。CGM-1 接受合法的同级/属性重排，拒绝受限片段中的结构错误；不能将 xmltags 返回值当作完整 XML 合法性证明。poconflicts 的输入目录由调用者负责同语言分组，本项目将分组作为核心合同并给出双方位置。

完整证据：63 个标记案例（38 HTML、25 XML）；23 项 ElementTree 目标解析探针；63 项 Toolkit 标签观测，其中 16 项固定预期作断言，其余 47 项只观察；5 个跨文件场景均对 CatalogGuard 和 poconflicts 的预期作断言。另有 26 个项目、配置、资源及关联位置的核心用例。JS/Wasm GC 各运行同一组 222 个核心用例，不将两次运行算作 444 个不同案例。

复现：`python -m pip install -r tests/quality-requirements.txt` 后执行 `python tests/quality_oracle.py`。独立参考只用于测试，生产核心没有这些依赖。规范的 JSON 夹具、生成测试、手写项目用例和可运行 PO 示例都在仓库；证据见 evidence/quality-conformance-0.2.0.json。有限案例不构成对整个 XML/HTML 或 Translate Toolkit 的完整兼容证明。
