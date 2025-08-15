#!/usr/bin/env bash
# 一键将 SSH 登录改为仅密钥登录（你已有公钥的情况）
set -e

# ===== 参数 =====
USER_NAME="${1:-root}"      # 第一个参数：用户名（默认 root）
PUB_KEY="${2:-}"            # 第二个参数：公钥内容

if [[ -z "$PUB_KEY" ]]; then
  echo "用法: sudo bash $0 用户名 'ssh-ed25519 AAAA...'"
  exit 1
fi

# ===== 路径设置 =====
HOME_DIR=$(eval echo "~${USER_NAME}")
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# ===== 创建 .ssh 并写入公钥 =====
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"

if grep -Fq "$PUB_KEY" "$AUTH_KEYS"; then
  echo "[*] 公钥已存在，跳过追加。"
else
  echo "$PUB_KEY" >> "$AUTH_KEYS"
  echo "[+] 公钥已写入 $AUTH_KEYS"
fi

# ===== 修改 sshd 配置 =====
SSHD_CONFIG="/etc/ssh/sshd_config"

grep -q "^PubkeyAuthentication" $SSHD_CONFIG &&       sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSHD_CONFIG ||       echo "PubkeyAuthentication yes" >> $SSHD_CONFIG

grep -q "^PasswordAuthentication" $SSHD_CONFIG &&       sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' $SSHD_CONFIG ||       echo "PasswordAuthentication no" >> $SSHD_CONFIG

grep -q "^KbdInteractiveAuthentication" $SSHD_CONFIG &&       sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' $SSHD_CONFIG ||       echo "KbdInteractiveAuthentication no" >> $SSHD_CONFIG

grep -q "^ChallengeResponseAuthentication" $SSHD_CONFIG &&       sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' $SSHD_CONFIG ||       echo "ChallengeResponseAuthentication no" >> $SSHD_CONFIG

if grep -q "^PermitRootLogin" $SSHD_CONFIG; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSHD_CONFIG
else
  echo "PermitRootLogin prohibit-password" >> $SSHD_CONFIG
fi

# ===== 重启 sshd =====
echo "[*] 重启 SSH 服务..."
systemctl reload sshd || systemctl restart sshd

echo "[✓] 已设置用户 $USER_NAME 仅能通过密钥登录。"
echo "请用以下命令测试："
echo "ssh -i /路径/私钥 $USER_NAME@服务器IP"
