#!/usr/bin/env bash
# 启用 SSH 密码登录 + 可选修改指定用户密码（强制生效版）
# 适配 Debian/Ubuntu/CentOS/RHEL 等，systemd 环境
set -euo pipefail

USER_NAME="root"   # 默认用户
NEW_PASS=""        # 留空则交互式输入
ALLOW_ROOT="yes"   # yes|no —— 是否允许 root 用密码登录

usage() {
  cat <<'EOF'
用法:
  sudo bash ssh-enable-password-and-set.sh [-u 用户名] [-p 新密码] [--allow-root yes|no]

示例:
  sudo bash ssh-enable-password-and-set.sh -u root -p 'Str0ng!Pass'
  sudo bash ssh-enable-password-and-set.sh -u ubuntu -p 'Str0ng!Pass' --allow-root no
EOF
  exit 1
}

# --- 解析参数 ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user) USER_NAME="${2:-}"; shift 2 ;;
    -p|--pass) NEW_PASS="${2:-}"; shift 2 ;;
    --allow-root) ALLOW_ROOT="${2:-yes}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "未知参数: $1"; usage ;;
  esac
done

[[ -z "$USER_NAME" ]] && usage
if [[ -z "${NEW_PASS}" ]]; then
  read -rsp "为用户 ${USER_NAME} 设置的新密码: " NEW_PASS; echo
  [[ -z "$NEW_PASS" ]] && { echo "新密码不能为空"; exit 1; }
fi

# --- 备份配置 ---
BACKUP_DIR="/etc/ssh/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" || true
[[ -d /etc/ssh/sshd_config.d ]] && cp -a /etc/ssh/sshd_config.d "$BACKUP_DIR/sshd_config.d.bak" || true

# --- 高优先级 drop-in：确保密码登录生效 ---
mkdir -p /etc/ssh/sshd_config.d
DROPIN="/etc/ssh/sshd_config.d/99-allow-password.conf"
cat > "$DROPIN" <<'CONF'
UsePAM yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
# 避免强制仅公钥的配置
AuthenticationMethods any
CONF
# root 密码登录是否允许
if [[ "$ALLOW_ROOT" == "yes" ]]; then
  echo "PermitRootLogin yes" >> "$DROPIN"
else
  echo "PermitRootLogin prohibit-password" >> "$DROPIN"
fi

# --- 同步修正主配置，避免被后续行覆盖 ---
sed -ri 's/^\s*#?\s*PasswordAuthentication\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
sed -ri 's/^\s*#?\s*KbdInteractiveAuthentication\s+.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config || true
sed -ri 's/^\s*#?\s*ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config || true
sed -ri '/^\s*AuthenticationMethods\s+/d' /etc/ssh/sshd_config || true
if grep -qiE '^\s*PermitRootLogin\s+' /etc/ssh/sshd_config; then
  if [[ "$ALLOW_ROOT" == "yes" ]]; then
    sed -ri 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  else
    sed -ri 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  fi
else
  [[ "$ALLOW_ROOT" == "yes" ]] && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config                                    || echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
fi

# --- 解锁用户 & 修改密码 ---
if id "$USER_NAME" >/dev/null 2>&1; then
  usermod -U "$USER_NAME" 2>/dev/null || true
  echo "${USER_NAME}:${NEW_PASS}" | chpasswd
else
  echo "[✗] 用户 ${USER_NAME} 不存在"; exit 1
fi

# --- 语法检查并重载/重启 ---
sshd -t
systemctl reload ssh  || systemctl reload sshd || systemctl restart ssh || systemctl restart sshd

# --- 打印有效配置摘要 ---
echo "[*] Effective (sshd -T):"
sshd -T | egrep '^(usepam|passwordauthentication|kbdinteractiveauthentication|challengeresponseauthentication|permitrootlogin|authenticationmethods)\s'

echo "[✓] 已开启密码登录，并为用户 ${USER_NAME} 修改密码。"
echo "现在可用: ssh ${USER_NAME}@<服务器IP>"
