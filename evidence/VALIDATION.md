# 本地验收记录

日期：2026-10-13，北京时间。平台：Windows x86-64。版本：SZS 0.1.0。

工具链：moon 0.1.20261012（748b63c）、moonc v0.10.15+943464bfa、Node.js 24.19.0、polib 1.2.0。

| 验证 | 结果 |
|---|---|
| `moon check --target all --deny-warn` | 通过，0 警告、0 错误 |
| JavaScript 单元/API 测试 | 33/33 通过 |
| Wasm GC 单元/API 测试 | 33/33 通过；与 JS 为同一组测试，不计成 66 个不同用例 |
| `moon info` 与 `moon fmt --check` | 通过，公开接口已生成 |
| JavaScript release 构建 | 通过 |
| CLI 集成 | 17/17 通过，包括退出码、stdin、JSON、模板、策略、输出保护和 32 MiB 限制 |
| polib 独立 parser 对比 | 4 文件、221 条消息一致，比较 id/context/plural/译文/obsolete/flags |
| `moon package` | 通过，已生成 Mooncakes 格式包 |
| `moon publish --dry-run` | 未通过账号前置条件：本次独立工具链尚未登录；不是已发布 |
| GNU msgfmt 对照 | 本机没有 GNU msgfmt；已编写 CI 必跑步骤，本地不宣称已实测 |
| GitHub Actions | 工作流已配置；远端运行结果需上传后核验 |

源码统计：21 个生产 `.mbt` 文件，共 4432 行，其中 4042 行非空且非整行注释；9 个测试文件，共 409 行，其中 350 行非空非整行注释。统计包含结构语法及必要的显式 trait 方法导出。生成 `.mbti`、测试、Node 入口、外部语料与编译 JS 未合并到生产 MoonBit 统计。详细结果见 `source-count.json`；不是主办方认证的有效行数。

真实 PO 来源为 moonbitlang/moonbit-docs 固定提交 `8d9f3ba206eb17f80ee1836e4c1139068d1351b5`：中文 gmachine-1（157 条）和日文 lambda/index（58 条），加上本项目两个 3 条示例，共 221 条。URL 与 SHA-256 在 tests/fixtures.json 中，可重跑验证。独立工具结果一致仅证明这些支持字段在这些样例上的一致性，不证明全部 gettext 兼容性。

CI 与发布状态以实际远端结果为准，不将配置文件、打包成功或本地测试冒充注册表发布及报名完成。
