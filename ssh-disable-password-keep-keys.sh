#!/usr/bin/env bash
# 关闭 SSH 密码登录，强制仅密钥登录（安全版，避免锁死）
# 与 ssh-enable-password-and-set.sh 配套
# 适配 Debian/Ubuntu/CentOS/RHEL 等（systemd）

set -euo pipefail

USER_NAME="root"   # 默认检查/写入公钥的用户
PUB_KEY=""         # 可选：提供一条公钥，先写入再切换
DENY_ROOT="no"     # yes|no：是否完全禁止 root 登录（默认允许 root 用密钥登录）

usage() {
  cat <<'EOF'
用法:
  sudo bash ssh-disable-password-keep-keys.sh [-u 用户名] [-k "公钥字符串"] [--deny-root yes|no]

示例:
  sudo bash ssh-disable-password-keep-keys.sh -u root
  sudo bash ssh-disable-password-keep-keys.sh -u ubuntu -k "ssh-ed25519 AAAA... user@pc"
  sudo bash ssh-disable-password-keep-keys.sh -u root --deny-root yes
EOF
  exit 1
}

# ---- 参数解析 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user) USER_NAME="${2:-}"; shift 2 ;;
    -k|--key)  PUB_KEY="${2:-}";  shift 2 ;;
    --deny-root) DENY_ROOT="${2:-no}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "未知参数: $1"; usage ;;
  esac
done
[[ -z "$USER_NAME" ]] && usage

# ---- 写入/检查公钥，避免锁死 ----
HOME_DIR=$(eval echo "~${USER_NAME}")
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"

if [[ -n "$PUB_KEY" ]]; then
  if ! grep -Fq "$PUB_KEY" "$AUTH_KEYS"; then
    echo "$PUB_KEY" >> "$AUTH_KEYS"
  fi
fi

# 至少需要一条有效公钥
if ! grep -Eq '^(ssh-|ecdsa-)' "$AUTH_KEYS"; then
  echo "[✗] 目标用户 $USER_NAME 的 $AUTH_KEYS 中没有任何有效公钥。为避免锁死，已退出。"
  echo "    解决：用 -k 传入一条公钥，或先手动写入 authorized_keys。"
  exit 1
fi

# ---- 备份配置 ----
BACKUP_DIR="/etc/ssh/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" || true
[[ -d /etc/ssh/sshd_config.d ]] && cp -a /etc/ssh/sshd_config.d "$BACKUP_DIR/sshd_config.d.bak" || true

# ---- 移除“允许密码”掉落配置，写入“仅密钥”掉落配置 ----
mkdir -p /etc/ssh/sshd_config.d
ALLOW_DROPIN="/etc/ssh/sshd_config.d/99-allow-password.conf"
[[ -f "$ALLOW_DROPIN" ]] && rm -f "$ALLOW_DROPIN"

FORCE_KEYS_DROPIN="/etc/ssh/sshd_config.d/99-force-keys.conf"
cat > "$FORCE_KEYS_DROPIN" <<'CONF'
UsePAM yes
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
# 只允许密钥认证
AuthenticationMethods publickey
AuthorizedKeysFile .ssh/authorized_keys
CONF

if [[ "$DENY_ROOT" == "yes" ]]; then
  echo "PermitRootLogin no" >> "$FORCE_KEYS_DROPIN"
else
  echo "PermitRootLogin prohibit-password" >> "$FORCE_KEYS_DROPIN"
fi

# ---- 同步修正主配置，避免被后续行覆盖 ----
SSHD_CONFIG="/etc/ssh/sshd_config"
# 关闭所有密码/交互式认证
sed -ri 's/^\s*#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$SSHD_CONFIG" || true
sed -ri 's/^\s*#?\s*KbdInteractiveAuthentication\s+.*/KbdInteractiveAuthentication no/' "$SSHD_CONFIG" || true
sed -ri 's/^\s*#?\s*ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG" || true
# 开启公钥
if grep -qiE '^\s*PubkeyAuthentication\s+' "$SSHD_CONFIG"; then
  sed -ri 's/^\s*#?\s*PubkeyAuthentication\s+.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
else
  echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
fi
# 只允许密钥（去掉任何 AuthenticationMethods 覆盖，再设置 publickey）
sed -ri '/^\s*AuthenticationMethods\s+/d' "$SSHD_CONFIG" || true
echo "AuthenticationMethods publickey" >> "$SSHD_CONFIG"

# root 登录策略
if grep -qiE '^\s*PermitRootLogin\s+' "$SSHD_CONFIG"; then
  if [[ "$DENY_ROOT" == "yes" ]]; then
    sed -ri 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$SSHD_CONFIG"
  else
    sed -ri 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
  fi
else
  [[ "$DENY_ROOT" == "yes" ]] && echo "PermitRootLogin no" >> "$SSHD_CONFIG"                                    || echo "PermitRootLogin prohibit-password" >> "$SSHD_CONFIG"
fi

# ---- 语法检查并重载/重启（兼容 ssh / sshd）----
sshd -t
systemctl reload ssh  || systemctl reload sshd || systemctl restart ssh || systemctl restart sshd

# ---- 打印有效配置摘要，便于自检 ----
echo "[*] Effective (sshd -T):"
sshd -T | egrep '^(usepam|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|challengeresponseauthentication|permitrootlogin|authenticationmethods)\s'

echo
echo "[✓] 已关闭密码登录，当前仅允许密钥登录。"
echo "[!] 请在另一个终端用密钥测试登陆后，再关闭本会话，例如："
echo "    ssh -i /路径/私钥 -o IdentitiesOnly=yes ${USER_NAME}@<服务器IP>"
