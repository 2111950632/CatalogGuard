# 发布与参赛提交

参赛账号：`2111950632`。仓库：<https://github.com/2111950632/szs>。MoonBit 模块名：`2111950632/szs`，版本 `0.1.0`。

## 本地验收

在项目根目录执行 README 的检查、测试、构建与集成测试命令。运行中文示例和 broken 示例；前者应退出 0，后者应退出 1。`node scripts/count-source.mjs` 单独报告生产、测试源码行数，不能把外部语料、生成文件或主机入口合计为 MoonBit 实现。

先阅读 `git diff` 和提交记录，再按正常 GitHub 登录流程上传：

```sh
git push origin main
```

不要在仓库、截图或报名表中公开访问令牌。已有登录可直接使用；没有登录时由作者按 GitHub 的标准流程登录。项目不会读取账号凭据清单。

## Mooncakes

当前仓库中的运行入口可直接构建。只有注册表发布完成并核验之后，才可以把 Mooncakes 链接作为已完成成果填写。

```sh
moon package
moon publish --dry-run
moon login
moon publish
```

`moon login` 与 `moon publish` 使用参赛者自己的账号，需要在 [Mooncakes](https://mooncakes.io/) 完成认证。模块前缀 `2111950632` 必须与实际可用命名空间相符。若 Mooncakes 的账号前缀不同，发布前同步修改 moon.mod、cmd/main/moon.pkg、包接口引用与文档，再重跑验收；不要仅更改说明文字。

发布后在另一目录用新 consumer 引用模块，验证 parser、check 和 report 接口。保存注册表链接和实际版本。`moon package` 或 dry-run 成功不能冒充注册表发布成功。

## 比赛材料

查看 [比赛官网](https://moonbitlang.github.io/Hackathon2026/) 及最新完整章程。现有公开信息支持 MoonBit 生态工具方向与原创实现；最终资格及项目验收由主办方决定。

准备申报书、公开仓库、README、运行说明、测试证据、GitHub Actions 结果、来源/许可证说明、AI 辅助开发说明。原计划的“4000 行以上实现和至少 6 次开发提交”属于本项目目标，不能在未核验最新章程时写成统一比赛门槛。

演示顺序：中文 PO 通过 → broken PO 出错 → JSON 源位置 → POT 对比 → 复数求值边界 → 公开 API 与测试证据。录屏、报名表、Mooncakes 账号认证与最终提交由参赛者完成。
