---
title: Commands Commonly Used in Linux
date: 2024-08-05 12:40:56
categories:
 - linux
tags:
 - linux
---


```bash
$ scp -rp tls/* root@86.150.206.117:/root/tls/
$ nohup ./server -p 8080 &

$ uname -a # Displays all system information (kernel, hostname, version, etc.).
$ file server 
$ otool # macOS tool for examining object files and executables.
$ xxd main.class # Display the contents in hexadecimal format.

$ chmod +x test.sh
$ ipconfig getifaddr en0  # check your ip on Mac

$ find themes/source/css -name "*header*" -type f
$ grep -nr 'ul$' themes/source/css  # n: line number, r: recursive

$ git log --all --decorate --oneline --graph # "A Dog" 
```

## 1. File System

```bash
$ ls -lh folder_name
```

> `-l` means "long listing format":
>
> It displays detailed information about each file or directory, including: File permissions, Number of links, Group, File size, Last modification date/time. 
>
> `-h`: human-readable file sizes (e.g., 1K, 234M, 2G)

---

```bash
$ df -lh
```

>`df`: disk filesystem.
>
>- `-l` means "local file systems only": It limits the output to local file systems, excluding any network or special file systems. 

---

```bash
$ du  -sh  *
```

> `du`: disk usage.
>
> - `-s`: stands for "summarize". It tells `du` to display only a total for each argument (each item (folder, file) in the current directory).
>
> Without `-s`:
>
> ```bash
> $ du -h downloads
> 4.0K    downloads/file1.txt
> 8.0K    downloads/videos/learn.mp4
> 12K     downloads/videos/bbc.mp4
> ...
> ```
>
> With `-s`:
>
> ```bash
> $ du -sh downloads
> 16K     downloads
> ```
> 

---


## 2. Monitor Commands

```bash
$ netstat -anp
$ lsof -n -i # on OSX
COMMAND    PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
Arc 1269 David   21u  IPv4 0x91c91fd81e559      0t0  UDP 192.168.2.15:50307->142.251.35.174:https
```

> `netstat`: Displays network connections, routing tables, interface statistics...
>
> - `-a`: Shows all connections and listening ports.
> - `-n`: Inhibits the conversion of network numbers to host names.
> - `-p`: Shows the PID and name of the program to which each socket belongs.
>
> `lsof -n -i` (macOS/OSX):
>
> - `lsof`: Lists open files. In Unix-like systems, everything (including network connections) is treated as a file.
>
> - `-n`: Inhibits the conversion of network numbers to host names.
>
> - `-i`: Selects the listing of files any of whose Internet address matches the address specified. If no address is specified, this option selects all Internet and network files.

You can also use `ps aux` to find a specific process by name, then use `netstat` to find the ip and port of the process. 

e.g., you can use `netstat -anp | grep 8080` to find the PID of the process, so that you can kill it by `kill PID`.

---

```bash
$ ps aux
```

> `ps`: short for Process Status (PID: Process ID, COMMAND: The command with all its arguments). 
>
> - `a`: Show processes for all users, not just the current user.
> - `u`: Display the process's user/owner.
> - `x`: Also show processes not attached to a terminal.

e.g., you can use `ps aux | grep ./server` to find the PID of `./server` process, so that you can kill it by `kill PID`.

---

```bash
$ systemctl list-units
$ systemctl list-units --type=service
$ systemctl start <service-name>

$ brew services list
$ brew services start mongodb-community
```

> `systemctl` is a command-line tool used to manage services on Linux systems that use systemd*. For services like Apache2, Nginx, and MySQL, `systemctl` allows you to: start, stop, and restart services. 
>
> *Note: Systemd is a modern init system^ and system management daemon designed for Linux.
>
> ^Note: An init system is the first process started during boot in Unix-like operating systems. It initializes the system and manages services. 

> Systemd manages services running in the background (often called daemons). This includes starting, stopping, restarting, and monitoring the status of services.
>
> But systemd actually does more than just manage services:
>
> - Managing system state (like shutdown, reboot)
> - Mounting filesystems
> - Logging system events

## 3. Network Tools

```shell
# -O write documents to FILE: download the file and save it into install.sh
wget -O install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
# The hyphen after -O tells wget to output the downloaded content to stdout (standard output) instead of saving it to a file.
wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

# -q quiet, same as above but output nothing
wget -qO install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

# -c flag tells the shell to read commands from the string that follows it.
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

```shell
$ dstat
You did not select any stats, using -cdngy by default.
--total-cpu-usage-- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai stl| read  writ| recv  send|  in   out | int   csw
  0   0  99   0   0|  30B  536B|   0     0 |   0     0 |  53    94
  2   1  97   0   0|   0     0 |3089B 4156B|   0     0 |  95   238
  3   1  95   0   1|   0     0 |5654B 4804B|   0     0 | 111   234
```

> Test real time network IO and disk IO
>
> - `-n` option stands for "network"
>
> - `-d` option stands for "disk" or "device"

---

```shell
iperf3 -s -p 5202 # server

iperf3 -c server_ip_address -p 5202 # test the upload speed (client upload to server)
iperf3 -c server_ip_address -p 5202 -R # test the download speed (client download from server)
```

> `speedtest-cli` and `iperf3`: speedtest-cli measures speeds to public servers, reflecting general internet performance to the user; iperf3 can perform tests between any two points, ideal for real performance between your local machine and remote server. 
>
> So there is no suprise that the result of `iperf3` is different from `speedtest-cli`, usually quite slower than the result `speedtest-cli`. 

