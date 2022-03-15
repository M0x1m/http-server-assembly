# Http Assembly server

## First start

```console
$ sh build.sh
$ ./server
```

The server will start according to the parameters of the configuration file:

> Binding address: 0.0.0.0(All interfaces)\
  Binding port: 8080\
  The server root directory: .

You can change these parameters in the config file [config](./config).

## Configuration

The server config parameters list:
> port=\<port>\
  host_addr=\<ip>\
  root=\<dir>\
  ddir_file=\<file>\
  do_ddir_files=\<true|false>

### port=

This parameter defines the server binding port.

### host_addr=

This parameter defines the server binding address.\
This parameter is used to bind the server to the specified network interface.

### root=

This parameter defines the server's root directory.\
The client won't have access to files and directories below the server root.

### ddir_file=

This parameter the defines default file name of file that will be opened when client requests a directory.

### do\_ddir_files=

This parameter toggles opening files by [default file name](#ddir_file) when client requests a directory.

### Commentaries

A comment in the config file denfines by `#`.

#### Example
```
    root=/home/user     # This option specifies the server root directory.
```
## Arguments

List of arguments:
> --config=\<file>\
  --port=\<port>\
  --host_addr=\<ip>\
  --root=\<dir>

### --config=

This parameter specifies path to the server's configuration file.

### --port=

See [port option](#port)

### --host_addr=

See [host_addr option](#host_addr)

### --root=

See [root option](#root)
