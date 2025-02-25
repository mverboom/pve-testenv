## PVE test environment

This is a set of scripts to convert a drawio network diagram to a set of Proxmox lxc
containers.

These scripts are pretty bad, have loads of assumptions and the parsing of the drawio
diagrams often leads to errors. But it works for me :)

## Features

The idea is to convert a network drawing made in drawio to a working set of lxc
containers. It currently has the following features:

* Conversion of drawio diagram to container creation commands (works sometimes) which converts the following information
** System hostname
** System IP address
** Connected vlans, mapped to vmbr bridges
** Configuration of default gateways
** Configuration of routing tables
** Creates shared storage between all containers
* Optional configuration of proxy access for package updates without additional network interfaces
* Exclusion of systems in the network diagram
* Automatic generation of /etc/hosts file based on nodes in drawing
* Container template generation based on DAB
** Includes socat, iperf3, mtr, tcpdump and other useful test utilities
** Embeds service that is started on boot
