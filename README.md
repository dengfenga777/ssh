# ssh-key-login-script

一键将 SSH 登录改为**仅密钥登录**（适用于你**已经有公钥**的情况）。

## 用法

**方式 A：下载脚本后运行**

```bash
chmod +x ssh-key-only-setup.sh
sudo ./ssh-key-only-setup.sh <用户名> "<你的公钥字符串>"
```

示例：
```bash
sudo ./ssh-key-only-setup.sh root "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxx user@pc"
sudo ./ssh-key-only-setup.sh ubuntu "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxx user@pc"
```

**方式 B：上传到 GitHub 后，一行命令运行（raw 直链）**

将本仓库推送到 GitHub 后，可以这样使用（把 `<yourname>` 和 `<repo>` 换成你的）：
```bash
curl -fsSL https://raw.githubusercontent.com/<yourname>/<repo>/main/ssh-key-only-setup.sh |       sudo bash -s -- <用户名> "<你的公钥字符串>"
```

## 注意事项
- **务必保持当前 SSH 会话不关闭**，新开一个终端测试密钥登录成功后再断开旧会话，避免锁死自己。
- 脚本会：
  - 追加你的公钥到 `~/.ssh/authorized_keys`（不会覆盖已有条目）
  - 设置正确权限（700/600）
  - 在 `/etc/ssh/sshd_config` 中开启 `PubkeyAuthentication`，关闭密码和交互式认证
  - 重载或重启 `sshd`
- 如果你的系统服务名是 `ssh` 而不是 `sshd`，可以将脚本里最后一行改成：
  ```bash
  systemctl reload ssh || systemctl restart ssh
  ```

## 许可证
MIT
