# nix-config

`thinkpad-t14s` 的 NixOS 和 Home Manager 配置，使用 [Dendritic](https://github.com/mightyiam/dendritic) 模式：配置文件都是 flake-parts 顶层模块，再通过 `flake.modules` 定义和组合 NixOS、Home Manager 模块。

## 模块结构

| 位置 | 职责 |
| --- | --- |
| `flake.nix` | 声明 inputs，使用 flake-parts 和 import-tree 加载配置 |
| `flake-modules/core.nix` | 注册 `flake.modules`，声明平台和 formatter |
| `configuration.nix` | 将主机模块实例化为 `nixosConfigurations.thinkpad-t14s` |
| `hosts/thinkpad-t14s/default.nix` | 定义主机模块，组合基础配置、profiles 和硬件配置 |
| `modules/` | 向 `flake.modules.nixos.base` 合并基础配置和可选功能声明；字体、打印及 Nix 设置分别位于 `desktop/fonts.nix`、`services/printing.nix`、`system/nix.nix` |
| `profiles/` | 定义 `nixos.desktop`、`gaming`、`apps`、`dev`、`services` 模块，选择启用的功能 |
| `home-manager/` | 向 `flake.modules.homeManager.desktop` 合并桌面用户配置 |
| `flake-modules/home-manager.nix` | 将 Home Manager 模块接入 `local.user` 指定的 NixOS 用户 |

同一个模块可以在多个文件里定义，内容由模块系统合并。一个功能也可以在同一个文件里同时定义 NixOS 和 Home Manager 配置，例如 `modules/apps/niri/default.nix`。

本次迁移保留 `local.*.enable` 接口和现有 profiles，以便单独验证结构变化。Spotify 作为 `flake.modules.homeManager.spotify` 导出，当前主机仍未导入它。

## 自动导入约定

import-tree 递归导入仓库中的 `.nix` 文件，因此新增配置文件无需修改目录级 `imports` 清单。被自动导入的文件必须是 flake-parts 顶层模块，例如：

```nix
{
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.hello];
  };
}
```

`inputs` 在外层获取，NixOS / Home Manager 的 `config`、`pkgs`、`lib` 在对应的内层模块获取，无需 `specialArgs` 或 `extraSpecialArgs`。新增独立命名模块时，还需要在主机或 profile 中导入 `config.flake.modules.nixos.<名称>` 才会启用它。

纯函数和 `callPackage` helper 使用 `_` 前缀，例如 `_package.nix`；import-tree 默认忽略路径中以 `_` 开头的文件或目录。以下文件也被显式排除：

- `flake.nix`：flake 入口。
- `hosts/thinkpad-t14s/hardware-configuration.nix`：保留硬件生成文件，由主机显式导入。
- `hosts/thinkpad-t14s/disko.nix`：保留普通 Disko 模块，兼容安装命令，由主机显式导入。

新增文件需要先执行 `git add -N <路径>` 或 `git add <路径>`，Nix 才能在 Git flake 中看到它。

## 独立软件包

Brave Origin Beta、Paseo Desktop、OxideTerm、Neiro、Gamescope 补丁版和 Nautilus 插件环境由个人 flake [Invisibox/nix-packages](https://github.com/Invisibox/nix-packages) 提供，当前配置通过 GitHub input 引用。
上游 Actions 完成版本更新并发布缓存后，在本仓库刷新锁定：

```sh
nix flake update nix-packages
```

保留该 input 自己的 nixpkgs 锁定，直接使用其 `packages` 输出，以便命中个人 flake CI 生成的二进制缓存。
`modules/system/nix.nix` 已配置 [invisibox Cachix](https://invisibox.cachix.org) 的地址和签名公钥，重建并切换系统后生效。
应用更新脚本也已迁至新仓库；本仓库的 `scripts/update-all.sh` 继续更新 Bottles、Rime 和 Zsh 插件。
本地开发仓库位于 `/home/zh/Documents/nix-packages`。如需测试未发布的修改，可在构建命令中加入 `--override-input nix-packages path:/home/zh/Documents/nix-packages --no-write-lock-file`。

## 验证与构建

```sh
nix fmt -- --check .
nix flake check --no-build
nix eval --raw '.#nixosConfigurations.thinkpad-t14s.config.system.build.toplevel.drvPath'
nix build '.#nixosConfigurations.thinkpad-t14s.config.system.build.toplevel'
```

`nix flake check` 可能提示 `unknown flake output 'modules'`：这是 flake-parts 提供的扩展输出；NixOS 实例仍会被正常检查。

硬件安装步骤见 [INSTALL.md](hosts/thinkpad-t14s/INSTALL.md)。Niri 配置和 dae 数据仍使用原有的 `/home/zh/Documents/nix-config` 工作目录路径。
