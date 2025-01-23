---
title: ufw vs  AWS Security Group
date: 2023-10-09 13:53:57
categories:
 - build website
tags:
 - build website
---

## 1. `ufw` command

### 1.1. Commonly used ufw commands

```shell
# ubuntu @ ip-172-31-12-228
$ sudo ufw status
Status: inactive
# ubuntu @ ip-172-31-12-228
$ sudo ufw enable
Command may disrupt existing ssh connections. Proceed with operation (y|n)? n
Aborted
```

> **Note:** use `sudo ufw enable` carefully, because it may disrupt your ssh connection. 

```shell
ufw enable: Enables the firewall, which starts enforcing the configured rules.
ufw disable: Disables the firewall, allowing all network traffic.
ufw status: Displays the current status of the firewall and the rules that are in effect.
ufw default allow: Sets the default policy to allow all incoming and outgoing traffic.
ufw default deny: Sets the default policy to deny all incoming and outgoing traffic.
ufw allow <port>: Opens a specific port for incoming traffic.
ufw deny <port>: Blocks incoming traffic on a specific port.

ufw delete <rule>: Deletes a specific rule from the firewall. 
# e.g., sudo ufw delete allow 80
```

### 1.2. `ufw app list`

```shell
# ubuntu @ ip-172-31-12-228
$ sudo ufw app list
Available applications:
  Nginx Full
  Nginx HTTP
  Nginx HTTPS
  OpenSSH
```

The output of `sudo ufw app list` only shows the available **application profiles**, not their actual status or whether they have been allowed or denied by `ufw`. It simply provides a list of predefined profiles **so that you can use conveniently** when configuring firewall rules. You don't need to remember which port for each application, you can simply use like this:

```shell
# sudo ufw allow 'Profile Name'
$ sudo ufw allow 'OpenSSH'
Rules updated
Rules updated (v6)
$ sudo ufw allow 'OpenS'  
ERROR: Could not find a profile matching 'OpenS'
```

 rather than 

```shell
sudo ufw allow 22
```

So the command below will allow both port `80` and `443`:

```
sudo ufw allow 'Nginx Full'
```

To check the status of your firewall rules and verify whether Nginx HTTP, Nginx HTTPS, or OpenSSH have been allowed or denied by `ufw`, you can use the `sudo ufw status` command. This command will display the current status of the firewall and the active rules.  

```shell
$ sudo ufw allow 'OpenSSH'
Rules updated
Rules updated (v6)

$ sudo ufw enable
Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup

$ sudo ufw status       
Status: active

To                         Action      From
--                         ------      ----
5060/udp                   ALLOW       Anywhere                  
OpenSSH                    ALLOW       Anywhere                  
5060/udp (v6)              ALLOW       Anywhere (v6)             
OpenSSH (v6)               ALLOW       Anywhere (v6)  

$ sudo ufw disable
Firewall stopped and disabled on system startup
```

## 2. Ubuntu Firewall (ufw) vs AWS Security Groups

A firewall like UFW is running at the OS level, while Amazon Security Groups are running at the instance level. Traffic coming into the EC2 would first pass through the SG, and then be evaluated by UFW.  

I strongly recommend you to use only "SG(Security Group)" on EC2 even though we can use both "SG" and "UFW. "SG" is a firewall same as "UFW".

When only "SG" allowed "SSH 22" and "UFW" didn't allow "SSH 22" then I logged out ubuntu, I couldn't log in to ubuntu forever, then I terminated ubuntu.

Even though "SG" allowed "SSH 22", I couldn't log in to ubuntu because "UFW" didn't allow "SSH 22". So if either of them doesn't allow "SSH 22", "SSH 22" doesn't work. If both "SG" and "UFW" allow "SSH 22", "SSH 22" works, then we can log in to ubuntu.

I also experimented with "HTTP 80". When only "SG" allowed "HTTP 80" and "UFW" didn't allow "HTTP 80", "HTTP 80" didn't work. When "SG" and "UFW" allowed "HTTP 80", "HTTP 80" worked.

Just remember like "If both allow, it works" and "If only either of them allow, it doesn't work". Actually, using both of them makes complication and some trobles. So again, I really recommend you to **use only "SG" on EC2** which is simpler than using both of them.

Source: https://stackoverflow.com/questions/57436758/does-ubuntu-ufw-overrides-amazon-ec2s-security-groups-and-rules