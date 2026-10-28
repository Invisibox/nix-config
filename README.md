# nix-config

`thinkpad-t14s` 的 NixOS 和 Home Manager 配置，使用 [Dendritic](https://github.com/mightyiam/dendritic) 模式：配置文件都是 flake-parts 顶层模块，再通过 `flake.modules` 定义和组合 NixOS、Home Manager 模块。

## 模块结构

| 位置 | 职责 |
| --- | --- |
| `flake.nix` | 声明 inputs、平台和 formatter，注册 `flake.modules`，使用 flake-parts 和 import-tree 加载配置 |
| `configuration.nix` | 将主机模块实例化为 `nixosConfigurations.thinkpad-t14s` |
| `hosts/thinkpad-t14s/default.nix` | 定义主机模块，组合基础配置、profiles 和硬件配置 |
| `modules/apps/` | 应用功能的 NixOS 和 Home Manager 配置，以及对应资源；`packages.nix` 统一选择应用、声明软件包，并接入 `homeManager.apps` |
| `modules/desktop/` | Niri、登录界面、字体、输入法、主题、Noctalia、桌面工具和 MIME 配置；通用配置合并到 `nixos.desktop` / `homeManager.desktop`，Niri 的用户配置随会话模块一起导入 |
| `modules/shell/` | Zsh、Powerlevel10k、CLI 和归档工具；系统工具合并到 `nixos.base`，用户配置合并到 `homeManager.shell` |
| `modules/dev/` | Git、Zed、编辑器、编译工具和 AI 编程助手，合并到 `nixos.dev` / `homeManager.dev` |
| `modules/local/` | 本地用户选项、Home Manager 接入，以及 `homeManager.base` 的用户目录和兼容版本设置 |
| `modules/profiles/` | 定义 `nixos.desktop`、`gaming`、`dev`、`services` 组合；desktop、dev 同时接入各自的 Home Manager 配置组 |
| `modules/system/` | Nix 设置、nix-ld 运行环境、虚拟化和容器配置 |
| `modules/services/` | dae、Neiro、打印等后台服务；打印由 desktop profile 选择 |
| `modules/security/` | 指纹认证等安全功能 |
| `modules/local/home-manager.nix` | 将 Home Manager 的 base 和 shell 配置组接入 `local.user` 指定的 NixOS 用户 |

同一个模块可以在多个文件里定义，内容由模块系统合并。一个功能也可以在同一个文件里同时定义 NixOS 和 Home Manager 配置，例如 `modules/desktop/niri/default.nix`。

配置按功能放在 `modules/` 中，Home Manager 模块也按功能归入其中。各功能文件可以合并到同一个配置组；需要独立选择的功能导出独立命名模块，由 profiles 或主机通过 `imports` 选择，导入即启用。`base` 只组合用户、Home Manager、Shell 和 Nix 等通用基础；字体与输入法随 desktop 启用，打印由 desktop 显式导入。

单文件功能直接使用 `kitty.nix`、`fingerprint.nix` 等文件；有多个实现文件或配套资源的功能使用目录，例如 Steam、Niri、Fcitx5、Zsh、dae 和 Neiro。目录位置用于组织功能，模块的选择关系仍由导出名称和 `imports` 决定。profiles 主要负责选择功能与设置参数，软件包清单按用途放在 apps、dev、shell、desktop 中。

应用选择与软件包清单集中在 `modules/apps/packages.nix`，由主机导入 `nixos.apps` 启用。例如，在该文件中组合应用：

```nix
{config, ...}: {
  flake.modules.nixos.apps.imports = [
    config.flake.modules.nixos.localsend
    config.flake.modules.nixos.onlyoffice
  ];
}
```

停用功能时移除对应的导入，同时删除该功能的 `local.*` 参数。包、字体、调音等参数仍通过 `local.*` 配置；Steam 的版本选择使用 `local.gaming.steam.beta`，指纹 TOD 驱动使用 `local.security.fingerprint.todDriver`。NixOS 和 Home Manager 自带的 `enable` 选项由各功能模块设置。

## 自动导入约定

import-tree 递归导入仓库中的 `.nix` 文件，因此新增配置文件无需修改目录级 `imports` 清单。被自动导入的文件必须是 flake-parts 顶层模块，例如：

```nix
{
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.hello];
  };
}
```

`inputs` 在外层获取，NixOS / Home Manager 的 `config`、`pkgs`、`lib` 在对应的内层模块获取，无需 `specialArgs` 或 `extraSpecialArgs`。新增独立命名模块时，还需要在主机或 profile 中导入它才会启用；向现有配置组添加内容则会随该配置组一起启用。

纯函数和 `callPackage` helper 使用 `_` 前缀，例如 `_package.nix`；import-tree 默认忽略路径中以 `_` 开头的文件或目录。以下文件也被显式排除：

- `flake.nix`：flake 入口。
- `hosts/thinkpad-t14s/hardware-configuration.nix`：保留硬件生成文件，由主机显式导入。
- `hosts/thinkpad-t14s/disko.nix`：保留普通 Disko 模块，兼容安装命令，由主机显式导入。

新增文件需要先执行 `git add -N <路径>` 或 `git add <路径>`，Nix 才能在 Git flake 中看到它。

## 独立软件包

Brave Origin Beta、Paseo Desktop、OxideTerm、Neiro、Gamescope 补丁版、Nautilus 插件环境，以及 `wechat-jailed`、`qq-jailed`、`baidunetdisk-jailed` 由个人 flake [Invisibox/nix-packages](https://github.com/Invisibox/nix-packages) 提供。当前配置通过 GitHub input 引用。
上游 Actions 完成构建并发布缓存后，在本仓库刷新锁定：

```sh
nix flake update nix-packages
```

保留该 input 自己的 nixpkgs 锁定，直接使用其 `packages` 输出，以便命中个人 flake CI 生成的二进制缓存。
`modules/system/nix.nix` 已配置 [invisibox Cachix](https://invisibox.cachix.org) 的地址和签名公钥，重建并切换系统后生效。
应用更新脚本也已迁至新仓库；本仓库的 `scripts/update-all.sh` 继续更新 Bottles、Rime 和 Zsh 插件。

微信、QQ 和百度网盘替代原有 Flatpak 声明；腾讯会议和 Open WebUI 的声明已移除。沙箱仅以只读方式挂载 `~/Documents`，应用自己的数据和下载写入 `~/.local/share/jail.nix/home/<包名>/`。允许联网、桌面通知、摄像头、通过 PulseAudio / PipeWire 播放音频和使用麦克风、GPU、剪贴板、读取和跟随系统深浅色模式，并通过受限桌面门户在系统默认浏览器中打开 HTTP(S) 网页；微信开放 Qt 旧式托盘注册权限。旧 Flatpak 安装和数据不会自动卸载或迁移；沙箱说明及权限测试见 `nix-packages/README.md`。

Proton CachyOS 的 `x86_64_v3` 版本直接引用 [Chaotic Nyx](https://github.com/chaotic-cx/nyx) 的 `packages` 输出，供 Heroic 和 Bottles 使用。保留 Nyx 自己的 nixpkgs 锁定，通过 `nix flake update chaotic` 更新；对应二进制缓存及公钥已加入 `modules/system/nix.nix`，重建并切换系统后生效。

## 验证与构建

```sh
nix fmt -- --check .
nix flake check --no-build
nix eval --raw '.#nixosConfigurations.thinkpad-t14s.config.system.build.toplevel.drvPath'
nix build '.#nixosConfigurations.thinkpad-t14s.config.system.build.toplevel'
```

`nix flake check` 可能提示 `unknown flake output 'modules'`：这是 flake-parts 提供的扩展输出；NixOS 实例仍会被正常检查。

硬件安装步骤见 [INSTALL.md](hosts/thinkpad-t14s/INSTALL.md)。Niri 配置链接到工作目录中的 `modules/desktop/niri/config.kdl`；旧位置 `home-manager/niri/config.kdl` 保留指向新文件的兼容软链接，供仍引用旧路径的系统代际使用。dae 配置位于工作目录中的 `modules/services/dae/`，`modules/apps/dae` 保留为指向新目录的兼容链接，供尚未切换的服务使用；import-tree 不递归导入目录软链接。
