# 结构与检查边界

`model.mbt` 定义目录、条目、位置、诊断和策略。`parser.mbt` 用状态机解析字段，累积转义后的 UTF-8 字节再解码，避免跨续行的字节序列被误判。语法错误进入 diagnostics，不抛出导致整个批次终止的异常。

`header.mbt` 读取 metadata。`checker.mbt` 检查结构、重复键、策略和内容，再调用格式与复数模块。`template.mbt` 通过长度编码的精确 context/id 键比较模板，区分无 context 与空 context，不通过模糊猜测改变译文。

`format.mbt`、`brace.mbt` 和 `python_percent.mbt` 生成参数合同并比较。显式编号允许参数重排；重复使用同一编号不被误算成额外参数。星号宽度和精度同样消耗参数。Python 的 presentation/conversion 合同是保守检查，不是完整运行时类型推断。

`plural.mbt` 分为 tokenization、优先级语法解析、AST、受预算限制的求值和有限覆盖。`&&`、`||`、`?:` 采用短路。算术通过 Int64 中间值检查 32 位溢出，不依赖宿主 eval。源表达式上限 4096 字符、2048 token；动态求值还有独立深度和操作预算。

`writer.mbt` 输出规范语法，保留 decoded 字符串和条目内注释。遇到解析诊断或不安全结构拒绝输出。`summary.mbt` 提供上下文与源引用工作量。`policy.mbt` 只允许指定审阅规则改级或关闭，不允许配置吞掉解析错误。

`report.mbt` 使用显式 JSON null 或标量表示可选字段，避免 MoonBit 默认 Option 编码影响外部消费者。`json_input.mbt` 在解析 JSON 前检查嵌套上限。`protocol.mbt` 以字符串 JSON 作为宿主边界，`cmd/main` 只通过两条 JS 外部函数收发请求。

`cli.mjs` 读取 UTF-8 文件、传入请求、加载构建后的 MoonBit 核心并输出结果；不实现目录、格式、复数或检查规则。测试包含白盒算法案例、公开 API 消费测试、CLI 进程测试与独立 polib 对照。GNU msgfmt 的正常/异常样例对照在 CI 中设置为必须通过，但不能据此声称检查覆盖与 GNU 完全相同。

默认与可配置资源范围在 README 和 Options 中列出。原始字节入口报告解码错误；若 decoder 未提供精确偏移，就指向文件第一行并明确说明，不编造错误位置。
