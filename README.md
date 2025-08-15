# ssh-key-login-script

三个脚本：
- `ssh-key-only-setup.sh` → 一键改为仅密钥登录
- `ssh-enable-password-login.sh` → 一键开启密码登录（简单版）
- `ssh-enable-password-and-set.sh` → 一键开启密码登录并修改指定用户密码（强制生效版）

## 一行命令使用（推送到 GitHub 后，把 `<你的用户名>` 换成你的）

### 改为仅密钥登录
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-key-only-setup.sh |       sudo bash -s -- <用户名> "<你的公钥>"
```

### 开启密码登录（简单版）
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-login.sh | sudo bash
```

### 开启密码登录并修改密码（强制生效版）
**交互式输入密码（更安全，推荐）：**
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-and-set.sh |       sudo bash -s -- -u <用户名> --allow-root yes
```
**非交互（直接指定密码）：**
```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/ssh-key-login-script/main/ssh-enable-password-and-set.sh |       sudo bash -s -- -u <用户名> -p 'Str0ng!Pass' --allow-root yes
```

## 说明
- “强制生效版”会写入 `/etc/ssh/sshd_config.d/99-allow-password.conf`，并同步修正主配置，移除 `AuthenticationMethods` 的强制公钥要求；确保密码登录不会被覆盖。
- 执行后会打印 `sshd -T` 的关键生效项。
- 生产环境请尽快改回密钥登录或至少禁用 root 密码登录。

## 推送到 GitHub
```bash
git init
git add .
git commit -m "feat: add advanced password-enable script"
git branch -M main
git remote add origin git@github.com:<你的用户名>/ssh-key-login-script.git
git push -u origin main
```
