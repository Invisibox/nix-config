# nix-config 临时优化 TODO

目标：先把自定义 feature module 和 option 命名空间整理稳定，再逐步拆分 profile、host、Home Manager 和 package 构建逻辑。暂不直接迁移到 Dendrix/Dendritic。

工作分支：`refactor/feature-modules`

## 阶段 0：迁移前基线

- [x] 跑一次当前配置检查，确认现状可构建。
  - 建议命令：`nix flake check`
  - 如 `flake check` 太重，至少跑：`nixos-rebuild dry-build --flake .#ASUS`
- [x] 记录当前启用入口。
  - 重点文件：`configuration.nix`
  - 重点段落：自定义 app/gaming/dev/service enable 项。
- [x] 确认统一命名空间。
  - 推荐使用：`local.*`
  - 暂定结构：
    - `local.user.*`
    - `local.apps.*`
    - `local.desktop.*`
    - `local.gaming.*`
    - `local.services.*`
    - `local.dev.*`
    - `local.virtualisation.*`

阶段 0 记录：

- 当前基线检查：`nix flake check` 通过。
- 当前 dry-build：`nixos-rebuild dry-build --flake '.#ASUS'` 通过。
- 当前检查警告：`programs.steam.config.closeSteam` 已改名为 `programs.steam.config.onSteamRunning`，后续整理 Steam 模块时处理。
- 当前自定义启用入口在 `configuration.nix`：
  - `nix-ld.enable = true;`
  - `steam.enable = true;`
  - `gamescope.enable = true;`
  - `heroic.enable = true;`
  - `brave-origin.enable = true;`
  - `lobehub.enable = true;`
  - `cc-switch.enable = true;`
  - `localsend.enable = true;`
  - `moonlight.enable = true;`
  - `netcatty.enable = true;`
  - `oxide-term.enable = true;`
  - `im.enable = true;`
  - `bottles.enable = true;`
  - `virtualization.enable = true;`
  - `waydroid.enable = true;`
  - `obs.enable = true;`
  - `daed.enable = true;`
  - `texlive.enable = true;`
  - `wps.enable = true;`
  - `wemeet.enable = true;`

验收标准：未改行为，只明确命名空间和当前构建状态。

## 阶段 1：建立 `local.*` 基础命名空间

- [x] 新增一个基础模块，例如 `modules/local/default.nix` 或 `modules/core/local.nix`。
- [x] 定义共享用户信息：
  - `local.user.name = "zh";`
  - `local.user.home = "/home/zh";`
- [x] 在 `modules/default.nix` 中导入该基础模块。
- [x] 后续模块逐步从 `config.local.user.name` 读取用户名，减少对 `specialArgs.username` 的依赖。

阶段 1 记录：

- 新增基础模块：`modules/local/default.nix`。
- 新增 option：`local.user.name`，默认值为 `"zh"`。
- 新增 option：`local.user.home`，默认跟随 `"/home/${config.local.user.name}"`。
- 已在 `modules/default.nix` 中导入 `./local`。
- 本阶段不批量替换现有模块里的 `username` specialArg，后续按 feature 迁移。
- 阶段验证：
  - `nix fmt .` 通过。
  - `nix flake check` 通过。
  - `nixos-rebuild dry-build --flake '.#ASUS'` 通过。
  - 仍有既有 Steam `closeSteam` 改名警告，按用户要求暂不处理。

验收标准：新增 option 后配置仍可 eval；暂不批量改所有模块。

## 阶段 2：迁移顶层自定义 option 路径

- [x] 将 app 类 option 从顶层迁移到 `local.apps.*`：
  - `brave-origin.enable` -> `local.apps.brave-origin.enable`
  - `cc-switch.enable` -> `local.apps.cc-switch.enable`
  - `lobehub.enable` -> `local.apps.lobehub.enable`
  - `localsend.enable` -> `local.apps.localsend.enable`
  - `moonlight.enable` -> `local.apps.moonlight.enable`
  - `netcatty.enable` -> `local.apps.netcatty.enable`
  - `oxide-term.enable` -> `local.apps.oxide-term.enable`
  - `bottles.enable` -> `local.apps.bottles.enable`
  - `im.enable` -> `local.apps.im.enable`
  - `texlive.enable` -> `local.apps.texlive.enable`
  - `wps.enable` -> `local.apps.wps.enable`
  - `wemeet.enable` -> `local.apps.wemeet.enable`
- [x] 将 gaming 类 option 迁移到 `local.gaming.*`：
  - `steam.enable` -> `local.gaming.steam.enable`
  - `gamescope.enable` -> `local.gaming.gamescope.enable`
  - `heroic.enable` -> `local.gaming.heroic.enable`
- [x] 将 service/dev/system 类 option 迁移：
  - `daed.enable` -> `local.services.daed.enable`
  - `nix-ld.enable` -> `local.dev.nix-ld.enable`
  - `virtualization.enable` -> `local.virtualisation.enable`
  - `waydroid.enable` -> `local.apps.waydroid.enable`
  - `obs.enable` -> `local.apps.obs.enable`
- [x] 每次迁移少量模块，避免一次性大改。

阶段 2 记录：

- 已迁移 `configuration.nix` 中的自定义 feature enable 入口到 `local.*`。
- 已迁移各 feature module 内部的 `cfg = config.*` 和 `options.*` 到对应 `local.*` 路径。
- `steam` 对 `gamescope` 的依赖已从 `config.gamescope.enable` 改为 `config.local.gaming.gamescope.enable`。
- `wemeet` 内部默认值回写已从 `wemeet.*` 改为 `local.apps.wemeet.*`。
- `daed` assertion 提示文案已同步为 `local.services.daed.*`。
- 阶段验证：
  - `nix fmt .` 通过。
  - `nix flake check` 通过。
  - `nixos-rebuild dry-build --flake '.#ASUS'` 通过。
  - 仍有既有 Steam `closeSteam` 改名警告，按用户要求暂不处理。

验收标准：`configuration.nix` 中不再出现自定义顶层 enable；上游 NixOS option 保持原名。

## 阶段 3：给无开关模块补 `enable`

- [x] 给 `modules/apps/niri/default.nix` 增加 `local.desktop.niri.enable`。
- [x] 给 `modules/apps/dms-greeter/default.nix` 增加 `local.desktop.dms-greeter.enable`。
- [x] 检查 import 后直接生效的其他模块。
- [x] 将当前行为显式写入配置入口：
  - `local.desktop.niri.enable = true;`
  - `local.desktop.dms-greeter.enable = true;`

阶段 3 记录：

- `modules/apps/niri/default.nix` 现在只在 `local.desktop.niri.enable = true` 时生效。
- `modules/apps/dms-greeter/default.nix` 现在只在 `local.desktop.dms-greeter.enable = true` 时配置 greeter。
- DMS greeter 的 upstream module import 保留在顶层，因为它提供 `programs.dank-material-shell.greeter` option 定义。
- `configuration.nix` 已显式启用：
  - `local.desktop.niri.enable = true;`
  - `local.desktop.dms-greeter.enable = true;`
- 阶段验证：
  - `nix fmt .` 通过。
  - `nix flake check` 通过。
  - `nixos-rebuild dry-build --flake '.#ASUS'` 通过。
  - 仍有既有 Steam `closeSteam` 改名警告，按用户要求暂不处理。

验收标准：import 模块本身不再改变系统；只有 enable 后才生效。

## 阶段 4：整理启用入口为 profiles

- [ ] 新建 `profiles/desktop.nix`：
  - Niri
  - DMS greeter
  - 字体/主题/portal/桌面基础项，视情况迁移
- [ ] 新建 `profiles/gaming.nix`：
  - Steam
  - Gamescope
  - Heroic
  - gamepad 相关硬件项
- [ ] 新建 `profiles/apps.nix`：
  - Brave Origin
  - LobeHub
  - LocalSend
  - Moonlight
  - Netcatty
  - OxideTerm
  - IM/WPS/WeMeet/TeX Live 等
- [ ] 新建 `profiles/dev.nix`：
  - nix-ld
  - dev packages
  - Neovim/CLI 工具，视情况迁移
- [ ] 新建 `profiles/services.nix`：
  - daed
  - postgresql
  - tailscale
  - printing/network 相关项，视情况迁移
- [ ] `configuration.nix` 只负责导入 profiles 和保留少量主机基础项。

验收标准：启用组合从 `configuration.nix` 主体中移出；主文件明显变薄。

## 阶段 5：建立 host 入口

- [ ] 新建 `hosts/ASUS/default.nix`。
- [ ] 将当前 `configuration.nix` 的主机专属内容逐步迁入：
  - `networking.hostName = "ASUS";`
  - `hardware-configuration.nix`
  - bootloader
  - timezone/locale
  - 用户基础配置
- [ ] 修改 `flake.nix` 中 `nixosConfigurations.ASUS.modules` 指向 host 入口。
- [ ] 保留 `configuration.nix` 作为过渡入口，或在迁移完成后删除。

验收标准：`flake.nix` 的 NixOS 配置入口是 `./hosts/ASUS`。

## 阶段 6：拆分 Home Manager 大文件

- [ ] 从 `home-manager/home.nix` 拆出：
  - `home-manager/features/packages.nix`
  - `home-manager/features/mime.nix`
  - `home-manager/features/git.nix`
  - `home-manager/features/theme.nix`
  - `home-manager/features/cli.nix`
- [ ] 保持 `home-manager/home.nix` 只做：
  - `home.username`
  - `home.homeDirectory`
  - imports
  - `home.stateVersion`
- [ ] 对和 NixOS feature 强相关的 HM 配置，优先考虑并回对应 `modules/*` feature。

验收标准：`home-manager/home.nix` 不再承载大包列表和大量业务配置。

## 阶段 7：拆大模块里的 package 构建逻辑

- [ ] `modules/apps/brave-origin/default.nix` 拆出 `package.nix`。
- [ ] `modules/apps/cc-switch/default.nix` 拆出 `package.nix`。
- [ ] `modules/apps/lobehub/default.nix` 拆出 `package.nix`。
- [ ] `modules/apps/im/default.nix` 拆出：
  - `wechat-sandbox.nix`
  - `qq-sandbox.nix`
- [ ] `modules/apps/daed/default.nix` 视情况拆出 package override 辅助文件。

验收标准：`default.nix` 主要负责 `options` 和 `config`；打包细节在相邻文件。

## 阶段 8：清理参数传递

- [ ] 模块内逐步用 `config.local.user.name` 替代 `username` specialArg。
- [ ] 检查是否还能减少 `home-manager.extraSpecialArgs`。
- [ ] `inputs` 暂时可以继续通过 specialArgs 传入，不急于替换。
- [ ] 等后续考虑 flake-parts 时，再整理 inputs 访问方式。

验收标准：用户名不再通过 specialArgs 散落传递；模块对本机用户名的依赖集中。

## 阶段 9：每步验证

- [ ] 每完成一个阶段运行格式化。
  - 建议命令：`nix fmt`
- [ ] 每完成一个阶段运行 eval/build 检查。
  - 建议命令：`nixos-rebuild dry-build --flake .#ASUS`
- [ ] 涉及 Home Manager 时，确认 `nixos-rebuild switch --flake .#ASUS` 前先 dry-build。
- [ ] 每阶段完成后用 `git diff` 复查是否包含无关变更。

验收标准：每阶段都是可回滚、可验证的小步提交。

## 暂不做

- [ ] 暂不迁移到 Dendrix/Dendritic。
- [ ] 暂不引入 Snowfall Lib。
- [ ] 暂不把所有 NixOS/HM 配置拆成 flake-parts class 输出。
- [ ] 暂不一次性重命名所有目录。

这些可以等 feature module 和 option 命名空间稳定后再评估。
