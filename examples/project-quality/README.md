# 两分钟验收：HTML/XML 与跨文件质量检查

先在仓库根目录执行 `moon build --target js --release`。

```sh
node cli.mjs examples/project-quality/valid --recursive --markup html --consistency --strict --json
node cli.mjs examples/project-quality/broken --recursive --markup html --consistency --strict --json
node cli.mjs examples/project-quality/xml-good.po --markup xml --strict --json
node cli.mjs examples/project-quality/xml-broken.po --markup xml --strict --json
```

四个命令退出码依次为 **0、1、0、1**。正常目录包含相同中文译文、可重排的同级标签与属性、可翻译 title，以及隔离比较的法文文件。错误目录包含 Save 的译法冲突、被改写的 href 和交叉闭合标签；诊断含 M002、M003、X002，并在 project_findings.related 中给出对照文件和位置。XML 错例包含受保护 id 改写和未声明实体。

也可使用 `node cli.mjs examples/project-quality/valid --recursive --config examples/project-quality/ci.json --json`，预期退出 0。配置与 CLI 选项都进入 MoonBit 核心验证；CLI 仅负责目录遍历和输入输出。

这组材料由本项目编写，不包含第三方语料。CGM-1 支持边界和与 Translate Toolkit 3.20.0 的实际差异见 ../../docs/PROJECT_QUALITY.md。
