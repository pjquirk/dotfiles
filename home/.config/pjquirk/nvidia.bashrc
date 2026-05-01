#!/usr/env/var bash
# shellcheck shell=bash
#
# Contains NVIDIA-specific aliases and functions

alias ssh-p4m="sshpass -p \$(op.exe read op://nvidia/p4-master/password) ssh pquirk@p4-master"
function ssh-p4m-to() {
    sshpass -p $(op.exe read op://nvidia/p4-master/password) ssh -t pquirk@p4-master ssh pquirk@"$1"
}

function ssh-p4m-root {
    local pass=$(op.exe read op://nvidia/p4-master/password)
    local tmpfile=$(mktemp /tmp/expect.XXXXXX)
    cat > "$tmpfile" <<EOF
spawn ssh -t pquirk@p4-master ssh -t pquirk@$1 sudo -i
expect -re {[Pp]assword}
send -- "$pass\r"
file delete $tmpfile
interact
EOF
    expect "$tmpfile"
    rm -f "$tmpfile"
}


alias ssh-rocky8="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-rocky8 -t 'bash --login'"
alias ssh-ansiblesandbox="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-ansiblesandbox -t 'bash --login'"
alias ssh-ansiblesandbox2="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-ansiblesandbox2 -t 'bash --login'"
