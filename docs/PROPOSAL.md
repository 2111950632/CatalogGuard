# szs 项目申报书

## 基本信息

项目名称：szs：MoonBit PO/POT 翻译目录检查工具  
参赛者：szs  
联系方式：2111950632@qq.com  
GitHub 仓库链接：[https://github.com/2111950632/szs](https://github.com/2111950632/szs)  
项目方向：MoonBit 开发者工具 / 多语言文档与软件本地化基础库  
是否为移植项目：否，原创项目，参考公开格式规范与工具行为。

## 项目简介

本项目以 MoonBit 实现 PO/POT 翻译目录检查库及命令行工具，面向多语言文档、开源软件和本地化团队，在翻译合入前发现格式参数丢失、类型改变、复数译文缺项及目录结构错误，并定位文件、条目和行列。项目从仅有 README 的个人仓库继续开发，目前已完成 0.1.0 本地版本：解析、校验、报告、CLI、测试与示例。技术路线采用保留源位置的数据模型和 MoonBit 检查核心，结合文件读取入口形成可复现流程，聚焦翻译文件的开发期质量检查。

## 核心功能范围

- 解析 UTF-8 PO/POT，支持续行、转义、注释、flags、上下文及单数／复数条目，保留诊断位置。
- 校验重复条目、头部信息及复数索引；按配置报告空译文与 fuzzy 状态；对照 POT 模板定位缺失与过时译文。
- 按 c-format／python-format／python-brace-format 标记核对支持范围内的 printf、Python percent 参数及 brace 字段，说明未支持语法。
- 解析复数规则公式，在明确输入范围与资源限制内检查除零、溢出及结果越界，说明未覆盖的情况。
- 提供 MoonBit 库 API、实际文件 CLI、文本／JSON 报告及明确退出码，便于接入 CI。
- JavaScript 与 Wasm GC 上各通过同一组 33 个 MoonBit 测试，17 个 CLI 测试通过；4 个文件、221 条消息与 polib 独立对照一致。GNU msgfmt 对照步骤已配置到 CI，本地尚未运行。
- 已实现 4042 行非空非整行注释的生产 MoonBit 源码，测试及生成文件分开统计；保留不少于 6 次实际功能开发提交。行数统计方法公开，不冒充主办方认证。
- README、示例、CI、来源与发布说明已准备；Mooncakes 格式包已生成，注册表发布仍需本人账号认证。首期范围不含自动翻译、MO 编译与任意编码识别。

## 移植或参考说明

参考 [GNU gettext 手册](https://www.gnu.org/software/gettext/manual/gettext.html) 的格式概念与既有工具行为，原创编写 MoonBit 实现，不移植 GNU gettext 源码，不宣称全球首创。项目采用 Apache-2.0，AI 辅助开发由作者负责验证；官方文档 PO 仅用于测试，固定来源与摘要、不分发、不计入代码。依赖与来源见仓库 THIRD_PARTY.md。
