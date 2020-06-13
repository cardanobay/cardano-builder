# The Cardano Static Binaries Builder

## Statica vs Dynamic

When you compile the cardano-cli and cardano-node binaries on standard distribution (like RHEL/Debian etc.), they are compiled, by default, with glibc. As a result, the produced binaries cannot become "fully static". They are instead, "dynamically" linked to some mandatory libraries. You can see theses dynamic links by issuing two commands

* `ldd cardano-node`
```
       linux-vdso.so.1 (0x00007ffc91bf5000)
        libm.so.6 => /lib64/libm.so.6 (0x00007fca039e3000)
        libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00007fca037b8000)
        libsystemd.so.0 => /lib64/libsystemd.so.0 (0x00007fca03513000)
        libz.so.1 => /lib64/libz.so.1 (0x00007fca032fc000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007fca030dc000)
        librt.so.1 => /lib64/librt.so.1 (0x00007fca02ed3000)
        ...
```
* `file cardano-node`\
\*see the 'dynamically linked" mention

```
cardano-node: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked*, interpreter /lib64/ld-linux-x86-64.so.2,
for GNU/Linux 3.2.0, BuildID[sha1]=e6c5d1d3c97588b19dc71aed1b95bd1f156d1c56, with debug_info, not stripped, 
```
There are four problems with this approach.
1) You must install all required libraries on your system, and on every system, the procedure differs.
2) If the system is updated (apt/yum/dnf update), the libraries and cardano binaries could suddenly become incompatible.
3) It embed a lot of unnecessary data to the file system (because often, you install hundred of MB of package just to have a small .so library). Not a good idea if you want to run your node, let's say, on docker.
4) The binaries are not portable. It means, you have to rebuild (or download) a pre-compiled binary for each operating system and version you want to use.

A contrario, we call "static" a binary that contains all required library in itself. It is possible to have a fully static binary, by compiling the code with [musl-libc](https://wiki.musl-libc.org/  "musl-libc"). You can then copy the binary on every linux distribution, wihout installing any dependencies. The same binary can run on Debian, Centos, Redhat, Fedora, Ubuntu etc. in every version, without needing to install a single additional package.

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

The real advantage is... you can add it to a very very small docker image, which take near to zero space and consume near to zero memory ! If you are interested by such small docker images, you can find more informations here : [The Lightweight & Secure Cardano Node Container](https://github.com/cardanobay/cardano-node "The Lightweight & Secure Cardano Node Container"), [The Easy Peasy Cardano CLI](https://github.com/cardanobay/cardano-cli "The Easy Peasy Cardano CLI") 

## Build Static Binaries

You can download the pre-compiled static binaries with the links above, or you can of course build your own version of the binaries ;) 

## Build example

Note that, in this example, once the builder finished its job, the static binaries (cardano-node & cardano-cli) can be found on the host, in the /tmp directory. You can then use this binary on whatever system (linux) you prefer !

```
podman run --rm --name cardano-builder \
  --volume /tmp:/release \
  cardanobay/cardano-builder build \
    --cardano_version latest \
    --ghc_version 8.6.5 \
    --os_arch x86_64 \
    --cabal_version 3.2.0.0
```

## Usage

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
