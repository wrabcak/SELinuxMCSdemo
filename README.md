# SELinuxMCSdemo
Purpose of this repository is to demonstrate how SELinux MCS feature can separate access to objects on the system for same SELinux user.

Following demo shows how [SELinux users](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/selinux_users_and_administrators_guide/sect-security-enhanced_linux-targeted_policy-confined_and_unconfined_users) can be mapped to real Linux users and confine them. For sevaral reasons, sometimes it's nescessary to restrict access to multiple type of files to one SELinux user. For this use case, multi-category secutity implemented in SELinux can be used. For more information what MCS is, please follow [the official Red Hat SELinux docs](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/sec-mcs-getstarted).

> Warning: Please execute the demo on development system!

## How to
Shell script should download all dependencies to run the demo.

To execute the demo, just run following commands:
```bash
git clone https://github.com/wrabcak/SELinuxMCSdemo.git; cd SELinuxMCSdemo
chmod +x ./demo.sh
./demo.sh
```
> Note: Password for profileX users is: "r".


Tested on the latest stable version of Fedora and RHEL-8.

## Examples

### User with c1 can access only c1 files
```bash
$ id -Z
staff_u:staff_r:staff_t:s0-s0:c1

$ ll -Z file
-rwxrwxrwx. 1 root root unconfined_u:object_r:usr_t:s0:c1 28 Sep  4 21:08 file1
-rwxrwxrwx. 1 root root unconfined_u:object_r:usr_t:s0:c3 28 Sep  4 21:08 file3

$ cat file1
Data related to category c1

$ cat file3
cat: file3: Permission denied
```
> Note: files has mode 777 which means they are accesible by anyone on the system!

### User with c1,c3 can access both files
```bash
$ id -Z
staff_u:staff_r:staff_t:s0-s0:c1,c3

$ ll -Z
total 8
-rwxrwxrwx. 1 root root unconfined_u:object_r:usr_t:s0:c1 28 Sep  4 21:08 file1
-rwxrwxrwx. 1 root root unconfined_u:object_r:usr_t:s0:c3 28 Sep  4 21:08 file3

$ cat file1
Data related to category c1

$ cat file3
Data related to category c3
```

