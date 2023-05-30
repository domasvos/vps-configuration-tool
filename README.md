# VPS Configuration tool
## _Tool to automate your CMS installations_

![my badge](https://badgen.net/badge/stable_version/1.1/)

Tool has necessary functions to start your first website using WordPress, Opencart or Prestashop without the need of manual configuration.

## Important
*Use VPS configuration tool at your own risk*
*I am not responsible if VPS configuration tool causes issues on your server*
*Make sure to backup your system before using the tool*

## Features

- Install WordPress, Opencart or Prestashop.
- Configure your Domain name for installed CMS.
- Install SSL certificate for your website.
- Install FileBrowser for easier file modification.
- Install Nginx or Apache2 web servers.

## Tech

Configuration tool uses a number of open source projects to work properly.

- [Certbot](https://certbot.eff.org/) - to install Let's Encrypt SSL certificates
- [File Browser](https://github.com/filebrowser/filebrowser) - tool for file modifcation
- [Remi's REM Repository](https://rpms.remirepo.net/) - for PHP installation on REHL systems.
- [Sury's Repository](https://deb.sury.org/) - for PHP installations on Debian systems.
- [node.js](https://nodejs.org/en) - for asset compiling of CMS software.
- [Composer](https://getcomposer.org/) - for library and dependency management of CMS.

VPS Configuration tool is written purely in **Bash**, therefore it takes care of all necessary tools mentioned above. 

*You will not need to install anything else yourself*.

## Requirements

Currently supported systems:
- Debian based systems
- Red Hat based systems

One of the package managers are installed(generally these are installed by default on above mentioned systems):
- apt
- yum
- dnf

## Installation

### Download VPS configuration tool to your server on which you want to create your website.

This can be done two ways - downloading zip and extracting or using git.
To download .zip file, you can use wget command, then unzip it and access the folder to start the tool.
```sh
wget https://github.com/domasvos/vps-configuration-tool/archive/refs/heads/develop.zip
unzip develop.zip
cd vps-configuration-tool-develop
```
As for git, you can use simple use *git clone* command, but for that you will need to download git.

- For Debian systems:
```sh
sudo apt-get install git -y
```
- For Rehl systems:
```sh
sudo yum install git -y
```
or
```sh
sudo dnf install git -y
```
Once installed, you can clone the repository:
```sh
git clone https://github.com/domasvos/vps-configuration-tool
cd vps-configuration-tool
```
--------------------
# Usage
This point describes how to use the VPS configuration tool.

Since it will be configurating the system, it needs sudoers access. To start the tool, you need to go into the folder that you downloaded, as mentioned earlier, and start start.sh script.
```sh
sudo bash start.sh
```
From there, you can enter numbers from 1 to 5 to choose which function you want to use.
#### 1. Installing CMS
Currently, with this tool, you can install one of these CMS:
- WordPress
- Opencart
- Prestashop

To choose CMS for installation you need to enter corresponding number from 1 to 3.
Once the CMS is chosen it will check all dependancies and install them if missing.
Then you will need to enter:
- Database information - the tool will create database for your website(make sure to remember it as it will be shown only once)
- Port - before you setup your domain name, your installed CMS will be accessible via your server's IP and chosen port.

After installation is completed, make sure to note your database details, follow the given URL and setup your website by creating administration details and filling all the necessary information to finalize the setup.

## 2. Configuring domain

#### Important
- For domain to work, it has to be pointed using DNS to your server's IP address, if you don't know how to do that, contact your domain's registrar.
- Domain cannot be added to any other website on the same server(you will get warning if that will be the case)

Once you choose this option, all you will need to do is enter your domain name:
- Enter without *https://* or *http://* part, **so if you want to setup domain *https://example.com/* you only need to enter *example.com***

Once domain is chosen the system will check if it is pointed, it will give warning if it is not pointed, but you can still proceed typing **y** or not proceed by typing **n**.

Then system will check if it already exists within the server, if so, you will need to remove domain from added virtualhost or choose a different one.

If domain is not added, it will configure virtualhost on existing web server and restart it.
You will be prompted with success message and you will be provided with the URL to access your website.

## 3. Installing File Browser

Once this option is chosen, you will need to choose path for which you want to setup File Browser, by default, the tool installs websites on */var/www/hmtl/* so this is set as default option for File Browser as well, once prompted with path, you can press **Enter** to use the default one.

**Important** - full path must be provided

You will also be prompted to choose a port, default port is **8080**. If you want to use the default one press **Enter**. Your server's IP address and chosen port will be used to access File Browser.

Once completed, you will be provided with File Browser URL.

## 4. Installing SSL

Once this option is chosen, tool will start with **Certbot** installation.
After that, tool will scan **Apache2/Httpd** or **Nginx** configuration files to find out what domain names are already configured.
It will prompt with possible choices and you will need to enter your domain name for which you want to install SSL certificate.
**You must enter the exact name displayed in the list so if example.com is displayed, you will need to enter example.com.**

After you will enter your domain, you will be prompted with several questions:
1. Your email address - required by Let's Encrypt
2. Terms of Services Agreement - required by Let's Encrypt
3. To force HTTPS - to redirects all traffic from HTTP to HTTPS. Recommended option 2, to redirect all traffic to HTTPS

Once that is done, installation is finalized and you will be provided with URL via HTTPS.

## 5. Installing Web Server

This option will appear only if you dont have pre-installed Web Server.
You will be able to choose from two options:
1. Apache2
2. Nginx

Recommended to read about each web server and decide which one is better for your use case.

# License

**Free Software**
