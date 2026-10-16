# 格式合同复审案例

这些 PO 来自 tests/format-cases.json，使用本项目自有示例头部。

先执行 `moon build --target js --release`。以下应返回 0：

```sh
node cli.mjs check examples/format-contracts/C-01.po --strict --json
node cli.mjs check examples/format-contracts/C-02.po --strict --json
node cli.mjs check examples/format-contracts/P-01.po --strict --json
node cli.mjs check examples/format-contracts/P-13.po --strict --json
node cli.mjs check examples/format-contracts/B-02.po --strict --json
node cli.mjs check examples/format-contracts/B-05.po --strict --json
node cli.mjs check examples/format-contracts/B-08.po --strict --json
```

以下应返回 1：C-16/P-15 的类型错配报告 F005，B-26 的字符串非法符号选项报告 F002。

```sh
node cli.mjs check examples/format-contracts/C-16.po --json
node cli.mjs check examples/format-contracts/P-15.po --json
node cli.mjs check examples/format-contracts/B-26.po --json
```

完整标准和兼容终点见 docs/FORMAT_CONTRACTS.md；完整矩阵包含 96 个案例，不止这 10 个展示文件。
