echo "=== USER AUDIT ==="

# 1. List all users with login shells (not /sbin/nologin or /usr/sbin/nologin)
echo ""
echo "Users with login shells:"
awk -F: '$7 !~ /(nologin|false)/ {print $1" -> "$7}' /etc/passwd

# 2. Check which users have sudo rights
echo ""
echo "Users with sudo rights:"
# Members of the sudo group
SUDO_GROUP=$(getent group sudo | awk -F: '{print $4}' | tr ',' '\n')
if [[ -n "$SUDO_GROUP" ]]; then
    echo "$SUDO_GROUP"
else
    echo "No users in sudo group"
fi

# Users explicitly in sudoers file
echo ""
echo "Users with explicit sudoers entries:"
grep -Po '^\s*\K[A-Za-z0-9_-]+' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sort -u

# 3. Flag any user with UID 0 other than root
echo ""
echo "Checking for UID 0 users:"
awk -F: '$3 == 0 && $1 != "root" {print "WARNING: User " $1 " has UID 0"}' /etc/passwd
