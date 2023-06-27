# Http Assembly server

[HTTP] [server] written in [x86\_64] [assembly language]\([GNU assembler]\) for [Linux].

[HTTP]: https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol
[server]: https://en.wikipedia.org/wiki/Server_(computing)
[x86\_64]: https://en.wikipedia.org/wiki/X86-64
[assembly language]: https://en.wikipedia.org/wiki/Assembly_language
[GNU assembler]: https://en.wikipedia.org/wiki/GNU_Assembler
[Linux]: https://en.wikipedia.org/wiki/Linux

## The server possibilities

 - [x] Config file implementation
 - [x] Command line arguments
 - [x] Error reporting\(including complaints about unknown args or words in config\)
 - [x] Multi-threaded connection servicing
 - [x] Decoding characters in hexadecimal encoding in requests
 - [x] Buffered IO
 - [x] Checking http method and protocol version in requests
 - [x] Proper partial content request serving
 - [x] Directory listing
 - [x] Mime-types
 - [x] Root jail
 - [x] Logging

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

The server without arguments will start according to the parameters of the
configuration file. \
If configuration file cannot be found, the server's parameters will set to
built-in parameters:

> Binding address: 0.0.0.0(All interfaces)                                           \
  Binding port: 80                                                                   \
  The server root directory: .                                                       \
  Default directory file: index.html                                                 \
  Enable default directory files: yes                                                \
  Enable directory list: yes                                                         \
  Timeout: 90 000ms                                                                  \
  Minimal permission: 4                                                              \
  Show hidden files(i.e. files whose names start with '.') in directory listing: yes \
  MIME-types file name: mime.types                                                   \
  Dirlist sorting: yes                                                               \
  Dirlist caching: yes                                                               \
  Cache directory: cache                                                             \
  Log file: server.log                                                               \
  Enable log to file: yes                                                            \
  Enable silent log: no                                                              \
  Table view dirlisting: yes

## Configuration

The server config parameters list:
> server-port=\<port>                             \
  server-binding-device-address=\<ip>             \
  server-root=\<dir>                              \
  default-directory-file-name=\<file>             \
  enable-default-directory-files=\<true|false>    \
  enable-dirlisting=\<true|false>                 \
  enable-custom-403-page=\<true|false>            \
  enable-custom-404-page=\<true|false>            \
  403-page-file-path=\<path>                      \
  404-page-file-path=\<path>                      \
  minimal-openning-permission=\<num>              \
  client-request-timeout=\<num>                   \
  enable-hidden-files-in-dirlisting=\<true|false> \
  mimetypes-file-path=\<path>                     \
  enable-dirlists-sorting=\<true|false>           \
  enable-dirlists-caching=\<true|false>           \
  caches-directory-name=\<dir>                    \
  log-file-path=\<file>                           \
  enable-logging-to-file=\<true|false>            \
  enable-silent-logging=\<true|false>             \
  table-view-dirlisting=\<true|false>

#### server-port

This parameter defines the server binding port.

#### server-binding-device-address

This parameter defines the server binding address. \
This parameter is used to bind the server to the specified network interface.

#### server-root-directory

This parameter defines the server's root directory. \
The client won't have access to files and directories below the server root.

#### default-directory-file-name

This parameter the defines default file name of file that will be opened in
requested directory when client requests a directory.

#### enable-default-directory-files

This parameter toggles opening files in requested directories by [default file
name](#default-directory-file-name) when client requests a directory.

#### enable-dirlisting

This parameter toggles sending HTML page of the directory content what client
had requested. \
HTML page will be make and send if default directory file cannot be found or
default files are disabled.

#### 404-page-file-path

This parameter defines path to 404 http error page.

#### 403-page-file-path

Same as [404](#404-page-file-path)

#### enable-custom-404-page

This parameter toggles using of page described by [404-page-file-path option](#404-page-file-path)

#### enable-custom-403-page

Same as [enable-custom-404-page](#enable-custom-404-page)

#### minimal-openning-permission

This parameter defines minimal permission for file or directory openning or
listing. If the permission less than this option the server sends 403 error
response. \
The permission that the server checks have defined in `others` permission
group of file or directory. \
The permission parameter can be from 0(---) to 7(xwr). If the permission is
`0` the server will try to open any files.

#### client-request-timeout

This parameter sets timeout in milliseconds for client request. If client
timed out the server sends 408 error response.

#### enable-hidden-files-in-dirlisting

Files whose names start with `.` are considered hidden. Thus this parameter
determines showing the files in directory listing whose name start with `.`.

#### mimetypes-file-path

This parameter defines the path to MIME-types file instead of the built-in
path: `mime.types`

Mime types file syntax:
```
# <- Commentary
# Tabs and spaces allowed
# Types divided by newlines
# Type ------- Extensions
text/x-c       c cc cxx cpp h hh hpp
text/html      html htm
```

#### enable-dirlists-sorting

This parameter toggles sorting by name in directory listing.

**WARNING:** Sorting can doing long on directories with a lot of entries. For
  example directory with 14638 entries is sorted in 16.6 seconds(CPU: Athlon
  64 X2 4200+ 2200MHz).

#### enable-dirlists-caching

This parameter toggles caching a pages of directory listing.

#### caches-directory-name

This parameter determines a location of a cache files.
Cache directory should not have any extrinsic files or directories.

#### log-file-path

This parameter determines a file name of a server log file.
Server will write all logs with date and time to specified file.

#### enable-logging-to-file

This parameter toggles server logs writes to the **log-file-path**

#### enable-silent-logging

This parameter toggles server logs writes to **stdout**.
If specified **true**, the server will do not attempts to write to **stdout**,
otherwise, if specified **false**, the server will writes logs only with time
in **stdout**

#### table-view-dirlisting

This parameter toggles using of HTML table tags for dirlistings instead of
simple list of links. If specified **true**, the server in dirlisting also
writes modification time and size in row for each file in requested directory.

#### Commentaries

A comment in the config file defines by `#`.

#### Example
```
    root=/home/user     # This option specifies the server root directory.
```
## Command line arguments

List of arguments:
> -d | --daemonize   \
  --config=\<file>   \
  --port=\<port>     \
  --host\_addr=\<ip> \
  --root=\<dir>      \
  -h | --help

#### -d | --daemonize 

Daemonize the server(i.e. run the server in background).

#### --config

This parameter specifies path to the server's configuration file.

#### --port

Same as [server-port config option](#server-port)

#### --host\_addr

Same as [server-binding-device-address config option](#server-binding-device-address)

#### --root

Same as [server-root-directory config option](#server-root-directory)

#### -h | --help

Prints usage message and list of the arguments.

## Links

x86\_64 Linux syscall table:
    https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md \
Linux man pages:
    https://man7.org/linux/man-pages/index.html                                      \
HTTP reference documentation:
    https://developer.mozilla.org/en-US/docs/Web/HTTP#reference
