## PVE test environment

This is a set of scripts to convert a drawio network diagram to a set of Proxmox lxc
containers. It also includes a script to run defined tests in the created test environment.

These scripts are pretty bad, have loads of assumptions and the parsing of the drawio
diagrams often leads to errors. But it works for me :)

![terminal demonstration of pvete](pvete.svg)

## Features

The idea is to convert a network drawing made in drawio to a working set of lxc
containers. It currently has the following features:

* Conversion of drawio diagram to container creation commands (works sometimes) which converts the following information
  * System hostname
  * System IP address
  * Connected vlans, mapped to vmbr bridges
  * Configuration of default gateways
  * Configuration of routing tables
  * Creates shared storage between all containers
* Optional configuration of proxy access for package updates without additional network interfaces
* Exclusion of systems in the network diagram
* Automatic generation of /etc/hosts file based on nodes in drawing
* Container template generation based on DAB
  * Includes socat, iperf3, mtr, tcpdump and other useful test utilities
  * Embeds service that is started on boot

Next is the option to run tests against this environment. It has the following features:

* Define test cases in ini style config files with support for including other configuration files
* Tests can be defined as that the should fail or succeed (based on exit value of command) Aditionally a check can be done on the returned output.
* The following tests are available:
  * ping
  * tcp service
  * udp service
  * tls service
  * dtls service
  * http and https service
* The script will only generate output on failure.

For more information on the working of the scripts see:

* [pvete](PVETE.md)
* [pveruntests](PVERUNTESTS.md)
