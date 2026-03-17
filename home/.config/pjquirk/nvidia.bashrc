# Contains NVIDIA-specific aliases and functions

alias ssh-p4m="sshpass -p \$(op.exe read op://nvidia/p4-master/password) ssh pquirk@p4-master"
alias ssh-rocky8="sshpass -p \$(op.exe read 'op://nvidia/Windows Login/password') ssh pquirk@pquirk-rocky8"