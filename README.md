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
  * icmp
  * tcp service
  * udp service
  * tls service
  * dtls service
  * http and https service
* The script will only generate output on failure.

## Example network drawing

The network drawing needs to conform to a number of conventions in order to make a chance to be converted.

* Networks should be drawn using the cloud icon
  * They content should alway have the name "vlanxxxx" where xxxx is the vlan number
  * Any lines below the vlanxxxx can be comments and will be ignored
* Hosts should be drawn using the rectangle icon
  * The content should always have to name of the host on the first line
  * Any lines below the name can be comments and will be ignored
  * A host drawn with a dashed line will not be created as a container
* Network connections should be drawn as lines connecting a host to a network
* IP addresses must be text linked to the line connecting a host to a network
  * IP addresses should always be in CIDR notation
  * The IP address can be appended by the letter gw (space separated) when the system is the default gateway for that network
* Routing tables should be drawn using the document icon
  * Routing tables should be connected with a line to a host
  * Routing tables should contain "ip r a" compatable syntax, without the "ip r a"
  * Each routing entry has to be on a separate line
* Services should be drawn using the process icon
  * Service syntax should be:
    * port/protocol where protocol can be:
      * tcp
      * udp
    * commands to generate output to return to the client
  * Each line in a process icon is a serivce
  * Services that are not connected to a specific host will be deployed on all hosts
  * Services linked to 1 or more hosts will only be deployed on those hosts
  * Services are started with socat and the commands are started with SYSTEM. The commands are quoted with double quotes (""), so it is best to use single quotes within specified commands (see example drawing).

A network drawing can look like this:

![Network drawing](testing.drawio.png "Network drawing")

## Configuration

In order for the drawing to be converted, the script needs a configuration file. The default name for
this configuration file is pvete.cfg and will be searched for in:
* Directory where the pvete script is located
* The homedirectory of the user, name of the configuration file will be prepended with a . (.pvete.cfg)

Additionally it is possible to change the name of the file and add the -c parameter to specify the name.

It is possible to have multiple configuration files in order to deploy multiple environments.

The example configuration file should be fairly obvious. A few options need further explanation.

CTSERVER

This is the Proxmox server that should be used to deploy the containers on. Make sure this system is
reachable by ssh and when doing so the login will be as root from the user running the script. Any
specific requirements to do this should be added to a ```~/.ssh/config``` file.

CTSHARED

This is a directory location on the Proxmox server that the script may create. This directory will be used
to store configuration information and scripts for all containers. It is shared between the containers
using a mountpoint.

CTTEMPLATE

This is the name of the template to use when creating a container. The create has an option to create the
template using DAB. This takes care of the requirements that are needed in the containers to make the
environment run smoothly.

PROXY

If set, the containers will be deployed to use the specified proxy for apt. The proxy should be reachable
from the configurated Proxmox server. The containers will not access the proxy directly, all connectivity
will run via the Proxmox server.

BRIDGE

Every network interface for a container will be assigned to a bridge. The vlan in the drawing will be used
as the vlan tag for the bridge. So the bridge should be vlan aware.
When integration the test environment with additional existing hosts, it can be useful to assign vlans to
specific bridges (existing hosts can then use vlan tagging).
There should always be a default bridge defined, so something like:
```
BRIDGE[default]="vmbr1000"
```
If specific vlans should not be assigned to the default bridge, additional configuration lines can be added,
mapping the vlans to a different bridge
```
BRIDGE[vmbr1001]="vlan200 vlan201 vlan202"
```

## Deploying

Once a drawing is available and the configuration file has been made, deploying is quite easy (if it works).

```
pvete deploy testing.drawio
```

The script tries to read the drawing, generates all commands to run and runs the commands. After it is
finished, the containers should exist on the Proxmox server and should be running.

## Modifying

In larger test environment, destroying and re-deploying can take a lot of time. In order to try to minimize
the time to make modifications to the testenvironment, a modify option is available. This option will analyze
the supplied drawing and tries to detect the changes between it and the currently deployed environment.

Currently it should detect and modify:
* New or removed hosts
* Changed IP addresses
* New, removed or changed global or specific services
* New, removed or changed routing tables

The modify option will not try to modify a container configuration. If a change in the container configuration
is detected, the container will be removed and re-created.

With changed services or routes, only the containers affected by the change will be restarted.

The repository contains a ```testing-modified.drawio``` drawing which has the following modifications compared to the
```testing.drawio``` drawing:
* add node1
* remove client2
* change ip client1 in vlan102
* remove node3 service 9001/tcp
* remove node2 service 9000/tcp + 53/udp
* add router1 service 9000/tcp + 53/udp
* remove global service 443/dtls

After the environment in ```testing.drawio``` is deployed, modifications can be deployed through:

```
pvete modify testinng-modified.drawio
```

## Using the environment

The script provides a number of options to more easily manage the containers. But it is not mandatory to use
the script, the normal Proxmox commands can also be used.

The script tries to make it easier to quickly run commands in all containers, stop or start them all and
access a container based on the name of the container instead of the Proxmox container id.

## Testing services deployed with drawing testing.drawio

```
pvete enter node3
```

UDP
```
root@node3:~# echo input | socat -T1 udp:node2-vlan100:53 -
testing
```

DTLS
```
root@node3:~# echo input | socat -T1 openssl-dtls-client:node2-vlan100:443,verify=0 -
DTLS encrypted reply
```

TCP
```
root@node3:~# telnet node2-vlan100 9000
Trying 10.10.0.2...
Connected to node2-vlan100.
Escape character is '^]'.
HTTP/1.0 200 OK

Hello this is a test
Connection closed by foreign host.
```

TLS
```
root@node3:~# unset https_proxy
root@node3:~# curl -k https://node2-vlan100
Result output
```
## Automatic testing of the environment

The script ```pveruntests``` is provided in order to assist with automating tests in a deployed environment. The script uses a
configuration file to read the tests, and will process them. It will show all tests that are incorrect.

### Test configuration

The configuration is done in ```.ini``` style file format.

Any line that is empty or starts with a ```#``` will be ignored.

#### Including files

In order to make it possible to split large amounts of tests over multiple files, it is possible to include files. This can
be done through the ```include``` statement. This can be anywhere in the file. Any ```include``` statement will insert the
tests at that place (in case order is important). This looks as follows:

```
include=/tests/webservers.ini
```

#### Tests

A test is a section in the ```.ini``` file. The name should not include spaces and should be unique (also when including
other files).

There are multiple options available within each test:

**from (required)**

This option refers to the host the test needs to be run from. This is the lxc container name as specified in
the deployed network drawing (without any network indication).
For example:

```from=node2```

**to (required)**

This option refers to the network name the connection needs to be made to. This is the name of the lxc
container as specified in the deployed network drawing, combined with the vlan it is connected to.
For example:

```to=node3-vlan100```

**service (required)**

This option is the service that needs to be connected to. There are multiple options:

```icmp```

This will run a ping test to the destination.

```<port>/tcp```

This will connect to the specified port number over tcp.

```<port>/udp```

This will connect to the specified port number over udp.


```<port>/tls```

This will connect to the specified port number over tls (without certificate verification).


```<port>/dtls```

This will connect to the specified port number over dtls (without certificate verification).

```<port>/http```

This will connect to the specified port number over http.

```<port>/https```

This will connect to the specified port number over https (without certificate verification).

An example of this looks like:

```service=443/tls```

**result (required)**

This refers to the exit code of the command. If the result matches the result of the command the test
will be successful.

A value of ```ok``` means the command should have an exit code of 0.

A value of ```fail``` means the command should have an exit code of not 0.

An example:

```result=fail```

**expect (optional)**

This specifies a value that should be recieved over the tested connection. This is in addition to the
```result``` parameter and ```expect``` will only be evaluated when the ```result``` is as expected.

If an expected result is spread over multiple lines, a newline character can be included in the result. Make
sure to double escape it (```\\n```).

Bear in mind that when a test is run over a higher level protocol like http, the result will be the body
of the reply and it will not include any headers.

An example:

```result=DTLS encrypted reply```

### Running tests

The script provides for parallellism. Especially when tests are meant to fail, it can result in longer test
times because of the wait for timeouts. Parallellism can really improve test duration.

Included is an example ```tests.ini``` file which has tests that can be ran against a deployed ```testing.drawio``` environment:

```
pveruntests -c tests.ini
```

This shoud result in 2 tests that fail, tests error and test4:

```
[error]: Unknown service fakeservice
[test4]: test failed, should succeed (output: firewall-vlan102 : xmt/rcv/%loss = 2/0/100%)
```

Default it will run tests with a parallellism of 2, but this can be easily increased, for example to 4:

```
pveruntests -j 4 -c tests.ini
```

## Cleaning up

Removing the containers can be done manually (but this will leave the shared directory and possibly the
proxy systemd unit file if a proxy is configured). The pvete script provides in a cleanup action which
will remove all containers, the shared directory and the systemd unit file.

```
pvete destroyall
```
