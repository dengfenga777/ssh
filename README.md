# ssh-key-login-script

两个脚本：
- `ssh-key-only-setup.sh` → 一键改为仅密钥登录
- `ssh-enable-password-login.sh` → 一键开启密码登录

## 一键改为仅密钥登录
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-key-only-setup.sh |       sudo bash -s -- <用户名> "<你的公钥>"
```

示例：
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-key-only-setup.sh |       sudo bash -s -- root "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxx user@pc"
```

## 一键开启密码登录
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-login.sh | sudo bash
```

## 注意事项
- 改为密钥登录后，保持当前 SSH 会话不关闭，先新开一个终端测试密钥登录成功后再断开旧会话。
- 开启密码登录会允许 root 和所有用户使用密码登录，请确保密码强度。

## 许可证
MIT
