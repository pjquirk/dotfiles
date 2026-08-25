#!/usr/env/var bash
# shellcheck shell=bash
#
# Contains NVIDIA-specific aliases and functions

alias ssh-p4m="sshpass -p \$(op.exe read op://nvidia/p4-master/password) ssh pquirk@p4-master"
# SSH to a host on the p4-master network, using p4-master as a jump box.
function ssh-p4m-to() {
    sshpass -p $(op.exe read op://nvidia/p4-master/password) ssh -A -J pquirk@p4-master pquirk@"$1"
}

# SSH to a host via p4-master, then escalate to root with sudo. Used by ssh-gitlab2p4.
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

# Log in via Teleport and SSH to the omnistation host.
function ssh-omnistation {
    tsh login --proxy=nv-prd-it.teleport.sh --auth=entra --user=pquirk
    ssh pquirk@omni-lfn-4tpjf.nv-prd-it.teleport.sh
}

# SSH to a PSE sync host via p4-master, escalating root -> p4admin on the way through.
function ssh-sync-host {
    local pass=$(op.exe read op://nvidia/p4-master/password)
    local host="$1"
    local tmpfile=$(mktemp /tmp/expect.XXXXXX)
    cat > "$tmpfile" <<EOF
spawn ssh -t pquirk@p4-master "sudo -i su - p4admin -c 'ssh $host'"
expect {
    -re {[Pp]assword} { send -- "$pass\r" }
}
interact
EOF
    expect "$tmpfile"
    rm -f "$tmpfile"
}

alias ssh-gitlab2p4="ssh-p4m-root gitlab-to-p4"
alias ssh-rocky8="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-rocky8 -t 'bash --login'"
alias ssh-ansiblesandbox="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-ansiblesandbox -t 'bash --login'"
alias ssh-ansiblesandbox2="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-ansiblesandbox2 -t 'bash --login'"

if [ -f "$HOME/.config/pjquirk/local.bashrc" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/pjquirk/local.bashrc"
fi

# Install uv if not present
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
