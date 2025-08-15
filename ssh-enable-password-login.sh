#!/usr/bin/env bash
# 一键开启 SSH 密码登录
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"

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

echo "[*] 重新加载 SSH 配置..."
systemctl reload sshd || systemctl restart sshd

echo "[✓] 已开启 SSH 密码登录，请用密码登录测试。"
