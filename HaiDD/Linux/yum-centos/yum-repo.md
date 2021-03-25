# Chỉ định mirror khi sử dụng yum

## 1. Tìm 1 mirror muốn sử dụng:
Ví dụ ở đây là: 
```
http://mirrors.nhanhoa.com/centos/
```

## 2. Sửa file `/etc/yum.repos.d/CentOS-Base.repo`
Comment các dòng `mirrorlist=...`

Thay đường link đúng cho các dòng `baseurl=...`

File `/etc/yum.repos.d/CentOS-Base.repo`:
```yaml
[base]
name=CentOS-$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
baseurl=http://mirrors.nhanhoa.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
baseurl=http://mirrors.nhanhoa.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
baseurl=http://mirrors.nhanhoa.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
baseurl=http://mirrors.nhanhoa.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
```

## 3. Vô hiệu hóa plugin fastestmirror
Plugin fastestmirror sẽ thực hiện tìm kiếm mirror gần chúng ta nhất, nên cần vô hiệu hóa nó đi.

Sửa file ` /etc/yum/pluginconf.d/fastestmirror.conf`: Set giá trị `enabled = 0`
```yaml
[main]
enabled=0
...
```

## 4. Clean cache
```
yum clean all
```

Kiểm tra:
```
yum repolist -v
```
Output:
```
pkgsack time: 0.014
Repo-id      : base
Repo-name    : CentOS-7 - Base
Repo-revision: 1604001756
Repo-updated : Fri Oct 30 03:03:00 2020
Repo-pkgs    : 10,072
Repo-size    : 8.9 G
Repo-baseurl : http://mirrors.nhanhoa.com/centos/7.9.2009/os/x86_64/
Repo-expire  : 21,600 second(s) (last: Thu Mar 25 17:06:14 2021)
  Filter     : read-only:present
Repo-filename: /etc/yum.repos.d/CentOS-Base.repo

Repo-id      : epel/x86_64
Repo-name    : Extra Packages for Enterprise Linux 7 - x86_64
Repo-revision: 1616637375
Repo-updated : Thu Mar 25 09:05:18 2021
Repo-pkgs    : 13,565
Repo-size    : 16 G
Repo-metalink: https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=x86_64&infra=stock&content=centos
  Updated    : Thu Mar 25 09:05:18 2021
Repo-baseurl : http://epel.mirror.angkasa.id/pub/epel/7/x86_64/ (52 more)
Repo-expire  : 21,600 second(s) (last: Thu Mar 25 17:06:17 2021)
  Filter     : read-only:present
Repo-filename: /etc/yum.repos.d/epel.repo

Repo-id      : extras
Repo-name    : CentOS-7 - Extras
Repo-revision: 1616164746
Repo-updated : Fri Mar 19 21:39:07 2021
Repo-pkgs    : 460
Repo-size    : 799 M
Repo-baseurl : http://mirrors.nhanhoa.com/centos/7.9.2009/extras/x86_64/
Repo-expire  : 21,600 second(s) (last: Thu Mar 25 17:06:17 2021)
  Filter     : read-only:present
Repo-filename: /etc/yum.repos.d/CentOS-Base.repo

Repo-id      : updates
Repo-name    : CentOS-7 - Updates
Repo-revision: 1616164499
Repo-updated : Fri Mar 19 21:35:17 2021
Repo-pkgs    : 1,898
Repo-size    : 9.6 G
Repo-baseurl : http://mirrors.nhanhoa.com/centos/7.9.2009/updates/x86_64/
Repo-expire  : 21,600 second(s) (last: Thu Mar 25 17:06:17 2021)
  Filter     : read-only:present
Repo-filename: /etc/yum.repos.d/CentOS-Base.repo
```