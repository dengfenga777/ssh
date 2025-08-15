# ssh

四个脚本：
- `ssh-key-only-setup.sh` → 一键改为仅密钥登录
- `ssh-enable-password-login.sh` → 一键开启密码登录（简单版）
- `ssh-enable-password-and-set.sh` → 一键开启密码登录并修改指定用户密码（强制生效版）
- `ssh-disable-password-keep-keys.sh` → 关闭密码登录，仅允许密钥（先校验/追加公钥，避免锁死）

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

### 关闭密码登录（强制仅密钥，防锁死）
**已有公钥：**
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-disable-password-keep-keys.sh | sudo bash -s -- -u <用户名>
```
**顺便追加一条公钥再关闭密码登录：**
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-disable-password-keep-keys.sh | sudo bash -s -- -u <用户名> -k "ssh-ed25519 AAAA... user@pc"
```
**关闭后同时彻底禁用 root 登录（可选）：**
```bash
curl -fsSL https://raw.githubusercontent.com/dengfenga777/ssh/main/ssh-disable-password-keep-keys.sh | sudo bash -s -- -u <用户名> --deny-root yes
```

## 推送到 GitHub
```bash
git init
git add .
git commit -m "feat: add disable-password script and update README"
git branch -M main
git remote add origin git@github.com:dengfenga777/ssh.git
git push -u origin main
```

## 兼容性与安全
- 所有脚本兼容 `ssh`/`sshd` 两种服务名，并在变更后进行 `sshd -t` 语法检查。
- “开启密码并改密（强制生效版）” 与 “关闭密码（仅密钥）” 互相覆盖：
  - 开启脚本会创建/更新 `/etc/ssh/sshd_config.d/99-allow-password.conf`。
  - 关闭脚本会删除该文件并创建 `/etc/ssh/sshd_config.d/99-force-keys.conf`。
- 关闭脚本在切换前会校验/追加公钥，避免把自己锁在外面。
