#!/usr/bin/env sh
# Copyright (C) 2021 Lukas Vrabec, <lvrabec@redhat.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

echo "
Purpose of this script is to prepare environment to show how SELinux MCS feature can separate access to objects on the system for same SELinux user. In our case "staff_u".

Example:
# SELinux label for a Linux user - SELinux user staff_u and category c1
$ id -Z
staff_u:staff_r:staff_t:s0-s0:c1

# example of files with categories either c1 or c3
$ ls -aZ /opt/data/
unconfined_u:object_r:usr_t:s0:c1 file1
unconfined_u:object_r:usr_t:s0:c3 file3

# user can access file1 because user has access to c1
$ cat /opt/data/file1
secret data

# user cannot access file3 because user has access only to category c1 but file has category c3
$ cat /opt/data/file3
cat: /opt/data/file3: Permission denied
"

# root priviledges required
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# install all required packages
dnf yum install -y setools-console policycoreutils-python-utils mcstrans chcat 2> /dev/null

# prepare env for demo
mkdir /opt/data

cat > local_demo.cil <<EOF
(typeattributeset mcs_constrained_type (staff_t))
EOF

semodule -i local_demo.cil

useradd profile1
useradd profile2
useradd profile3

echo "profile1:r" | chpasswd
echo "profile2:r" | chpasswd
echo "profile3:r" | chpasswd

echo "Data related to category c1" > /opt/data/file1
echo "Data related to category c3" > /opt/data/file3

# start demo

echo ""
echo "Demo start"

read -p "--> chmod 777 /opt/data/file*"
echo ""
chmod 777 /opt/data/file*
echo ""

read -p "--> chcat c1 /opt/data/file1"
echo ""
chcat c1 /opt/data/file1
echo ""

read -p "--> chcat c3 /opt/data/file3"
echo ""
chcat c3 /opt/data/file3
echo ""

read -p "--> ls -aZ /opt/data"
echo ""
ls -aZ /opt/data
echo ""

read -p "--> sestatus"
echo ""
sestatus
echo ""

read -p "--> semanage login -l"
echo ""
semanage login -l
echo ""

read -p "--> semanage login -a -s staff_u -rs0 profile1"
echo ""
semanage login -a -s staff_u -rs0 profile1
echo ""

read -p "--> semanage login -a -s staff_u -rs0 profile2"
echo ""
semanage login -a -s staff_u -rs0 profile2
echo ""

read -p "--> semanage login -a -s staff_u -rs0 profile3"
echo ""
semanage login -a -s staff_u -rs0 profile3
echo ""

read -p "--> semanage login -l"
echo ""
semanage login -l
echo ""

read -p "--> sesearch -A -s staff_t -t usr_t -c file -p read"
echo ""
sesearch -A -s staff_t -t usr_t -c file -p read
echo ""

read -p "--> sesearch -A -s staff_t -t usr_t -c file -p write"
echo ""
sesearch -A -s staff_t -t usr_t -c file -p write
echo ""

read -p "--> chcat -l -- +c1 profile1"
echo ""
chcat -l -- +c1 profile1
echo ""

read -p "--> chcat -l -- +c3 profile2"
echo ""
chcat -l -- +c3 profile2
echo ""

read -p "--> chcat -l -- +c1,c3 profile3"
echo ""
chcat -l -- +c1 profile3
chcat -l -- +c3 profile3
echo ""

read -p "--> semanage login -l"
echo ""
semanage login -l
echo ""

# showtime!

read -p "--> ssh profile1@localhost"
echo ""
ssh profile1@localhost
echo ""

read -p "--> ssh profile2@localhost"
echo ""
ssh profile2@localhost
echo ""

read -p "--> ssh profile3@localhost"
echo ""
ssh profile3@localhost
echo ""

cat <<EOT >> /etc/selinux/targeted/setrans.conf
s0:c1=finance
s0:c3=marketing
EOT

systemctl start mcstransd

sleep 5

echo "Category numbers could be translated to human readable categories"

read -p "--> chcat -L"
echo ""
chcat -L
echo ""

read -p "--> ls -Z /opt/data/"
echo ""
ls -Z /opt/data/
echo ""

echo "Demo end."
echo "Clean up phase."

# clean up phase
rm -rf /opt/data

semodule -r local_demo &> /dev/null
rm -rf ./local_demo.cil

semanage login -d -s staff_u profile1
semanage login -d -s staff_u profile2
semanage login -d -s staff_u profile3

systemctl stop mcstransd

userdel -r profile1
userdel -r profile2
userdel -r profile3

head -n -2 /etc/selinux/targeted/setrans.conf > /etc/selinux/targeted/setrans.conf

