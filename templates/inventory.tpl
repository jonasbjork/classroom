[servers]
%{ for i , server in servers ~}
${server} ansible_host=${server_ip[i]} ansible_user=root ansible_ssh_private_key_file=~/.ssh/my-ssh-key
%{ endfor ~}