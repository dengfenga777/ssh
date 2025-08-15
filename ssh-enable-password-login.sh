#!/usr/bin/env bash
# 一键开启 SSH 密码登录，并可选修改指定用户密码
set -e

USER_NAME="${1:-}"
NEW_PASS="${2:-}"
SSHD_CONFIG="/etc/ssh/sshd_config"

# 开启密码登录
if grep -q "^PasswordAuthentication" $SSHD_CONFIG; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' $SSHD_CONFIG
else
    echo "PasswordAuthentication yes" >> $SSHD_CONFIG
fi

if grep -q "^KbdInteractiveAuthentication" $SSHD_CONFIG; then
    sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' $SSHD_CONFIG
else
    echo "KbdInteractiveAuthentication yes" >> $SSHD_CONFIG
fi

if grep -q "^ChallengeResponseAuthentication" $SSHD_CONFIG; then
    sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' $SSHD_CONFIG
else
    echo "ChallengeResponseAuthentication yes" >> $SSHD_CONFIG
fi

if grep -q "^PermitRootLogin" $SSHD_CONFIG; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' $SSHD_CONFIG
else
    echo "PermitRootLogin yes" >> $SSHD_CONFIG
fi

# 如果提供了用户名和密码，就修改密码
if [[ -n "$USER_NAME" && -n "$NEW_PASS" ]]; then
    if id "$USER_NAME" >/dev/null 2>&1; then
        echo "${USER_NAME}:${NEW_PASS}" | chpasswd
        echo "[✓] 已修改用户 $USER_NAME 的密码。"
    else
        echo "[✗] 用户 $USER_NAME 不存在，无法修改密码。"
        exit 1
    fi
fi

# 重启 SSH
echo "[*] 重新加载 SSH 配置..."
systemctl reload sshd || systemctl restart sshd

echo "[✓] 已开启 SSH 密码登录。"
if [[ -n "$USER_NAME" && -n "$NEW_PASS" ]]; then
    echo "现在可以用账号 [$USER_NAME] 和新密码登录。"
fi
