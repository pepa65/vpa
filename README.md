# ![vpa](https://raw.github.com/pepa65/vpa/master/logo.png)
[Gitlab ![Gitlab pipeline](https://gitlab.com/pepa65/vpa/badges/master/pipeline.svg)](https://gitlab.com/pepa65/vpa/-/pipelines)
[![GitHub CI status](https://github.com/pepa65/vpa/workflows/CI/badge.svg)](https://github.com/pepa65/vpa/actions)
![CodeQL scan](https://github.com/pepa65/vpa/workflows/CodeQL%20scan/badge.svg)

**vpa - Virtual Private Access: a dead simple VPN that just gives a client encrypted access to the server's internet**

v0.3.1 <!-- Set in `include/vpn.h` -->

```text
[client]---(encrypted tunnel)---[server]---(internet)
```

Both the VPN server and client have the same tiny single-binary application that can be compiled for all platforms.
The only thing that is needed to establish a VPN connection is to have the binary present on both the server and
the client, and to have the same 32-byte keyfile present on both sides.

## Features
* Over TCP, so works pretty much everywhere, including on public wifi with only TCP port 443 open/available.
* Uses only modern cryptography, with formally verified implementations: [charm](https://github.com/jedisct1/charm).
* Small and constant memory footprint, no heap memory allocations.
* Small single-binary (~35 kB or ~15 kB compressed), with a small and readable code base without external dependencies.
* Works out of the box: No lousy documentation to read. No configuration file. No post-configuration.
* Runs with a single command on the server, and a single command on the client. No firewall or routing rules to mess with manually.
* Works on Linux (kernel >= 3.17), macOS and OpenBSD, as well as DragonFly BSD, FreeBSD and NetBSD in client and point-to-point modes.
  Adding support for other operating systems is trivial.
* Doesn't leak between reconnects if the network doesn't change. Blocks IPv6 on the client to prevent IPv6 leaks.
* It does require shell commands to be present in the PATH: `awk`, `sysctl`, `iptables`, `ip` (linux) or `route` (OSX/BSDs).

The code of `vpa` is cloned from [dsvpn](https://github.com/jedisct1/dsvpn) and mainly the user interface (CLI) is modified to make it even easier to run. Apart from that it is fully compatible. All praise to [Frank Denis](https://github.com/jedisct1)!

## Why
* Using TCP (most VPNs use UDP to not get bogged down, but with `BBR` congestion is minimal).
* Over any accessible port (ports `80` and `443` are usually available).
* Fully tunneled.
* Cryptographically secure.
* Simple install: single binary.
* Simple configuration: no configuration file.
* Simple usage: only the keyfile needs to be placed on server and clients.

## Installation
Download the [amd64/x86_64 binary](https://gitlab.com/pepa65/vpa/-/jobs/artifacts/master/raw/vpa?job=building)
or clone the repository with:

`git clone https://gitlab.com/pepa65/vpa`

`cd vpa`

### Make
Build it with:

`make`

On Raspberry Pi 3 & 4, build it like this to enable NEON optimizations:

`make mfpu=neon`

The routing rules are all automatically set up when run, and torn down when exited. To make `vpa` operate without setting up
routing rules, build the binary with:

`make NO_DEFAULT_ROUTES=1`

Install with:

`sudo make install`

### Zig build
Alternatively, if you have [zig](https://ziglang.org) installed (0.12 or later), it can be used to compile `vpa`:

`zig build -Drelease`

(Without `-Drelease` the binary is a lot bigger, but that works too.)

For static linking against musl (no GLIBC version problems on older Linux distros):

`zig build -Drelease -Dtarget=x86-linux-musl`

The binary ends up in `zig-out/bin/vpa`.

## Make and copy secret key
`vpa` uses a shared secret. The keyfile can be any file of at least 32 bytes.
A random keyfile can be created with:

`dd if=/dev/urandom of=vpa.key count=1 bs=32`

Put the same key on the server and the client. If needed, the key can be exported & imported in printable form.

Output copiable form:

`base64 <vpa.key`

At the other machine do (paste the copied base64 form of the key between the quotes!):

`echo '' |base64 --decode >vpa.key`

A file `vpa.key` in the current directory will be used as the secret key, or in absence of that, the one in the user's home.
A keyfile can be specified on the commandline which always takes priority.

## Running
### Run the server
`sudo vpa --server`

`sudo vpa -s - 12345`

The first example uses port `443`, the default (in case `443` is already taken, `444` is tried).
The second example specifies port `12345`, and everything else is set to the default values.

### Run the client
`sudo vpa my.doma.in`

If a port different than `443` (or `444`) needs to be used, specify it after the server's IP or hostname.

#### Start client as a service
To start the client automatically on bootup, a `systemd` service unit can be used where applicable.
In `/etc/systemd/system/vpa-client.service` put the following
(replace `HOST` with the server's hostname or IP address!):

```
[Unit]
Description=Virtual Private Access VPN Server

[Service]
ExecStart=/usr/local/bin/vpa HOST

[Install]
WantedBy=network.target
```

#### Warning about DNS on the client
If the client was using a DNS resolver that's only accessible from the local network, it will no longer be accessible through the VPN.
That would be the only issue that needs to be worked around. Use a public resolver, a fully local resolver, or DNSCrypt.

### That's it
Once both the server and the client are started, the encrypted connection is established and the routing is arranged.
To disconnect, hit `Ctrl-C` on either the client or the server.

## Start server as a service
To start the server automatically on bootup, a `systemd` service unit can be used where applicable.
In `/etc/systemd/system/vpa.service` put the following:

```text
[Unit]
Description=Virtual Private Access VPN Server

[Service]
Environment="HOME=/root"
ExecStart=/usr/local/bin/vpa --server
Restart=always
RestartSec=10

[Install]
WantedBy=network.target
```

(Assuming the `vpa.key` file is in /root, otherwise the Environment can be adjusted.)
It can then be enabled (needed only once) and started by:

`systemctl enable --now vpa.service`

## Full & advanced configuration
```text
vpa v0.3.0 - Virtual Private Access: a Dead Simple VPN

Client:  vpa <server> [<port> <serverIP> <clientIP> <gwIP> <keyfile>]
Server:  vpa -s|--server [<IP> <port> <serverIP> <clientIP> <gwIP> <keyfile>]

Client:
  <server>:     Mandatory: the IP or hostname of the VPN server to connect to.
  <port>:       The port served on (default: 443, fallback to 444).
Server:
  -s|--server:  Run as VPN server (if not given: run as client).
  <IP>:         The IP address the server listens on (default is all: 0.0.0.0).
  <port>:       The server port to connect to (default: 443).
Common:
  <serverIP>:   The server-side tunnel IP (default: 10.11.12.1).
  <clientIP>:   The client-side tunnel IP (default: 10.11.12.13).
  <gwIP>:       The gateway IP to tunnel through (default: from routing table).
  <keyfile>:    Shared secret (default: ./vpa.key with fallback to ~/vpa.key).
All arguments are position-sensitive, and when marked with '-' or left off
(on the right hand side), they will take their default values.
```

* Use `-s` or `--server` for the server.
* The server listens on all interfaces by default, or can be limited to the IP address given in `<IP>`.
* If no port is given, the server will try to start on `443`, and fall back to `444` if `443` is in use.
* For the client, `<server>` must be specified: the IP address or hostname of the VPN server.
* `<port>`: The TCP port to use for the VPN, `443` by default, or `444` if that is taken.
* `<serverIP>`: Server IP address of the tunnel. The client and server tunnel IPs must be the same on the client and on the server.
  Use any **private** IP address subnet (`10.*.*.*`, `172.16-31.*.*`, `192.168.*.*`) here that is not in use, default `10.11.12.1`.
* `<clientIP>`: Client IP address of the tunnel, default `10.11.12.13`.
* `<gwIP>`: The gateway IP address to tunnel through, by default as shown by: `ip r show default`.
* `<keyfile>`: Path to the file with the secret key, can be left off if it is `./vpa.key` or if that is not present: `~/vpa.key`.
* Some of the output goes to stdout and some to stderr... Only the server's stderr output is used for fail2ban.
