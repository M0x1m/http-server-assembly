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
  host\_addr=\<ip>\
  root=\<dir>\
  ddir\_file=\<file>\
  do\_ddir\_files=\<true|false>\
  do\_custom\_403=\<true|false>\
  do\_custom\_404=\<true|false>\
  403\_path=\<path>\
  404\_path=\<path>\
  min\_permission=\<num>

### port=

This parameter defines the server binding port.

### host\_addr=

This parameter defines the server binding address.\
This parameter is used to bind the server to the specified network interface.

### root=

This parameter defines the server's root directory.\
The client won't have access to files and directories below the server root.

### ddir\_file=

This parameter the defines default file name of file that will be opened in requested directory when client requests a directory.

### do\_ddir\_files=

This parameter toggles opening files in requested directories by [default file name](#ddir_file) when client requests a directory.

### 404\_path=

This parameter defines path to 404 http error page.

### 403\_path=

Same as [404](#404_path)

### do\_custom\_404=

This parameter toggles using of page described by [404\_path option](#404_path)

### do\_custom\_403=

Same as [do\_custom\_404](#do\_custom_404)

### min\_permission=

This parameter defines minimal permission for file openning. If file permission less than this option the server sends 403 error response.\
Permission can be from 0(---) to 7(xwr). On the minimal number of permission the server will properly open any files.

### Commentaries

A comment in the config file denfines by `#`.

#### Example
```
    root=/home/user     # This option specifies the server root directory.
```
## Arguments

List of arguments:
> -d | --daemonize\
  --config=\<file>\
  --port=\<port>\
  --host\_addr=\<ip>\
  --root=\<dir>\
  -h | --help

### -d | --daemonize 

Daemonize the server.

### --config=

This parameter specifies path to the server's configuration file.

### --port=

See [port option](#port)

### --host\_addr=

See [host\_addr option](#host_addr)

### --root=

See [root option](#root)

### -h | --help

Prints usage message and list of the arguments.
