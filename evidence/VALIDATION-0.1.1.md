# 0.1.1 本地验收记录

日期：2026-10-13（北京时间）。Windows x86-64；moon 0.1.20261012、moonc v0.10.15+943464bfa、Node.js 24.19.0。

| 检查 | 实际结果 |
|---|---|
| 核心检查 | all target 类型检查通过，deny-warn 开启 |
| 核心测试 | JS 37/37、Wasm GC 37/37；为同一组 37 个用例 |
| CLI 集成测试 | 19/19，包括特殊文件名与构建版本选择回归 |
| 接口与格式 | moon info、moon fmt --check 通过 |
| release 构建与打包 | 通过 |
| 独立 consumer | 从真实 moon package ZIP 提取，在单独模块通过 JS/Wasm GC 调用；其中额外 consumer 用例 1 个，含依赖测试运行总数为 38，不能把 38 都称为新增测试 |
| 独立 polib 对比 | 4 文件、221 条消息一致 |
| 演示 | 四项预期结果均正确，故意出错案例返回 1 |
| GNU msgfmt | 本地 GNU gettext-tools 1.0 实际执行：中文正确案例通过，含 fuzzy 的错误案例和单独的 c-format 类型错误均拒绝；SZS 对这三个案例结果一致 |
| GitHub Actions | 8630048 已上传；首次运行核心/CLI 步骤通过，独立对照步骤失败。本地已修复 GNU 默认跳过 fuzzy 的对照问题，线上修复结果待新的实际运行核验 |
| Mooncakes | 命名空间确认为 2111950632；网页已登录，本地命令行尚未登录，注册表发布与在线 consumer 验证未完成 |

当前生产源码 21 文件、4485 总行、4095 非空非整行注释行；测试源码 10 文件、460 总行、394 非空非整行注释行。统计口径同 0.1.0，排除测试、生成接口、编译 JS 和外部数据；包含结构语法及显式 trait 导出，不是主办方认证的有效行数。细分见 source-count-0.1.1.json。

新增回归覆盖精确 Content-Type、重复/残缺 charset、数字 brace 身份、错误协议类型、大量重复位置参数、CLI end-of-options 和旧 dist 加载问题。性能变更以参数索引查找代替逐个扫描；没有将单次时间测量宣传为通用倍数提升。

完整运行流程为 `npm run verify`，结果记录在忽略目录 evidence/local/verification.json。独立工具所需依赖齐备时再运行 `npm run verify:independent`；未完成的步骤会失败，不静默跳过。

GNU 对照显式使用 `--use-fuzzy`，从而检查待审校译文。额外的 tests/fixtures/gnu-format-mismatch.po 没有 fuzzy 或缺失复数项，用 `%d` → `%s` 单独验证格式检查确实拒绝类型错误。这里只证明列出的案例结果一致，不宣称全部规则与 GNU 等价。可用 `--msgfmt PATH` 或 `SZS_MSGFMT` 指定可执行文件。

GNU 工具从 [MSYS2 gettext-tools 软件包](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-gettext-tools) 取得，下载校验 SHA256 为 `e2b017e98dfed1ff026b6d5fc26b228d05d8a0ffc00077727018109f694eee5b`；相关 runtime、libtextstyle、libiconv 包也与官方 SHA256 核验一致。仅在工作目录中用于独立验证，不随本项目运行包分发。

首次线上检查：[Check SZS #1](https://github.com/2111950632/szs/actions/runs/38392400671)。
