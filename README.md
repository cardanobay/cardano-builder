# The Cardano Static Binaries Builder

## Static vs Dynamic

When you compile the cardano-cli and cardano-node binaries on standard distribution (like RHEL/Debian etc.), they are compiled, by default, with glibc. As a result, the produced binaries cannot become "fully static". This is a limitation of the library. They are instead, "dynamically" linked to glibc, as well as some other mandatory libraries. You can see theses dynamic links by issuing two commands

* `ldd cardano-node`
```
       linux-vdso.so.1 (0x00007ffc91bf5000)
        linux-vdso.so.1 (0x00007ffe52385000)
        libm.so.6 => /lib64/libm.so.6 (0x00007f795c837000)
        libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00007f795c60c000)
        libsystemd.so.0 => /lib64/libsystemd.so.0 (0x00007f795c367000)
        libz.so.1 => /lib64/libz.so.1 (0x00007f795c150000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f795bf30000)
        librt.so.1 => /lib64/librt.so.1 (0x00007f795bd27000)
        libutil.so.1 => /lib64/libutil.so.1 (0x00007f795bb23000)
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f795b91f000)
        libgmp.so.10 => /lib64/libgmp.so.10 (0x00007f795b687000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f795b2c4000)
        ...
```
* `file cardano-node`\

\*see the 'dynamically linked" mention

```
cardano-node: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked*, interpreter /lib64/ld-linux-x86-64.so.2,
for GNU/Linux 3.2.0, BuildID[sha1]=e6c5d1d3c97588b19dc71aed1b95bd1f156d1c56, with debug_info, not stripped, 
```
There are four problems with this approach.
1) You must install all the required libraries on your system, and on each system, the processus differs.
2) If the system is updated (apt/yum/dnf update), the libraries and cardano binaries could have incompatibilities.
3) It adds a lot of unnecessary data to the file system (because often, you install hundred of MB of package just to have a small .so library). Not a good idea if you want to run a very small node, let's say, in a container on AWS.
4) The binaries are not portable. It means you have to rebuild (or download) a pre-compiled binary for each different operating system and version you want to use.

A contrario, we call "static" a binary that contains all required library in itself. It is possible to have a fully static binary, by compiling the cardano source code with [musl-libc](https://wiki.musl-libc.org/  "musl-libc"). You can then copy the compiled binaries on every linux distribution, wihout installing any dependencies. The same binary can run on Debian, Centos, Redhat, Fedora, Ubuntu etc. in every version, without needing to install a single additional package.

When you analyze a static binary, this is what you get :

* `ldd cardano-node`
```
        not a dynamic executable
```

* `file cardano-node`\
\*see the 'statically linked" mention
```
cardano-node: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

The real advantage is... you can add it to a very very small docker image, which consumes near to zero excessive disk space or memory ! If you are interested by such small docker images you can find more informations here : [The Lightweight & Secure Cardano Node](https://github.com/cardanobay/cardano-node "The Lightweight & Secure Cardano Node"), [The Easy Peasy Cardano CLI](https://github.com/cardanobay/cardano-cli "The Easy Peasy Cardano CLI")

!!! Currently, we have not been able to build CABAL with musl-libc on the aarch64 architecture, so it is not possible to compile a fully statically linked for the Rock PI. But you can run a container on aarch64, or build a dynamically linked binary here [The Lightweight & Secure Cardano Node](https://github.com/cardanobay/cardano-node)

## Download static binaries

You can find the latest version of fully statically linked binaries on our [releases](https://github.com/cardanobay/cardano-node/releases) page.

## Build static binaries

You can download the pre-compiled static binaries, or docker images with the links above, or you can of course build your own version of the binaries ;) 

### Build example

Note that, in this example, once the builder finished its job, the static binaries (cardano-node & cardano-cli) can be found on the host, in the **/tmp** directory. You can then use theses binaries on whatever system (linux) you prefer, just copy & paste it !

```
podman run --rm --name cardano-builder \
  --volume /tmp:/release \
  cardanobay/cardano-builder --build \
    --cardano_version latest \
    --ghc_version 8.6.5 \
    --os_arch x86_64 \
    --cabal_version 3.2.0.0
```

### Usage

```
Usage: /usr/local/bin/builder build --cardano_version <version> [OPTIONS]
  Build the Cardano Node container.

Available options:
  --build*            Ask the builder to begin the build process
  --cardano_version*  The cardano version [Default: N/A] [Example: latest, 1.13.0]
                      'latest' will results in resolving the latest version from github
  --ghc_version       The Glasgow Haskell Compiler version [Default: 8.6.5]
  --cabal_version     The Common Architecture for Building Applications
                      and Libraries [Default: 3.2.0.0]
  --os_arch           The operating system architecture [Default: x86_64]
  --help              Display this message
 * = mandatory options
```

## What is in this repo ?

In this repository, you will find
* [Dockerfile](https://raw.githubusercontent.com/cardanobay/cardano-builder/master/Dockerfile). Contains the instructions to build the cardano-builder container
* [Building Script](https://raw.githubusercontent.com/cardanobay/cardano-builder/master/scripts/02-build-image). A helper script to build* the cardano-builder container. Yes... the builder has to be built xD
  * usage : `./scripts/02-build-image --builder docker`
* [Static binary builder](https://raw.githubusercontent.com/cardanobay/cardano-builder/master/builder), included in the container. Contains all the instructions to build the fully statically linked binary with musl-libc
* This README ^_^

## Contact

Admin email : pascha+cardanobay@protonmail.com \
Website : https://www.cardanobay.com \
Docker Hub : https://hub.docker.com/r/cardanobay/cardano-builder \
Github : https://github.com/cardanobay/cardano-builder
