How to verify iptables tool

**On D02**
iptables -A INPUT -s <172.18.45.13> -j REJECT  -> set the rule to reject the packets 
iptables -L -> shows the added rule

**Where**
172.18.45.60 - ip address of D02 board and
172.18.45.13 - ip address of the PC.
 
**On PC**
ping <172.18.45.60> -> unreachable as packets are rejected based on above iptables rule.

**On D02**
iptables -D INPUT 1 -> delete the rule.

iptables -A INPUT -s <172.18.45.13> -j ACCEPT  -> set the rule to accept the packets 
iptables -L -> shows the added rule

**ON PC**
ping <172.18.45.60> -> work ok as packets are accpeted.
