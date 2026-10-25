# dae

`config.dae` 保存从 daed 迁移的当前全局配置、DNS、路由和 5 个分组。
Nix 模块启用 `dae-unstable`，服务直接读取仓库中的文件，方式与 niri 配置相同。

首次切换，在仓库根目录执行：

```sh
sudo nixos-rebuild switch --flake .#thinkpad-t14s
```

之后编辑 `config.dae`，无需重新构建系统，执行：

```sh
sudo systemctl reload dae
journalctl -u dae -f
```

订阅链接位于 `~/.config/dae/subscriptions.dae`，仓库中的同名链接由 `config.dae` 的 `include` 引入。
7 个订阅使用 `https-file://` 保留在线更新；`persist.d/` 已导入原有 109 个节点，作为网络不可用时的缓存。
保留原刷新时间：每天 00:10、06:10、12:10、18:10 自动 reload。

私有文件和缓存实际保存在仓库外的 `~/.config/dae/`，迁移到其他机器时需要单独安全复制该目录。
仓库中的 `subscriptions.dae`、`persist.d/` 只是链接，已被 Git 忽略；使用 `path:` 构建 flake 也不会复制凭据内容。
配置及私有文件使用 `0600` 权限，私有目录使用 `0700`；Nix 激活时会创建链接并修正主配置权限。
原始 `/var/lib/daed/wing.db` 保留，可用于找回未启用的路由等设置。

dae 没有 daed 的 Web 面板。运行情况使用 `systemctl status dae` 和上述日志命令查看。
