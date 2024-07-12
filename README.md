# Installation
```
yum install git gcc make cjson cjson-devel

firewall-cmd --permanent --add-port=1044/udp

firewall-cmd --permanent --add-protocol=igmp

firewall-cmd --reload

git -C /opt clone https://github.com/konradziczek/libvirttui-uftp.git /opt/uftp

/opt/uftp/setup.sh
```


# Updating
```
git -C /opt/uftp pull

/opt/uftp/setup.sh
```
