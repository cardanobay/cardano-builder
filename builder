#!/bin/bash

# ----------------------------------------------------------------
# CHECK OPTIONS
# ----------------------------------------------------------------

set -e

trap 'catch $? $LINENO' EXIT

usage() {
  echo "Usage: $0 build --cardano_version <version> [OPTIONS]"
  echo "  Build the Cardano Node container."
  echo ""
  echo "Available options:"
  echo "  --build*            Ask the builder to begin the build process"
  echo "  --cardano_version*  The cardano version [Default: N/A] [Example: latest, 1.13.0]"
  echo "                      'latest' will results in resolving the latest version from github"
  echo "  --ghc_version       The Glasgow Haskell Compiler version [Default: 8.6.5]"
  echo "  --cabal_version     The Common Architecture for Building Applications"
  echo "                      and Libraries [Default: 3.2.0.0]"
  echo "  --os_arch           The operating system architecture [Default: x86_64]"
  echo "  --help              Display this message"
  echo " * = mandatory options"
  exit 0
}

catch() {
  if [ "$1" != "0" ]; then
    echo "An error has occured. Abording."
    exit 0
  fi
}

help=${help:-false}
build=${build:-false}
cardano_version=${cardano_version:-}
ghc_version=${ghc_version:-8.6.5}
cabal_version=${cabal_version:-3.2.0.0}
os_arch=${os_arch:-x86_64}

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2" 2>/dev/null
   fi
  shift
done

if [ ! -x "$(command -v 'apk')" ]; then
  echo "Error: this script is only compatible with alpine docker"
  exit 1
fi

if [ "$help" != false ]; then
  usage
fi

if [ "$build" == false ]; then
  usage
fi

if [ -z "$cardano_version" ]; then
  usage
fi

echo ""
echo "Building cardano with options :"
echo ""
echo "cardano_version : $cardano_version"
echo "ghc_version     : $ghc_version"
echo "cabal_version   : $cabal_version"
echo "os_arch         : $os_arch"
echo ""
sleep 5

# ----------------------------------------------------------------
# BUILD THE SOURCE CODE
# ----------------------------------------------------------------

# INSTALL GLOBAL PREREQUISITES
apk update \
  && apk upgrade \
  && apk add elogind-dev g++ git gmp-dev make ncurses-dev ncurses-static perl wget zlib-dev zlib-static

# CREATE DIRECTORY STRUCTURE
mkdir -p /build/cabal
mkdir -p /build/cardano
mkdir -p /build/elogind
mkdir -p /build/ghc

# INSTALL CABAL
# The Haskell Common Architecture for Building Applications and Libraries 
cd /build/cabal
wget -qO- https://downloads.haskell.org/cabal/cabal-install-latest/cabal-install-${cabal_version}-${os_arch}-alpine-linux-musl.tar.xz | tar xJf - -C .

# INSTALL GHC
# The Glasgow Haskell Compiler
cd /build/ghc
wget -qO- https://github.com/redneb/ghc-alt-libc/releases/download/ghc-${ghc_version}-musl/ghc-${ghc_version}-${os_arch}-unknown-linux-musl.tar.xz | tar xJf - -C . --strip-components 1 \
  && ./configure  \
  && make install

# BUILD STATIC VERSION OF LIBELOGIND
cd /build/elogind \
  && apk add ninja bash meson m4 gperf libcap-dev eudev-dev gettext-dev \
  && git clone https://github.com/elogind/elogind.git . \
  && meson build \
  && ninja -C build \
  && mkdir libelogind \
  && cd libelogind \
  && cp ../build/src/basic/libbasic.a . \
  && cp ../build/src/journal/libjournal-client.a . \
  && cp ../build/src/libelogind/libelogind_static.a . \
  && cp ../build/src/login/liblogind-core.a . \
  && echo "create libelogind.a
addlib libbasic.a
addlib libjournal-client.a
addlib libelogind_static.a
addlib liblogind-core.a
save
end" > libelogind.mri \
  && ar -M <libelogind.mri \
  && cp ./libelogind.a /lib

# DOWNLOAD AND PREPARE CARDANO SOURCE CODE
cd /build/cardano
git clone https://github.com/input-output-hk/cardano-node.git . \
 && git fetch --all --tags \
 && tag=$([ "${cardano_version}" = "latest" ] && echo $(git describe --tags $(git rev-list --tags --max-count=1)) || echo ${cardano_version}) \
 && git checkout tags/${tag} \
 && /build/cabal/cabal update

# BUILD : CARDANO NODE, CARDANO CLI
/build/cabal/cabal build all --enable-executable-static

# PUBLISH RELEASES
cp $(find ./ -type f -name "cardano-node") /release
cp $(find ./ -type f -name "cardano-cli") /release
