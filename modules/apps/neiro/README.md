# Neiro 声明式配置

本仓库提供自定义的 `local.services.neiro` 模块，通过 Home Manager 管理主用户的
systemd 用户服务。它不是 nixpkgs 内置选项。

## 当前设备

`hosts/thinkpad-t14s/default.nix` 已启用 Neiro，并指定内置扬声器的 PipeWire 节点。
`hosts/thinkpad-t14s/_audio-tuning.nix` 从联想官方 `n45a127w.exe` 驱动包提取：

```text
DEV_0257_SUBSYS_17AA2329_PCI_SUBSYS_232917AA.xml
```

它匹配此机的 Realtek ALC257（`DEV_0257`）、HDA 子系统 `17AA2329` 和 PCI
子系统 `232917AA`。调音文件包含 normal 模式、双声道，以及 music、dynamic、movie
等配置；默认从厂商的 music 配置启动。其他机器需要重新核对硬件 ID 和厂商调音文件。

驱动来源可在联想的 [21LS Windows 11 驱动目录](https://download.lenovo.com/catalog/21ls_Win11.xml)
及 [音频包元数据](https://download.lenovo.com/pccbbs/mobiles/n45a127w_2_.xml) 中核对。
Nix 固定驱动 URL 和 SHA-256，只解包所需 XML，不运行 Windows 安装程序。
厂商 XML 不放进 Git，也不应上传到公共二进制缓存。

## 配置归属

- 个人 flake `nix-packages` 的 `packages/neiro/package.nix` 固定源码提交和 Cargo 依赖哈希，
  并包装 PipeWire、WirePlumber、ffmpeg 等运行依赖；本模块默认引用其 `neiro` 输出。
- 主机配置声明 `tuningFile` 和 `settings.speaker_sink`，避免把扬声器调音用于其他设备。
- 用户服务在 PipeWire、WirePlumber 之后启动，运行 `neiro daemon --tuning …`。
- `~/.config/neiro/state.toml` 保持可写。每次服务启动时，模块覆盖 `settings` 中声明的
  顶层字段，保留其余字段，包括 TUI 保存的个人 EQ 和各 profile 的修改。
  `tuning_path` 自动由 `tuningFile` 写入，使 `neiro dump-tuning` 等离线命令也使用同一文件。

例如，在主机配置中加入以下设置，会在每次服务启动时恢复它们：

```nix
local.services.neiro.settings = {
  profile = "music";
  hw_volume = 0.8;
};
```

`hw_volume` 是硬件扬声器音量上限，取值 0 到 1；未声明时采用 Neiro 的默认行为。
若声明 `personal` 或 `overrides` 表，该表会整体覆盖运行时保存的对应表。
删除声明的字段只会停止覆盖，不会从已有 `state.toml` 中删除它。
因此不直接用只读的 `xdg.configFile` 链接 `state.toml`。

## 应用与使用

首次应用前，将新增文件纳入 Git；Nix 的 Git flake 不包含未跟踪文件：

```sh
git add modules/apps/neiro hosts/thinkpad-t14s/_audio-tuning.nix
sudo nixos-rebuild switch --flake '.#thinkpad-t14s'
systemctl --user start neiro.service
neiro status
neiro
```

不用运行 `neiro install` 或 `neiro import`。前者会另写用户服务，后者的导入路径
会被这里显式指定的 `--tuning` 覆盖。

TUI 中空格对比处理前后，`s` 保存设置，`q` 关闭界面并保留后台处理。
也可以用 `neiro toggle`、`neiro profile music` 控制。
服务会随 PipeWire 启动；修改声明式设置并重建后，可用
`systemctl --user restart neiro.service` 确保重新读取配置。

```sh
journalctl --user -u neiro.service -b
systemctl --user stop neiro.service
```

停止服务时 Neiro 会恢复原输出和音量。要长期停用，设置
`local.services.neiro.enable = false;` 并重建。

保留厂商的 regulator 和 limiter 设置。Neiro 对部分 Dolby 参数的解释来自逆向分析；
文件解析成功不能代替实机试听，首次使用从低音量开始。

## 更新

在个人软件包仓库运行：

```sh
cd /home/zh/Documents/nix-packages
./scripts/update-neiro.sh
```

脚本跟踪上游默认分支的最新提交，从 `Cargo.toml` 读取版本，自动更新源码提交、
源码哈希和 `cargoHash`，并使用个人 flake 锁定的 nixpkgs 构建、运行上游测试。
同版本号下的新提交也会更新；已是最新提交则直接退出。
只有构建成功才会替换包定义，失败时保留原文件。
个人 flake 的 `./scripts/update-all.sh` 也会调用此脚本。更新后在 `nix-config` 中运行
`nix flake update nix-packages`，再重建系统。

升级联想驱动时，更新主机的 `_audio-tuning.nix` 中的 URL、SHA-256 及包内 XML 路径，
并重新确认硬件 ID；不能只换成同声卡型号的任意调音。
