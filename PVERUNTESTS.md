## pveruntests

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

```ping```

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

If no output is expected, the expected result should be ```<>```.

The value of ```expect``` is evaluated using the ```[[ =~ ]]``` expression in bash, so
the value of ```expect``` is treated as a regular expression.

Bear in mind that when a test is run over a higher level protocol like http, the result will be the body
of the reply and it will not include any headers.

Examples:

```result=DTLS encrypted reply```

```result=<>```

### Notes on creating tests

**UDP tests**

Running udp tests can be tricky. In the background socat is being used for running the UDP test. It will
send out a packet and will wait for a timeout period for a reply. However, as UDP is connectionless,
recieving no packet is not seen as an error.
Using tests to validate a firewall is blocking traffing for UDP, it is best to define an actual UDP
service on one or more targets. Make the service return a value. When checking UDP set the ```result```
to ```ok``` and ```expect``` and empty (```<>```) result. That way, if  the firewall is not setup correctly
(either with a reject rule or allowing traffic) the test will fail, because the expected output is not
empty.

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

It is also possible to run specific tests, instead of everything:

```
pveruntests -c tests.ini test9 test10
```
