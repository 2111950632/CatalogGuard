# CatalogGuard

MoonBit 编写的 PO/POT 翻译目录检查库与命令行工具。项目由 `2111950632` 维护，面向 MoonBit 文档、应用本地化和 GitHub CI 中的翻译检查。

当前版本 0.2.2。继续修复终审复查发现的忽略上下文漏报及 HTML 数字字符引用误报/漏报。跨文件索引为每项比较保留至多五个见证，独立比较复数源文、同复数源文的译文及格式 flags。两个朴素参考分别穷举 768 个正向和 729 个逆向小项目；另有 960 个生成标记输入及 350 个多文件项目检查随标准验证和 CI 运行。功能边界保持显式，旧版成果按版本保留。

0.2.0 针对第二轮初审新增 **HTML/XML 标记结构和跨文件一致性检查**，与原有三类格式合同组成可嵌入 MoonBit 的翻译质量检查核心。新增功能、与固定版本 Translate Toolkit 的实际对照、合法与错误案例见 [项目质量检查边界](docs/PROJECT_QUALITY.md)。PO/POT、目录校验、复数和模板处理与 [moongettext](https://github.com/YanFangNie/moongettext) 存在重叠，不申报为独有能力；格式标准和兼容终点仍见 [格式合同说明](docs/FORMAT_CONTRACTS.md)。

解析、格式与标记合同、跨文件分组比较、复数求值、模板对比、配置校验、报告生成均在 MoonBit 中实现；Node.js 入口负责参数传递、目录遍历、UTF-8 文件读取和输出。核心不执行宿主语言 `eval`，不需要第三方运行时包。

## 快速运行

安装 [MoonBit 工具链](https://docs.moonbitlang.com/en/latest/cli/moon/index.html) 和 [Node.js 20 或更新版本](https://nodejs.org/en/download)，在项目目录运行：

```sh
moon build --target js --release
node cli.mjs check examples/zh_CN.po --template examples/messages.pot --strict
node cli.mjs examples/project-quality/valid --recursive --markup html --consistency --strict --json
```

预期输出：3 条有效消息，3 条已翻译，0 个错误、0 个警告。故意出错的例子用于演示诊断和失败退出码：

```sh
node cli.mjs check examples/broken.po --json
node cli.mjs inspect examples/zh_CN.po --json
node cli.mjs stats examples/zh_CN.po --json
node cli.mjs plural 'nplurals=2; plural=(n!=1);'
node cli.mjs rules
```

依次展示正常、错误、JSON 和复数规则四项演示：`npm run demo`。录屏步骤见 [演示提纲](docs/DEMO.md)。

PowerShell、macOS 和 Linux 均可使用上面的命令。目录路径包含空格时加引号。PowerShell 查看上一条程序的退出码用 `$LASTEXITCODE`。

下载带 `dist/szs-core.js` 的运行包后，只需 Node.js 即可执行 `node cli.mjs ...`，无需再次编译。GitHub 源码不提交构建产物；从源码运行时先构建。要制作运行包：

```sh
moon build --target js --release
node scripts/package.mjs
```

同目录存在本地构建时，CLI 使用 release/debug 中最近构建的版本；无本地构建时加载运行包的 `dist` 核心，避免重新构建后仍运行旧发布文件。

## 检查范围

| 功能 | 本版本行为 |
|---|---|
| PO/POT 解析 | UTF-8、BOM、CRLF、多行字符串、字节转义、上下文、注释、引用、flags、obsolete |
| 源位置 | 文件名、条目索引、从 1 开始的行列；字符串续行纳入范围；end 为排他位置 |
| 目录与 metadata | 重复 context/msgid、缺失字段、头字段、charset、日期、空翻译、fuzzy、NUL、换行边界 |
| 格式合同 | 显式 `c-format`、`python-format`、`python-brace-format` 的参数身份和类型；C 参数序号、星号宽度精度；Python 命名字段 |
| HTML/XML 标记 | 显式选择片段模式；配对与嵌套、祖先关系、数量、属性存在与受保护值；允许同级子树、属性顺序及可翻译值变化 |
| 跨文件项目检查 | 按语言/上下文/源文建索引，报告译文、复数源文和格式标记冲突，提供双方位置；可选逆向同译文审阅 |
| 复数 | 受限语法解析、短路求值、除零与整数溢出、索引范围、翻译槽位完整性、有限区间覆盖 |
| POT 对比 | 精确匹配 context/msgid，报告缺失、多余、plural 来源变化、format flags 变化 |
| 配置 | 合法性校验、空翻译/fuzzy 严重性、严格模式、资源限制；部分审阅规则可关闭或改级 |
| 输出 | 文本、版本 1 JSON、目录结构、按 context 和源文件统计的翻译工作量 |
| 规范化 | 输出规范 PO 文本，保留条目内注释及 decoded 字符串，不修复翻译含义 |

退出码：`0` 通过所选策略，`1` 检查失败，`2` 参数、配置、文件读取或规范化拒绝。默认 warning 不导致失败；`--strict` 使 warning 导致失败。`inspect` 只检查解析，不代表所有翻译规则通过。`stats` 仍运行检查，并返回相同的策略退出码。

```sh
node cli.mjs check examples/broken.po --config examples/strict.json --json
node cli.mjs normalize examples/zh_CN.po --output normalized.po
```

`--output` 仅写入新文件，拒绝覆盖。省略该参数时输出到终端。通过 `-` 从标准输入读取。`.pot` 扩展名自动启用模板模式，也可用 `--pot`。

## 支持边界

- 只接受 UTF-8；不读 MO，不自动转换编码，不提取源代码，不执行译文格式化，不做机器翻译或语义评分。
- 根据显式 flags 检查格式。普通文本中的 `%` 或 `{}` 不触发推测检查；`possible-*` 和未支持的格式 flags 有提示。`no-*` 表示不检查对应格式，矛盾 flags 报错。
- 标记和跨文件检查默认关闭，分别用 `--markup html|xml`、`--consistency` 启用。CGM-1 是受限平衡片段合同，不是完整 HTML5/XML 验证器；范围外构造明确失败。语言、上下文隔离与冲突审阅策略详见项目质量检查边界。
- C printf 目标为 C11/POSIX 静态参数合同，另支持列明的 GNU 扩展。Python 目标为 3.12 的 str 百分号和 str.format 内建规格；支持 Unicode 名称、数字身份、自动路径和一层嵌套依赖。同一参数的不同合法用途记录为集合，可重排但须保留。合同语义和未覆盖范围见格式合同说明，不等同于完整格式化执行器。
- 复数是受检的有符号 32 位整数语义，**仅测试 `n=0..plural_max`，不证明所有整数输入都安全或所有形式都可达**。默认上限 1000，可设 0..100000；嵌套、token 和操作预算有上限。报告包含实际检查进度。
- 头字段诊断指向所在 msgstr 范围，不猜测 decoded metadata 的原始精确行。源引用按空白分词；包含空白的复杂文件名不是完整支持范围。
- obsolete 条目保留但不检查。规范化拒绝解析诊断、无法关联的末尾注释及不能安全输出的结构，避免静默丢失数据。顺序和换行布局会规范化；不是逐字节往返。

## MoonBit 库 API

包名为 `2111950632/szs`。主要接口见 [生成的公开接口](pkg.generated.mbti) 与 [公开 API 测试](api_test.mbt)：

```moonbit
let catalog = @szs.parse_catalog(source, file="zh_CN.po")
let report = @szs.check_catalog(catalog)
let json = @szs.report_json(report)
```

还提供原始字节入口、复数 parser/evaluator、格式合同、POT 对比、规范化和工作量统计。0.2.0 新 API 包括 markup_contract、check_markup_catalog、check_consistency、parse_project_policy 和 check_project。旧 Options、Policy 与 check_catalog 保持兼容。包名继续使用 2111950632/szs；版本对应的线上/发布验收另附交付记录。发布步骤见 [发布说明](docs/RELEASE.md)。

## 验证

```sh
moon check --target all --deny-warn
moon test --target js --deny-warn
moon test --target wasm-gc --deny-warn
moon info
moon fmt --check
moon build --target js --release --deny-warn
node --test tests/integration.mjs
node scripts/count-source.mjs
```

完整标准验证分别在 `moon 0.1.20261012 / moonc 0.10.15` 和当日官方 `moon 0.1.20261021 / moonc 0.10.17` 下通过，Node.js 24.19.0。CI 记录实际工具链版本，使用官方当前工具链；工具链更新可能需要显式升级 API，失败不会被跳过。

安装 Python 3.9 或更新版本后，`npm run verify` 按顺序完成核心检查、两种后端测试、CLI 测试、打包和独立 consumer 验证。它从 `moon package` 的真实压缩包提取源码，在单独项目中调用 API；需要 Python 标准库，不需要 polib。`SZS_MOON`、`SZS_PYTHON` 可指定本机工具路径。

装好 Python 3.12、`tests/quality-requirements.txt` 中的固定参考工具和 GNU gettext 后，可执行 `npm run verify:independent` 加上独立对照。依赖缺失或网络下载失败会停止验证，不会跳过后宣称成功。CI 同时保存工具版本、示例报告、源码统计与包供下载。

独立比对使用 polib 1.2.0 和固定提交的 MoonBit 官方中日文 PO 文件；只比较明确支持的解析字段。外部语料不计入项目代码、不打包分发：

```sh
python -m pip install polib==1.2.0
node scripts/fetch-fixtures.mjs
python tests/oracle.py tests/external/moonbit-docs-0.po tests/external/moonbit-docs-1.po
# 安装 GNU gettext 后，可添加 --gnu 比较正常/异常样例的结果
```

源码统计把生产代码、测试、生成接口、外部语料和 Node 入口分开。非空非整行注释的行数包含结构语法，不冒充主办方认证的有效代码行。

## 参赛与原创说明

本项目从个人仓库的 README 初始提交继续开发。PO/POT 检查已有 GNU gettext、polib、Translate Toolkit 等成熟工具；本项目的价值是 MoonBit 检查核心、清楚的诊断与支持边界、可嵌入 API 和可重复运行的工程入口，不宣称全球首创。

MoonBit 实现为本项目新编写，未复制 GNU gettext、polib 或 Translate Toolkit 的实现代码。使用 AI 辅助开发，由仓库作者负责审核、验证和提交。参考与外部测试来源见 [来源说明](THIRD_PARTY.md)。代码按 Apache-2.0 授权。

比赛资格、申报截止与发布要求，以 [比赛官网](https://moonbitlang.github.io/Hackathon2026/) 和主办方最新章程为准。仓库中有 [申报书](docs/PROPOSAL.md)；填写报名表和 Mooncakes 账号认证需由参赛者完成。

版本修复见 [更新记录](CHANGELOG.md)，本次初审补充见 [复审说明](docs/REVIEW_RESPONSE.md)。
