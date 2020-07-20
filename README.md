# OneClickCDN
A one-click shell script to set up a CDN node for your websites.

## What does this script do?
* Build Traffic Server from source.
* Add website to CDN
* Install SSL certificates
* One-click free SSL certificates from Let's Encrypt
* Manage websites, view stats, purge caches
* So on...

## System requirement
* Ubuntu 20.04 LTS 64 bit or Debian 10 64 bit (experimental)
* 1 IPv4
* At least 512 MB RAM for running CDN instance
* For the very first time, building the program from source requires about 1.5 GB RAM.  You may add SWAP to your VPS for this step.
* Root access, or sudo user

## How to use
```
wget https://raw.githubusercontent.com/Har-Kuun/OneClickCDN/master/OneClickCDN.sh && sudo bash OneClickCDN.sh
```

## Contact me
You can open an issue here if there is any problem/bug when you use it.
For faster response, you can leave a message on this project webpage https://qing.su/article/oneclick-cdn.html

中文支持请访问 https://qing.su/article/oneclick-cdn.html

Thank you!

## Update log
* 07/19/2020        v0.0.1        Script created.
* 07/20/2020        v0.0.2        Added Debian 10 support; add systemd service.
