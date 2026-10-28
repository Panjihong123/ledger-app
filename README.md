# 记账软件（Android）

个人记账 App：管理资产账户、记收支、看总资产、按月/按年统计占比与排行。纯本地存储（SQLite），无需登录/后端。

## 功能
- 资产账户：添加 / 删除 / 调整余额，首页显示总资产
- 账本：默认一个，可在「我的 → 账本管理」增删与切换
- 记账：选择账户 + 分类（支出/收入）+ 金额 + 日期 + 备注
- 分类管理：支出/收入类型可自由增删（水电费、房租、停车费、餐饮、水果…）
- 统计：按月 / 按年，支出/收入占比饼图 + 排行

## 本地编译（可选，需本机有 Flutter SDK）
```
flutter pub get
flutter build apk --release
```

## 云端编译（无需本机 Android SDK）
本仓库已配置 GitHub Actions（`.github/workflows/build.yml`）：
推送代码到 `main` 分支后，GitHub 自动用官方模板生成 Android 工程、拷贝 `lib/` 与 `pubspec.yaml`、执行 `flutter build apk --release`，并把 APK 作为 **Actions 产物** 上传。

下载方式：仓库 `Actions` 标签页 → 对应运行 → `ledger-app-release-apk` 产物 → 下载 `app-release.apk`，传到一加 13T 安装即可（debug keystore 签名，可直接安装）。

> 技术栈：Flutter + provider + sqflite + fl_chart。
