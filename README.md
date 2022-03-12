# Http Assembly server

## First start

```console
$ sh build.sh
$ ./server
```

The server will start according to the parameters of the configuration file:

> Binding address: 192.168.1.67\
> Binding port: 42782\
> The server root directory: .

You can change these parameters in the config file [config](./config).

## Configuration

The server config parameters list:
> port=\<port>\
> host_addr=\<ip>\
> root=\<dir>

### port=

This parameter defines the server binding port.

### host_addr=

This parameter defines the server binding address.\
This parameter is used to bind the server to the specified network interface.

### root=

This parameter defines the server's root directory.\
The client won't have access to files and directories below the server root.

### Commentaries

A comment in the config file denfines by `#`.

#### Example
```
    root=/home/user     # This option specifies the server root directory.
```
## Arguments

List of arguments:
> --config=\<file>\
> --port=\<port>\
> --host_addr=\<ip>\
> --root=\<dir>

### --config=

This parameter specifies path to the server's configuration file.

### --port=

See [port option](#port=)

### --host_addr=

See [host_addr option](#host_addr=)

### --root=

See [root option](#root=)
