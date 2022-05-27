# Http Assembly server

[HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) [server](https://en.wikipedia.org/wiki/Server_(computing)) written in [x86\_64](https://en.wikipedia.org/wiki/X86-64) [assembly language](https://en.wikipedia.org/wiki/Assembly_language)\([GNU assembler](https://en.wikipedia.org/wiki/GNU_Assembler)\) for [Linux](https://en.wikipedia.org/wiki/Linux).

## The server possibilities

 - [x] Config file implementation
 - [x] Command line arguments
 - [x] Error reporting\(including complaints about unknown args or words in config\)
 - [x] Multi-threaded connection servicing
 - [x] Decoding characters in hexadecimal encoding in requests
 - [x] Buffered IO
 - [x] Checking http method and protocol version in requests
 - [x] Proper partial content request serving
 - [ ] Directory listing
 - [ ] Mime-types
 - [ ] Root jail
 - [ ] Logging

## Getting the repository
```console
$ git clone https://github.com/M0x1m/http-server-assembly.git
```

## Building

`binutils` package is required for building the server.

  Building the server:
  ```console
  $ cd http-server-assembly
  $ bash build.sh
  ```

## Usage

```
$ ./server [{-d|--daemonize}, {-h|--help},
            {--port=(binding port)}, {--root=(directory)},
            {--host_addr=(ipv4 interface addr)},
            {--config=(path to the server config)}]
```

The server without arguments will start according to the parameters of the configuration file.\
If configuration file cannot be found, the server's parameters will set to built-in parameters:

> Binding address: 0.0.0.0(All interfaces)\
  Binding port: 80\
  The server root directory: .\
  Default dir file: index.html\
  Do default dir files: yes\
  Timeout: 90 000ms\
  Minimal permission: 4

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
  min\_permission=\<num>\
  timeout=\<num>

#### port

This parameter defines the server binding port.

#### host\_addr

This parameter defines the server binding address.\
This parameter is used to bind the server to the specified network interface.

#### root

This parameter defines the server's root directory.\
The client won't have access to files and directories below the server root.

#### ddir\_file

This parameter the defines default file name of file that will be opened in requested directory when client requests a directory.

#### do\_ddir\_files

This parameter toggles opening files in requested directories by [default file name](#ddir_file) when client requests a directory.

#### 404\_path

This parameter defines path to 404 http error page.

#### 403\_path

Same as [404](#404_path)

#### do\_custom\_404

This parameter toggles using of page described by [404\_path option](#404_path)

#### do\_custom\_403

Same as [do\_custom\_404](#do\_custom_404)

#### min\_permission

This parameter defines minimal permission for file or directory openning or listing. If the permission less than this option the server sends 403 error response.\
The permission that the server checks have defined in `others` permission group of file or directory.\
The permission parameter can be from 0(---) to 7(xwr). If the permission is `0` the server will try to open any files.

#### timeout

This parameter sets timeout in milliseconds for client request. If client timed out the server sends 408 error response.

### Commentaries

A comment in the config file denfines by `#`.

#### Example
```
    root=/home/user     # This option specifies the server root directory.
```
## Command line arguments

List of arguments:
> -d | --daemonize\
  --config=\<file>\
  --port=\<port>\
  --host\_addr=\<ip>\
  --root=\<dir>\
  -h | --help

#### -d | --daemonize 

Daemonize the server(i.e. run the server in background).

#### --config

This parameter specifies path to the server's configuration file.

#### --port

See [port option](#port)

#### --host\_addr

See [host\_addr option](#host_addr)

#### --root

See [root option](#root)

#### -h | --help

Prints usage message and list of the arguments.

## Links

x86\_64 Linux syscall table: https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md \
Linux man pages: https://man7.org/linux/man-pages/index.html \
HTTP reference documentation: https://developer.mozilla.org/en-US/docs/Web/HTTP#reference
