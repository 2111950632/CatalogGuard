# 三类格式合同的标准和兼容终点

本文件定义 CatalogGuard Format Contract Profile 1（CGFC-1）。规范目标是 C11/POSIX printf 的静态参数合同、Python 3.12 的 str 百分号格式，以及 Python 3.12 str.format 的字段与内建规格。GNU msgfmt 1.0 是交叉参考，不是 Python 语言定义。本项目不执行 printf、Python 代码或用户的 __format__；检查通过不保证翻译语义或任意实参值正确。

## 相对 moongettext 的净增范围

基线固定为 [YanFangNie/moongettext 7ef9576](https://github.com/YanFangNie/moongettext/tree/7ef95764ed37b47d4b8fabe1a6ed12c719850437)。已阅读其 validation.mbt、公开 API、兼容矩阵，并实际调用公开 API。

| 能力 | moongettext 基线 | 本项目定位 |
|---|---|---|
| PO/POT、上下文、复数、目录校验、统计和模板处理 | 已提供 | 共性能力，不申报为净增创新 |
| MO 编译、运行时 gettext 查询 | 已提供 | 本项目不实现、不申报替代 |
| C printf 的身份、类型、星号宽度精度合同 | 未提供对应校验 | 净增检查能力 |
| Python 百分号的字典键、顺序参数和重复用途合同 | 未提供对应校验 | 净增检查能力 |
| Python brace 的路径、嵌套依赖及呈现合同 | 未提供对应校验 | 净增检查能力 |
| 上述格式诊断的位置、JSON、策略和失败退出码 | 不含上述格式合同 | 净增能力的工程出口，不单独算新算法 |

实测 `%d → %s`、`%(n)d → %(n)s`、`{n:d} → {n:s}`：基线 validate_po 不报告 error，本项目报告 F005。另加重复键对照，确认基线校验实际运行。基线结果只说明该固定提交的范围，不是否定其设计或质量。

执行 `python scripts/compare-moongettext.py` 可复现四个探针。脚本不修改对方代码；仅对基线屏蔽新编译器对旧 derive 写法的 warning 79，本项目仍用 --deny-warn。第三方源码和缓存不打包分发。

## 合同语义

合同按“参数身份 → 用途集合”比较，不按文本出现顺序比较。C 顺序实参从 1 编号；Python 百分号顺序实参从 1 编号、字典键另设命名空间；brace 从 0 编号并保留属性和下标路径。译文须保留全部身份和用途集合。相同用途可重复，显式编号或命名字段可合法重排；宽度精度数值和普通文本不要求相同。

同一 Python 参数同时用于默认、整数、repr 等用途是合法的，抽取器保留规范排序的用途集合，不因重排误报。删除其中一种用途属于合同变化。F001/F002 为源文/译文的语法、未支持构造或资源边界失败，消息写明原因；F003 缺失参数，F004 多余参数，F005 用途变化。失败不会被忽略或当成通过。

## 固定目标标准

| 标记 | 标准及范围 | 边界 |
|---|---|---|
| c-format | [WG14 N1570 7.21.6.1](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf) 的 C11 printf，加 [POSIX 编号参数](https://pubs.opengroup.org/onlinepubs/9699919799/functions/printf.html)；diouxX、aAeEfFgG、c/s/p/n/%%；合法 length、flags、字面及星号宽度精度；m$ 和 *m$；检查 #、0、precision、%n 的未定义组合 | 编号不得混用或留空洞。GNU %m、I、分组旗标是列明的附加支持；不含全部平台扩展或 C23 格式 |
| python-format | [Python 3.12 str 百分号格式](https://docs.python.org/3.12/library/stdtypes.html#printf-style-string-formatting)；字典键或顺序参数，全部文档转换符、flags、字面/动态宽度精度、忽略的单个 h/l/L、%%；空键、Unicode 键、括号键和重复用途 | 按文档的可移植字典模式，不支持与顺序实参混用或字典动态星号；不含 bytes 格式 |
| python-brace-format | [Python 3.12 Format String Syntax 和内建 Mini-Language](https://docs.python.org/3.12/library/string.html#format-string-syntax)；自动/编号/命名根、属性下标、Unicode 名称和 Unicode 15.0 十进制索引、转义、!s/!r/!a、内建规格、一个嵌套字段层、动态依赖 | 不执行 f-string 表达式、自定义对象规格、属性访问或实参格式化；拒绝更深嵌套及已知非法内建选项组合 |

参数位置上限 10000，下标为有符号 32 位非负整数，最多 4096 个不同身份；超出时明确失败。Unicode 数字性质固定为 Python 3.12 的 Unicode 15.0。Python 运行参考为 CPython 3.12.14。

## 完整兼容终点与当前状态

完整兼容的终点固定为以上三类静态合同规范，不扩大到 GNU gettext 全功能或任意 Python 执行器。终点验收要求：

1. CGFC-1 内每个语法产式及类型组合有实现和正反分支案例，合法重排与等价编号可接受。
2. 无效组合、明确排除项和资源边界失败可复现；同一合法参数的多种用途可重排。
3. Python 正常/异常实例在固定 CPython 3.12 独立执行；C 合同与固定 GNU 参考交叉核对；规范差异逐项记录，不能让 GNU 结果覆盖 C11 或 Python 文档。
4. JS/Wasm GC、CLI/公开 API 结果一致，发布后独立项目可下载复验。

0.1.2 完成本次 96 个分类案例和已发现问题的修复。该案例集不是对所有字符串、平台 ABI 或用户对象的穷尽证明，**目前不宣称全规范兼容已完成**。剩余兼容工作是逐项补齐转换类型与选项组合矩阵、随机合法重排及变异用例，再完成同版本发布后消费验收；达到以上门槛才标记兼容终点达成。复审以已实现的净增能力和证据为依据，不把后续计划计作成果。

## 合法重排与边界案例

| ID | 源文 | 译文 | 预期 |
|---|---|---|---|
| C-01 | `%s has %d files` | `%2$d files for %1$s` | 通过 |
| C-02 | `%*.*f %s` | `%4$s %3$*1$.*2$f` | 通过 |
| P-01 | `%(name)s %(count)d` | `%(count)d %(name)s` | 通过 |
| P-13 | `%(x)s %(x)r` | `%(x)r %(x)s` | 通过，多用途重排 |
| B-02 | `{} {:d}` | `{1:d} {0}` | 通过 |
| B-05 | `{v:{w}.{p}f} {name!s}` | `{name!s} {v:{w}.{p}f}` | 通过，保留动态依赖 |
| B-08 | `{[name]}` | `{0[name]}` | 通过 |
| B-33 | `{٠}` | `{0}` | 通过，十进制身份规范化 |
| C-20 | `%s %d` | `%1$s %d` | F002，混用编号 |
| C-30 | `%n` | `%+n` | F002，C11 未定义组合 |
| P-22 | `%(x)s` | `%(x)*s` | F002，字典星号 |
| B-25 | `{0:{1}}` | `{0:{1:{2}}}` | F002，过深嵌套 |
| B-26 | `{x:s}` | `{x:+s}` | F002，字符串符号选项 |
| B-30 | `{x!s}` | `{x!s:d}` | F002，转换后规格不合法 |

完整源为 tests/format-cases.json：34 个 C、24 个 Python 百分号、38 个 brace 案例。执行 `python scripts/generate-format-tests.py`、`moon fmt` 可生成回归测试；生成测试不计入生产代码。

## GNU 1.0 交叉参考的已知差异

| ID | 规范或合同选择 | GNU 1.0 观测 |
|---|---|---|
| C-07 | C11 %lf 与 %f 传参合同一致 | 拒绝 %lf |
| C-26 | C11 百分号指令必须为 %% | 接受带宽度的百分号 |
| B-07 | Python 将前导零数字身份规范化 | 报告身份不同 |
| B-13 | Python 3.12 支持下划线分组 | 拒绝该规格 |
| B-17 | CGFC-1 保留全部动态依赖 | 允许省去该命名依赖 |

全部 96 案例记录 GNU 结果；其中 73 项对 GNU 1.0 固定预期作断言，其余 23 项仅观察，不算作“对照通过”。其他 GNU 版本只记录结果，不假定等同 1.0。55 项 Python 运行探针独立验证源文和译文的有效/无效预期。Python 能运行不等于翻译合同未变，例如整数改成字符串转换仍可运行，却改变源文用途。

复现：Python 3.12 下执行 `python tests/format_conformance.py --msgfmt PATH`，或在配置好 GNU gettext 后执行 `npm run verify:independent`。证据为 evidence/format-conformance-0.1.2.json 与 evidence/moongettext-baseline-0.1.2.json。检查核心仍全部在 MoonBit；Python 仅用于独立验收。
