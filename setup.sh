#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "ERROR: Script must be run as root."
    exit 1
fi


if [[ ! "$0" == "/opt/uftp/setup.sh" ]]; then
    echo "ERROR: /opt/uftp does not exist - did you clone repository in this path?"
    exit 1
fi


if ! grep -q "Rocky Linux 9" /etc/os-release; then
    echo "ERROR: This software runs only on Rocky Linux 9."
    exit 1
fi


if ! which gcc &>/dev/null; then
    echo "ERROR: gcc is not installed."
    exit 1
fi


if ! which make &>/dev/null; then
    echo "ERROR: make is not installed."
    exit 1
fi


if ! rpm -q "cjson" &>/dev/null; then
    echo "ERROR: Package cjson is not installed."
    exit 1
fi


if ! rpm -q "cjson-devel" &>/dev/null; then
    echo "ERROR: Package cjson-devel is not installed."
    exit 1
fi

echo -n "Creating user... "
if ! grep -q "^uftp:" /etc/passwd; then
    useradd -d /opt/uftp --system uftp
    echo "OK"
else
    echo "ALREADY EXISTS"
fi


echo -n "Preparing uftp... "

killall -q -r uftpd
rm -r -f /opt/uftp/uftp
tar -C /opt/uftp -zxvf /opt/uftp/uftp-5.0.3.tar.gz >/dev/null
mv /opt/uftp/uftp-5.0.3 /opt/uftp/uftp

sed -i 's/^LDLIBS=/LDLIBS=-lcjson /' /opt/uftp/uftp/makefile
sed -i 's/^client_announce.o:/image_file_accepted.o: image_file_accepted.c image_file_accepted.h client.h\nclient_announce.o:/' /opt/uftp/uftp/makefile
sed -i 's/^UFTPD_OBJS=/UFTPD_OBJS=image_file_accepted.o /g' /opt/uftp/uftp/makefile

sed -i 's/^\#include \"client_transfer.h\"/\#include \"client_transfer.h\"\n\n\#include \"image_file_accepted.h\"/' /opt/uftp/uftp/client_fileinfo.c
sed -i 's/^        if (skip) {/        if (!image_file_accepted(group)) { skip = 1; }\n        if (skip) {/' /opt/uftp/uftp/client_fileinfo.c

cp /opt/uftp/assets/image_file_accepted.c /opt/uftp/uftp/
cp /opt/uftp/assets/image_file_accepted.h /opt/uftp/uftp/

if ! make -C /opt/uftp/uftp &>/dev/null; then
    echo "ERROR: make did not return 0"
    exit 1
fi

echo "OK"


echo -n "Setting up crontab... "

touch /opt/uftp/uftp_client.log

if ! grep -q "uftp_client" /etc/crontab; then
    echo '*/5 * * * * uftp /opt/uftp/uftp_client.sh > /dev/null' >> /etc/crontab
fi

echo "OK"


echo -n "Running chmods and chowns... "

chown -R uftp:uftp /opt/uftp
chown -R root:uftp /opt/virt_data/images

chmod 700 /opt/uftp
chmod -R 775 /opt/virt_data/images

echo "OK"
