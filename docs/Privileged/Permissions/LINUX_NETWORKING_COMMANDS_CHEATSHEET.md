# Linux Networking Tools Cheat Sheet

Rationale
- Practical, function‑grouped commands for interface, monitoring, DNS, firewall, wireless and transfer.
- Highlights modern successors (ip, ss, iw, nftables) and keeps legacy references for triage.
- Android‑compatible where possible; non‑root commands marked by default.

## Interface Management
| Command  | Description | Example |
|---|---|---|
| ip | Modern utility for IP, routes, links | `ip addr show` |
| iproute2 | Advanced routing/tc suite | `ip link show` |
| ifconfig | Legacy interface tool | `ifconfig` |
| iw | Modern wireless control | `iw dev wlan0 link` |
| iwconfig | Legacy wireless | `iwconfig` |
| ethtool | NIC parameters | `ethtool eth0` |
| ifenslave | Link aggregation | `ifenslave bond0 eth0 eth1` |
| nmcli | NetworkManager CLI | `nmcli connection show` |
| dhclient | DHCP client | `dhclient -v eth0` |
| route | Legacy routing table | `route -n` |

## Diagnostics & Monitoring
| Command  | Description | Example |
|---|---|---|
| ping | Reachability | `ping -c 4 8.8.8.8` |
| traceroute | Hop path | `traceroute example.com` |
| mtr | Live traceroute+ping | `mtr -rw example.com` |
| ss | Socket stats (modern) | `ss -ltnp` |
| netstat | Legacy sockets | `netstat -an` |
| tcpdump | Packet capture | `tcpdump -i eth0` |
| ngrep | Pattern grep in traffic | `ngrep -d eth0 'HTTP'` |
| iftop | Per‑conn bandwidth | `iftop` |
| nload | IO monitor | `nload` |
| arp, arp-scan, arpwatch | ARP tools | `arp -a` |
| iperf3 | BW tests | `iperf3 -s` / `iperf3 -c host` |
| hping3 | Crafted packets | `hping3 -S -p 80 host` |
| dnstracer | DNS path | `dnstracer example.com` |

## DNS / Name Resolution
| Command  | Description | Example |
|---|---|---|
| dig | Rich DNS query | `dig +dnssec example.com` |
| host | Simple resolver | `host example.com` |
| nslookup | Legacy | `nslookup example.com` |
| dnsmasq | Local DNS/DHCP | `systemctl restart dnsmasq` |

## Socket & Connection
| Command | Description | Example |
|---|---|---|
| nc / ncat | TCP/UDP IO, port checks | `nc -vz host 443` / `ncat -l 1234` |

## Firewall & Filtering
| Command | Description | Example |
|---|---|---|
| nftables | Modern packet filter | `nft list ruleset` |
| iptables | Legacy firewall | `iptables -L -n` |
| iptables-save/restore | Persist | `iptables-save > /root/iptables.rules` |
| ipset | Address sets | `ipset list` |

## Wireless & AP
| Command | Description | Example |
|---|---|---|
| hostapd | Software AP | `hostapd /etc/hostapd/hostapd.conf` |

## Transfer & Remote Access
| Command | Description | Example |
|---|---|---|
| ssh/sshd | Secure shell | `ssh user@host` / `systemctl status ssh` |
| scp | Copy over SSH | `scp file user@host:/path` |
| wget | HTTP(S) fetch | `wget https://example.com` |
| curl | URL transfer | `curl -I https://example.com` |

## Address/Network Calculation
| Command | Description | Example |
|---|---|---|
| ipcalc | IP math | `ipcalc 10.0.0.1/24` |

References
- /reference vault (modern vs legacy tools, nftables/ipset recipes, tcpdump patterns)
- Debian/Ubuntu Network Docs, iproute2, nftables wiki, tcpdump.org, curl manual