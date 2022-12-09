# ![vpa](https://raw.github.com/pepa65/vpa/master/logo.png)
[![GitHub CI status](https://github.com/pepa65/vpa/workflows/CI/badge.svg)](https://github.com/pepa65/vpa/actions)
[![Travis CI status](https://api.travis-ci.org/pepa65/vpa.svg?branch=master)](https://travis-ci.org/pepa65/vpa)
![CodeQL scan](https://github.com/pepa65/vpa/workflows/CodeQL%20scan/badge.svg)

**vpa - Virtual Private Access: a dead simple VPN that just gives a client encrypted access to the server's internet**

```text
[client]----(encrypted link)----[server]----(internet)
```

Features:

* Over TCP, so works pretty much everywhere, including on public wifi with only TCP port 443 open/available.
* Uses only modern cryptography, with formally verified implementations: [charm](https://github.com/jedisct1/charm).
* Small and constant memory footprint, no heap memory allocations.
* Small single-binary (~35 kB or ~15 kB compressed), with a small and readable code base without external dependencies.
* Works out of the box: No lousy documentation to read. No configuration file. No post-configuration.
* Runs with a single command on the server, and a single command on the client. No firewall or routing rules to mess with manually.
* Works on Linux (kernel >= 3.17), macOS and OpenBSD, as well as DragonFly BSD, FreeBSD and NetBSD in client and point-to-point modes. Adding support for other operating systems is trivial.
* Doesn't leak between reconnects if the network doesn't change. Blocks IPv6 on the client to prevent IPv6 leaks.

## Installation

Build it with: `make`

On Raspberry Pi 3 & 4, build it like this to enable NEON optimizations:

`env OPTFLAGS=-mfpu=neon make`

Alternatively, if you have [zig](https://ziglang.org) installed, it can be used to compile `vpa`:

`zig build`

<!--On macOS, `vpa` can be installed using Homebrew: `brew install vpa`.-->

## Make and copy secret key

`vpa` uses a shared secret, create it with: `dd if=/dev/urandom of=vpa.key count=1 bs=32`

Put the same key on the server and the client. If needed, the key can be exported & imported in printable form.

Output copiable form: `base64 <vpa.key`

At the other machine do: `echo '(base64 form of key)' |base64 --decode >vpa.key`

## Example usage on the server

`sudo vpa server vpa.key`

`sudo vpa server vpa.key auto 12345`

The first example uses port `443`, the default.
The last example specifies port `12345`, and everything else is set to the default values.

## Example usage on the client

`sudo vpa client vpa.key (server IP or hostname)`

If a port different than `443` needs to be used, specify it after the server's IP or hostname.

## That's it

Once the vpa-server is started and the vpa-client is started, the encrypted connection is established and the routing is arranged.

To disconnect, hit `Ctrl-C` on either the client or server.

## A note on client DNS

If the client was using a DNS resolver that's only accessible from the local network, it will no longer be accessible through the VPN.
That would be the only issue that needs to be worked around. Use a public resolver, a fully local resolver, or DNSCrypt.

## Full & advanced configuration

The arguments are given in this order, any values of `auto` at the end can be left off.

```text
vpa server|client <key> <server> <port> <tunnel> <local IP> <remote IP> <external IP>|<gateway IP>

vpa server
    <key file>
    <server IP or hostname> | auto
    <server port> | auto
    <tunnel name> | auto
    <local tunnel IP> | auto
    <remote tunnel IP> | auto
    <external IP> | auto

vpa client
    <key file>
    <server IP or hostname>
    <server port> | auto
    <tunnel name> | auto
    <local tunnel IP> | auto
    <remote tunnel IP> | auto
    <gateway IP> | auto
```

* `server` or `client`: use `server` on the server, and `client` on clients.
* `<key file>`: path to the file with the secret key (e.g. `vpa.key`).
* `<server IP or hostname>`: on the client, it should be the IP address or hostname of the server.
  The server will by default listen on all interfaces (using `auto`), or you can limit to a specified IP address.
* `<server port>`: the TCP port to use for the VPN, `443` by default.
* `<tunnel name>`: the name of the VPN interface device. On Linux can be set to anything.
  On macOS, it has to follow a more boring pattern, best to use `auto` here.
* `<local tunnel IP>`: local IP address of the tunnel. Use any **private** IP address that you don't use here.
* `<remote tunnel IP>`: remote IP address of the tunnel. The client and server tunnel IPs must be the same on the client and on the server, just reversed! The defaults are `192.168.192.1` for the client and `192.168.192.254` for the server.
* `<external IP>` (only for the server): the external IP address of the server, best left to `auto`.
* `<gateway IP>` (only on the client): the router IP address, listed under Gateway by: `netstat -rn`

## Why

* Using TCP (most VPNs use UDP to not get bogged down, but with `BBR` congestion is minimal)
* Over any accessible port (ports `80` and `443` are usually available)
* Fully tunneled
* Secure
* Simple configuration
* Simple usage

