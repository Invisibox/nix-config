# dae

`config.dae` 保存从 daed 迁移的当前全局配置、DNS、路由和 5 个分组。
Nix 模块启用 `dae-unstable`，将公开配置部署为 `/etc/dae/config.dae`，权限为 `0400`。
运行时不依赖仓库的位置或工作区文件权限。
微信主进程 `wechat` 和内嵌进程 `WeChatAppEx` 使用 `must_direct` 绕过透明代理，避免私有协议或 IP 直连落入代理分组；仅配置腾讯域名直连无法覆盖这些连接。

## 密钥与恢复

现有订阅已加密为 `subscriptions.dae.enc`，`.sops.yaml` 保存对应的 age 公钥。
`~/.config/sops/age/keys.txt` 供普通用户运行 `sops edit`，`/var/lib/sops-nix/key.txt` 供系统解密；两处保存同一把私钥，均使用 `0600` 权限。
请先将私钥安全备份到仓库之外；重装必须恢复原私钥，新生成的密钥无法解开现有密文。
恢复步骤见[主机安装说明](../../../hosts/thinkpad-t14s/INSTALL.md)。

## 修改配置

公开规则直接编辑 `config.dae`。订阅通过 SOPS 编辑，保存时会重新加密：

```sh
sops edit --input-type binary --output-type binary \
  modules/services/dae/subscriptions.dae.enc
```

修改公开规则或加密订阅后都需要重新构建并切换；NixOS 会请求 dae reload：

```sh
sudo nixos-rebuild switch --flake '.#thinkpad-t14s'
```

只刷新在线订阅和查看日志时执行：

```sh
sudo systemctl reload dae
journalctl -u dae -f
```

## 运行时文件

- `/etc/dae/config.dae`：由 Nix 生成的公开配置，不要写入订阅凭据，文件内容会进入 Nix store。
- `/etc/dae/subscriptions.dae`：sops-nix 指向 `/run/secrets/dae-subscriptions` 的链接；解密文件属于 root，权限为 `0400`，订阅变更时触发 dae reload。
- `/etc/dae/persist.d`：指向 `/var/lib/dae`，由 systemd 创建为 root 所有的 `0700` 状态目录；服务使用 `0077` umask 写入缓存。

7 个订阅使用 `https-file://` 保留在线更新，缓存供网络不可用时使用。
保留原刷新时间：每天 00:10、06:10、12:10、18:10 自动 reload。
迁移到其他机器时，需要安全复制 age 私钥；缓存可单独备份和恢复，步骤见主机安装说明。

dae 没有 daed 的 Web 面板。运行情况使用 `systemctl status dae` 和上述日志命令查看。
