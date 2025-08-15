# ssh

三个脚本：
- `ssh-key-only-setup.sh` → 一键改为仅密钥登录
- `ssh-enable-password-login.sh` → 一键开启密码登录（简单版）
- `ssh-enable-password-and-set.sh` → 一键开启密码登录并修改指定用户密码（强制生效版）

## 一行命令使用

### 改为仅密钥登录
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-key-only-setup.sh | sudo bash -s -- <用户名> "<你的公钥>"
```

### 开启密码登录（简单版）
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-enable-password-login.sh | sudo bash
```

### 开启密码登录并修改密码（强制生效版）
**交互式输入密码（更安全，推荐）：**
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-enable-password-and-set.sh | sudo bash -s -- -u <用户名> --allow-root yes
```
**非交互（直接指定密码）：**
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-enable-password-and-set.sh | sudo bash -s -- -u <用户名> -p 'Str0ng!Pass' --allow-root yes
```

## 推送到 GitHub
```bash
git init
git add .
git commit -m "feat: initial scripts for SSH auth modes"
git branch -M main
git remote add origin git@github.com:dengfenga777/ssh.git
git push -u origin main
```

## 安全提示
- 请避免在公开场景下用命令行明文传递密码，优先使用交互式方式。
- 成功恢复登录后，建议尽快切回密钥登录或至少禁用 root 密码登录。
