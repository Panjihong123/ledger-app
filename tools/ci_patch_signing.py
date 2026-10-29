#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CI 专用：给 flutter create 生成的 Android 工程打上【固定 release 签名】补丁。

背景：
  之前靠把仓库里的 keystore 覆盖到 ~/.android/debug.keystore 来“固定签名”，
  但 AGP 发现该文件不符合预期时会自己重新生成一个随机 debug 证书，
  导致每次构建的 APK 签名都不同 → 手机覆盖安装时报“签名冲突”。

做法：
  不再依赖 AGP 的默认 debug 证书路径，直接在 android/app/build.gradle(.kts)
  里声明 signingConfigs.release，并让 buildTypes.release 使用它。
  同时自动识别 Groovy DSL 与 Kotlin DSL 两种模板。

用法：
  python3 tools/ci_patch_signing.py <android/app 目录> <keystore 绝对路径>
"""

import pathlib
import re
import sys

STORE_PASS = "android"
KEY_ALIAS = "androiddebugkey"
KEY_PASS = "android"


def fail(msg: str) -> None:
    print(f"[ERROR] {msg}")
    sys.exit(1)


def patch_groovy(path: pathlib.Path, keystore: str) -> None:
    src = path.read_text(encoding="utf-8")

    if "signingConfigs.release" in src:
        print("[SKIP] build.gradle 已包含 signingConfigs.release")
        return

    release_cfg = f"""    signingConfigs {{
        release {{
            storeFile file("{keystore}")
            storePassword "{STORE_PASS}"
            keyAlias "{KEY_ALIAS}"
            keyPassword "{KEY_PASS}"
        }}
    }}
"""

    if "signingConfigs {" in src:
        # 已有 signingConfigs 块（少见），把 release 插进块首
        head, tail = src.split("signingConfigs {", 1)
        inner = f"""
        release {{
            storeFile file("{keystore}")
            storePassword "{STORE_PASS}"
            keyAlias "{KEY_ALIAS}"
            keyPassword "{KEY_PASS}"
        }}
"""
        src = head + "signingConfigs {" + inner + tail
        print("[OK] 在已有 signingConfigs 块中插入 release")
    else:
        anchor = "android {"
        idx = src.find(anchor)
        if idx < 0:
            fail("build.gradle 中找不到 `android {` 块，模板结构可能已变化")
        insert_at = idx + len(anchor)
        src = src[:insert_at] + "\n" + release_cfg + src[insert_at:]
        print("[OK] 在 android 块顶部插入 signingConfigs.release")

    # release 构建改用我们的签名
    # 兼容两种写法：`signingConfig signingConfigs.debug` 与 `signingConfig = signingConfigs.debug`
    pattern = re.compile(r"signingConfig\s*=?\s*signingConfigs\.debug\b")
    if not pattern.search(src):
        print("[DEBUG] 未能匹配签名赋值，模板中相关行如下：")
        for line in src.splitlines():
            if "signingConfig" in line:
                print("  > " + line.strip())
        fail("build.gradle 中找不到 debug 签名引用，无法切换为 release 签名")
    src = pattern.sub("signingConfig = signingConfigs.release", src)

    path.write_text(src, encoding="utf-8")
    print("[OK] buildTypes.release → signingConfigs.release")


def patch_kts(path: pathlib.Path, keystore: str) -> None:
    src = path.read_text(encoding="utf-8")

    if "create(\"release\")" in src or "getByName(\"release\")" in src:
        print("[SKIP] build.gradle.kts 已包含 release 签名配置")
        return

    release_cfg = f"""    signingConfigs {{
        create("release") {{
            storeFile = file("{keystore}")
            storePassword = "{STORE_PASS}"
            keyAlias = "{KEY_ALIAS}"
            keyPassword = "{KEY_PASS}"
        }}
    }}
"""

    anchor = "android {"
    idx = src.find(anchor)
    if idx < 0:
        fail("build.gradle.kts 中找不到 `android {` 块")
    insert_at = idx + len(anchor)
    src = src[:insert_at] + "\n" + release_cfg + src[insert_at:]

    pattern = re.compile(r'signingConfig\s*=?\s*signingConfigs\.getByName\("debug"\)')
    if not pattern.search(src):
        print("[DEBUG] 未能匹配签名赋值，模板中相关行如下：")
        for line in src.splitlines():
            if "signingConfig" in line:
                print("  > " + line.strip())
        fail("build.gradle.kts 中找不到 debug 签名引用，无法切换为 release")
    src = pattern.sub('signingConfig = signingConfigs.getByName("release")', src)

    path.write_text(src, encoding="utf-8")
    print("[OK] build.gradle.kts → signingConfigs.release")


def main() -> None:
    if len(sys.argv) < 3:
        fail("用法: ci_patch_signing.py <android/app 目录> <keystore 路径>")

    app_dir = pathlib.Path(sys.argv[1])
    keystore = pathlib.Path(sys.argv[2]).resolve()

    if not keystore.exists():
        fail(f"keystore 不存在: {keystore}")

    groovy = app_dir / "build.gradle"
    kts = app_dir / "build.gradle.kts"

    if groovy.exists():
        patch_groovy(groovy, keystore.as_posix())
    elif kts.exists():
        patch_kts(kts, keystore.as_posix())
    else:
        fail(f"{app_dir} 下既没有 build.gradle 也没有 build.gradle.kts")

    # 打印补丁结果，方便在 CI 日志里人工确认
    target = groovy if groovy.exists() else kts
    text = target.read_text(encoding="utf-8")
    for line in text.splitlines():
        if any(k in line for k in ("signingConfigs", "release", "storeFile",
                                   "storePassword", "keyAlias", "signingConfig")):
            print("  | " + line.strip())

    print("[DONE] 签名补丁已应用")


if __name__ == "__main__":
    main()
