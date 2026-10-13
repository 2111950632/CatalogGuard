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
| GNU msgfmt | 下载二进制受网络/TLS 环境限制，本机仍未执行；CI 必跑步骤已配置 |
| GitHub Actions | 上传后核验实际运行结果，不以配置完成冒充通过 |
| Mooncakes | 本地包已生成；账号认证、注册表发布与在线 consumer 验证未完成 |

当前生产源码 21 文件、4485 总行、4095 非空非整行注释行；测试源码 10 文件、460 总行、394 非空非整行注释行。统计口径同 0.1.0，排除测试、生成接口、编译 JS 和外部数据；包含结构语法及显式 trait 导出，不是主办方认证的有效行数。细分见 source-count-0.1.1.json。

新增回归覆盖精确 Content-Type、重复/残缺 charset、数字 brace 身份、错误协议类型、大量重复位置参数、CLI end-of-options 和旧 dist 加载问题。性能变更以参数索引查找代替逐个扫描；没有将单次时间测量宣传为通用倍数提升。

完整运行流程为 `npm run verify`，结果记录在忽略目录 evidence/local/verification.json。独立工具所需依赖齐备时再运行 `npm run verify:independent`；未完成的步骤会失败，不静默跳过。
