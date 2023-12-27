#!/bin/bash

# Create NetsysGroup to share kube files
sudo groupadd netsys

userList=$(sudo find /home -maxdepth 1 -type d -uid +1000 | awk -F/ '{print $(NF)}')

# 문자열을 줄 바꿈으로 구분하여 배열에 저장
IFS=$'\n' read -d '' -r -a users <<< "$userList"

# Add all users to group [netsys]
for user in "${users[@]}"; do
    sudo usermod -aG netsys "$user"
    echo "Added $user to group [netsys]."
done
