# CatalogGuard 初审补充说明

日期：2026-10-16。项目维护者：石子硕，GitHub ID：2111950632。

针对本次初审意见，我已收窄项目的净增范围、明确三类目标标准与完整兼容终点，并补充合法重排、边界语法及原样基线对照。之前材料没有清楚区分共性能力和净增检查，也未给出足够的标准分支证据，现以可运行案例补充。

## 与 moongettext 的共性及净增

PO/POT 解析与写出、上下文与复数、目录校验、统计和模板处理，与 moongettext 有重叠，本次不将这些共性功能申报为净增创新。moongettext 的 MO 编译和运行时查询也不是本项目要替代的能力。

本次净增范围集中于三个使用 MoonBit 实现的静态格式参数合同检查器：C printf、Python str 百分号格式、Python str.format 字段与内建规格。检查参数身份、用途集合、动态宽度精度依赖，以及源文和译文之间的缺失、多余和用途变化，并输出源位置、JSON 及失败退出码。

基线为 [moongettext 提交 7ef9576](https://github.com/YanFangNie/moongettext/tree/7ef95764ed37b47d4b8fabe1a6ed12c719850437)。实际调用其公开 validate_po：三类类型错配均不报告 error，重复键控制案例能报告 error。本项目对同样三类错配报告 F005。基线原代码未修改，脚本与证据公开；这说明范围差异，不是对基线质量的否定。

## 目标标准和兼容终点

| 检查器 | 固定目标 |
|---|---|
| c-format | C11 WG14 N1570 7.21.6.1 的 printf 静态合同，加 POSIX 编号参数；GNU 扩展逐项列明 |
| python-format | Python 3.12 str 百分号格式的可移植字典/顺序实参语法；实测 CPython 3.12.14 |
| python-brace-format | Python 3.12 str.format 字段及内建 Mini-Language；实测 CPython 3.12.14，Unicode 15.0 数字身份 |

完整兼容终点是 CGFC-1 所列静态合同规范全部产式、类型组合和资源边界的实现与正反案例覆盖，两后端一致，并完成同版本发布后消费验收。它不包括 GNU gettext 全功能、任意 Python 对象执行、自定义格式器或 f-string 表达式。

当前 0.1.2 已完成本次 96 个分类案例及发现问题的修复，不将这 96 个案例视为所有字符串的穷尽证明，也不声称全规范兼容已完成。剩余工作及终点验收门槛在 [FORMAT_CONTRACTS.md](FORMAT_CONTRACTS.md) 单独列明；未完成计划不计作当前成果。

## 合法重排与边界证据

| 类型 | 源文 | 译文 | 结果 |
|---|---|---|---|
| C 编号重排 | `%s has %d files` | `%2$d files for %1$s` | 通过 |
| C 动态宽度精度 | `%*.*f %s` | `%4$s %3$*1$.*2$f` | 通过 |
| Python 字典重排 | `%(name)s %(count)d` | `%(count)d %(name)s` | 通过 |
| 同一键多种用途 | `%(x)s %(x)r` | `%(x)r %(x)s` | 通过 |
| brace 显式编号 | `{} {:d}` | `{1:d} {0}` | 通过 |
| brace 嵌套依赖 | `{v:{w}.{p}f} {name!s}` | `{name!s} {v:{w}.{p}f}` | 通过 |
| 自动路径 | `{[name]}` | `{0[name]}` | 通过 |
| 混用 C 编号 | `%s %d` | `%1$s %d` | F002 |
| 字典动态星号 | `%(x)s` | `%(x)*s` | F002 |
| 过深嵌套 | `{0:{1}}` | `{0:{1:{2}}}` | F002 |
| 字符串非法选项 | `{x:s}` | `{x:+s}` | F002 |
| 转换后非法规格 | `{x!s}` | `{x!s:d}` | F002 |

本次修复包括：Python 空字典键、同参数多种合法用途被误拒，brace 自动路径和 Unicode 数字身份，以及过深嵌套、内建非法选项、C11 未定义组合漏检。

## 实际验证与复现

- 96 个新格式案例：34 个 C、24 个 Python 百分号、38 个 brace。加原有 37 个用例，共 133 个核心用例，在 JS/Wasm GC 各通过；不是 266 个不同用例。
- 19 个 CLI 用例通过，独立提取的真实打包 consumer 在两后端通过。consumer 的 134 项总数包含库原有 133 项，仅新增 1 个调用探针。
- 55 项 CPython 3.12.14 运行探针通过；73 项 GNU 1.0 固定预期通过，另 23 项只记录观察，不充作通过。GNU 与目标标准的差异逐项保留，不用修改标准预期来迎合参考工具。
- 原样 moongettext 基线 4 个探针通过：3 个范围差异及 1 个重复键控制。polib 对照仍为 4 文件、221 条消息。

```sh
moon check --target all --deny-warn
moon test --target js --deny-warn
moon test --target wasm-gc --deny-warn
node --test tests/integration.mjs
python tests/format_conformance.py --msgfmt PATH
python scripts/compare-moongettext.py
```

Python 独立探针固定使用 3.12。GNU 1.0 用于锁定交叉预期，其他 GNU 版本只作版本化观察。CI 同时保留格式案例及基线结果。公开证据为 [格式矩阵结果](../evidence/format-conformance-0.1.2.json)、[基线结果](../evidence/moongettext-baseline-0.1.2.json) 和源码中的测试矩阵。

## 版本与提交信息

仓库：https://github.com/2111950632/CatalogGuard 。本次源码版本为 0.1.2，模块名继续使用 2111950632/szs。历史 Mooncakes 0.1.1 的验收只证明旧版本，不作为本次新增能力的发布证明。最新线上检查、0.1.2 发布及独立下载结果另附最终交付记录，未确认前不写成成功。

项目采用 Apache-2.0。AI 辅助方案设计、实现、测试和文档，提交者对最终成果及维护负责。希望组委会依据补充的净增范围、标准与可复现实例重新审核；本材料不代表已通过复审。
