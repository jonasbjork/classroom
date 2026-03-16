# classroom
Set up lab environment for class.

You need to have Terraform or opentofu installed. Also Ansible is needed.

I am using [Hetzner Cloud](https://hetzner.cloud/?ref=VO2m2lpX8EoQ) for this setup, but it could be changed to other cloud providers too. I have used Amazon Web Services and Digital Ocean in the past.

Usage is described further down, please read the info blocks first.

## Terraform info

The file `terraform.tfvars` contains some variables you need to set.

- `hcloud_token` - this is the API KEY from Hetzner Cloud.
- `domain_name` - this is the domain name you want to use, Terraform will setup the domain in Hetnzer Cloud and own it there, so when you are destroying your environment the domain will be gone to. Make sure that you have set up NS records so they point at Hetzner DNS: `helium.ns.hetzner.de.`, `hydrogen.ns.hetzner.com.` and `oxygen.ns.hetzner.com.`
- `location` - is the Hetzner data center you want to run your servers in, I use `fsn1`.
- `server_type` - is the instance type for the virtual servers, I use `cx33` which is small and cheap.
- `servers{}` - is the list of servers you want to create. In the file there is four servers at the moment: `jonas`, `anders`, `sebastian` and `oscar`. You just add or delete servers here, and Terraform will take care of the rest. Example:
```
servers = {
    "jonas"     = { name = "jonas" }
    "anders"    = { name = "anders" }
    "sebastian" = { name = "sebastian" }
    "oscar"     = { name = "oscar" }
}
```

The file `main.tf` contains things you probably want to change (use the `terraform.tfvars` file to override):

- `ssh_key_name` - the name of your ssh key in Hetzner Cloud.
- `public_key_path` - the path to the public ssh key, defaults to ssh/my-ssh-key.pub which means your key is in the ssh folder of this repo.
- `image` - I use centos-stream-9 for my labs, so it's there..

I set up firewall rules too, only allowing 22/tcp, 80/tcp, 443/tcp and 8080/tcp. If you need more ports open you have to add them here. Note that this is the Hetzner Cloud firewall, so the students can't open other ports on the lab machines and allow access to them.

The `main.tf` file will also create A-records for all servers created with Terraform.

In the end of `main.tf` an inventory file for Ansible will be created, it uses the template from the folder `templates/` and will create the `ansbile/inventory` file. The template:

```
${server} ansible_host=${server_ip[i]} ansible_user=root ansible_ssh_private_key_file=~/.ssh/my-ssh-key
```

Note that the `ansible_ssh_private_key` is hard coded here, and you need to change it to your key path. This is the `PRIVATE` key, and it allowes Ansible to login to the servers.

## Ansible info

Terraform will create the `inventory` file for us, in the `ansible/` folder.

There is only one playbook, `setup.yaml`. In the top of the file you will see the ssh_user and ssh_pass variables, that is the user account that will be created for the student. Make sure you change the SUPERSECRETPASSWORD123 to something else. Also you might want to change the "student" username.

Ansible will set the servers to use 1.1.1.1 and 9.9.9.9 as DNS resolvers, you can change that in the setup.yaml file.

Time zone will be set to Europe/Stockholm, all packages will be upgraded and EPEL will be enabled.

Packages installed:

- git-core
- fail2ban
- nano
- podman
- jq
- bash-completion
- podman-compose

Just add more if needed, and remove what you don't want.

Fail2ban is installed to make ssh a bit more secure, there is a lot of bots out there scanning for ssh servers. If you have 3 failed logins, your IP address will be banned (blocked). Just use another internet (like your phone) to connect and remove your ban with fail2ban-client on the server.

I am setting the text editor `nano` as default in the system as many of my student really have a hard time with `vim`.

The user `student` is created, and also added to the `wheel` group which means that the student can `sudo` to become root.

SELinux is set to enforce, as I like to teach my students to work with SELinux instead of disabling it and throw away one of the best security measures there is.

Finally I remove the Hetzner provided *cloud-init* file, and change ssh configuration to allow login with only password.

That's it!

## Install and use

I use opentofu instead of terraform, and I am on a macOS system.

```
tofu init
tofu plan
tofu apply
````

It takes a couple of minutes and then your servers are ready in the cloud. Now you change to `ansible/` folder:

```
cd ansible
```

The `inventory` file was created by Terraform and will be used to configure the servers:

```
ansible-playbook -i inventory setup.yaml
```

Takes a while, and then your servers are ready.

## Suggestions and improvements

Any suggestions or improvements are welcome!



DEMO 16 MARS


