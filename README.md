# ssh-key-login-script

两个脚本：
- `ssh-key-only-setup.sh` → 一键改为仅密钥登录
- `ssh-enable-password-login.sh` → 一键开启密码登录（可选：同时修改指定用户密码）

## 一行命令使用

### 改为仅密钥登录
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-key-only-setup.sh |       sudo bash -s -- <用户名> "<你的公钥>"
```

### 开启密码登录（仅开启，不改密码）
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-login.sh | sudo bash
```

### 开启密码登录并修改用户密码
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-login.sh |       sudo bash -s -- <用户名> "<新密码>"
```

## 注意
- 开启密码登录会允许密码认证，请确保密码强度并在需要时再开启。
- 改为仅密钥登录后，请在另一个终端验证密钥登录成功再断开旧会话，避免锁死。
