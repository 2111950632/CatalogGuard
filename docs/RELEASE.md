# 发布与参赛提交

参赛账号：`2111950632`。仓库：<https://github.com/2111950632/CatalogGuard>。MoonBit 模块名继续为 `2111950632/szs`，当前源码版本 `0.2.2`。源码版本、已发布版本及对应 CI 须分别核验，不能用历史绿色运行证明新的修复已上传。

## 本地验收

使用 moonc >= 0.10.16，在项目根目录执行 `npm run verify`，覆盖版本门槛、检查、两后端测试、格式与接口检查、构建、CLI、生成输入及实际打包消费验证。运行中文示例和 broken 示例；前者应退出 0，后者应退出 1。`node scripts/count-source.mjs` 单独报告生产、测试源码行数，不能把外部语料、生成文件或主机入口合计为 MoonBit 实现。

先阅读 `git diff` 和提交记录，再按正常 GitHub 登录流程上传：

```sh
git push origin main
```

不要在仓库、截图或报名表中公开访问令牌。已有登录可直接使用；没有登录时由作者按 GitHub 的标准流程登录。项目不会读取账号凭据清单。

## Mooncakes

当前仓库中的运行入口可直接构建。只有注册表发布完成并核验之后，才可以把 Mooncakes 链接作为已完成成果填写。

```sh
moon package
moon login
moon publish --dry-run
moon publish
```

`moon login` 与 `moon publish` 使用参赛者自己的账号，需要在 [Mooncakes](https://mooncakes.io/) 完成认证。模块前缀 `2111950632` 必须与实际可用命名空间相符。若 Mooncakes 的账号前缀不同，发布前同步修改 moon.mod、cmd/main/moon.pkg、包接口引用与文档，再重跑验收；不要仅更改说明文字。

发布后在另一目录用新 consumer 引用模块，验证 parser、check 和 report 接口。保存注册表链接和实际版本。`moon package` 或 dry-run 成功不能冒充注册表发布成功。

发布前可运行 `python scripts/check-consumer.py` 验证打包文件的独立使用。此检查使用本地 workspace，不证明模块已经存在于注册表。发布后仍需用新目录从 Mooncakes 下载并验证。

## 比赛验收

查看 [比赛官网](https://moonbitlang.github.io/Hackathon2026/) 及最新完整章程。现有公开信息支持 MoonBit 生态工具方向与原创实现；最终资格及项目验收由主办方决定。

按选手于 2026-10-29 提供的验收指南，审核通过的选手验收前不需要再提交任何表格；保持开发并将对应内容上传 GitHub 即可。README、源码、示例、CI、测试、开源许可证和来源说明均在现有仓库内维护，Mooncakes 保持可用的已发布版本，不新增提交附件。

本轮若只调整工程检查和文档、未改动 MoonBit 库源码，不为了更新验收记录重复发布同版本。核验 GitHub 上对应提交的 CI，不能借用旧提交的绿色状态。参赛资格及最终验收结论仍由主办方确认。
