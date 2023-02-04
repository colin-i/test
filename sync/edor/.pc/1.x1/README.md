# EDitOR

## Install
On Ubuntu, but other distros may have the same tree and dependencies.\
Architecture: amd64 arm64 armhf
```sh
sudo add-apt-repository ppa:colin-i/ppa
```
Or the *manual installation step* from this link *https://gist.github.com/colin-i/e324e85e0438ed71219673fbcc661da6* \
Install:
```sh
sudo apt-get install edor
```

## From source
Use autoconf automake libncurses-dev ; on armv7l(alias arm) cpu, libunwind-dev
```sh
autoreconf -i
./configure
make install
```
Use *\-\-prefix=your_path* at *./configure* if needed (example: at Termux in Android).\
*\-\-disable\-cpp* to set c rules.\
Or, for some 64-bit platforms:
```sh
make -f Makefile.old
```
Uninstall command is *make uninstall*.

## Donations
The *donations* section is here
*https://gist.github.com/colin-i/e324e85e0438ed71219673fbcc661da6*
