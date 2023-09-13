read -p "Enter Destination IP: " ip
read -p "Enter Destination Port: " dport
read -p "Enter Local Tunnel Port: " tport
ssh-keygen -t rsa -N '' <<< $'\n\n\n'
ssh-copy-id -i ~/.ssh/id_rsa.pub -p$dport root@$ip <<< $'yes\n'

ssh -p $dport root@$ip << EOF

    if ! grep -q "Port $dport" /etc/ssh/sshd_config; then
        sed -i "1s/^/Port $dport\n/" /etc/ssh/sshd_config
        echo "Added Port $dport to /etc/ssh/sshd_config"
    else
        echo "Port $dport already exists in /etc/ssh/sshd_config"
    fi
    sudo systemctl restart ssh.service
    exit

EOF

ssh -p$dport -f -N -L *:$tport:localhost:$dport root@$ip

if ! crontab -l | grep -q "*/5 * * * * ssh -p$dport -f -N -L *:$tport:localhost:$dport root@$ip"; then
    (crontab -l ; echo "*/5 * * * * ssh -p$dport -f -N -L *:$tport:localhost:$dport root@$ip") | crontab -
    echo "Added command to crontab"
else
    echo "Command already exists in crontab"
fi