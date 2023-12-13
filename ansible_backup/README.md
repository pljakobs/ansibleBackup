# Ansible Backup Script

In this repo there are two examples. `backup_simple.yml` and `backup.yml` a more complete example.
 
#### `backup_simple.yml` - Simple Example
`backup_simple.yml` does the following two tasks:
1. Creates a local directory on the server where the playbook is run and uses the root directory defined in the `backup_simple.yml` vars section.
2. Uses the synchronize module to rsync the directories specified in your `inventory.yml` file. 

This playbook also requires that you have `rsync` preinstalled on your host to backup and that you have allowed `NOPASSWD` access to at least the `rsync` binary. 

#### `backup.yml` - More "Complete" Example
`backup.yml` is a more complete example that includes some automation to make sure minimal dependencies exist and does the following:
1. Installs `rsync` if needed on RHEL/CentOS/Fedora machines.
2. Sets `NOPASSWD` for our current ansible_user and restarts `sshd` if needed.
3. Creates a local directory on the server where the playbook is run and uses the root directory defined in the `backup_simple.yml` vars section.
4. Uses the synchronize module to rsync the directories specified in your `inventory.yml` file. 

An example `inventory.yml` file is provided that you may edit the names of the hosts to be `FQDN` or fill in the `ansible_host` with the IP address of the machines to backup. 

*Note* by default the playbooks will use a `lin-excludes.txt` file to exclude files but you may change this behavior at the task level of `omit` if preferred.

We could get a bit fancier with our `rsync_path` if we wanted to specify per src_path whether we want to use `sudo rsync` or just plain ole `rsync` with `rsync` being the default option. However in my tests this made no change to results of backup stored locally with regards to userid/gid. An example of this is featured below:

We would need to modify our `inventory.yml` file to change it's format slightly:
 ```
    all:
      hosts:
        fhem2:
          #ansible_host: <replace-with-ip-address-if-no-dns>
          src_paths:
            - path: "/etc"
              sudo: true
            - path: "/opt/docker"
            - path: "/opt/fhem"
```

Edit needed for the `backup.yml` or `backup_simple.yml` file:
```
    - name: Perform backups
      ansible.builtin.synchronize:
        src: "{{ item.path }}"
        dest: "{{ backup_base }}{{ inventory_hostname }}"
        mode: pull
        rsync_path: "{{ 'sudo rsync' if item.sudo | default(false) else 'rsync' }}"
        rsync_opts: "-R {{ rsync_options | default(omit) }}"
      with_items: "{{ src_paths }}"
      delegate_to: localhost
```
