#! /bin/bash

# Install packages
if [[ "$OSVAR" == "osx" ]]; then
  # Brew packages
  brew update > /dev/null
  brew install boehmgc sfml gnu-tar > /dev/null
  brew upgrade node > /dev/null
elif [[ "$OSVAR" == "linux" ]]; then
  # Apt packages + Nodejs
  set -e
  curl -sL https://deb.nodesource.com/setup_12.x | bash -
  apt -q -y install libcurl4-openssl-dev libsdl1.2-dev libgc-dev libsfml-dev valgrind nodejs

  # Running in Travis
  export TRAVIS="true"
elif [[ "$OSVAR" == "windows" ]]; then
  # MinGW on Windows
  if [[ ! -d "$BUILDDIR/mingw/mingw$ARCH" ]]; then
    wget -nv "https://nim-lang.org/download/mingw$ARCH.7z"
    7z x -y "mingw$ARCH.7z" -o"$BUILDDIR/mingw" > /dev/null
  fi

  # Nodejs on Windows
  export NODEVER="v12.18.1"

  if [[ "$ARCH" == "64" ]]; then
    export NODEFILE="node-$NODEVER-win-x64"
  else
    export NODEFILE="node-$NODEVER-win-x86"
  fi

  if [[ ! -d "$BUILDDIR/nodejs" ]]; then
    export NODEURL="https://nodejs.org/dist/$NODEVER/$NODEFILE.zip"
    wget -nv "$NODEURL.zip"
    7z x -y "$NODEFILE.zip" -o"$BUILDDIR/nodejs" > /dev/null
  fi

  export PATH="$BUILDDIR/nodejs/$NODEFILE:$BUILDDIR/mingw/mingw$ARCH/bin:$PATH"
  gcc --version
fi

# Extract Nim
if [[ "$OSVAR" == "windows" ]]; then
  7z x -y "$FILENAME.$EXT" > nul
else
  tar xJf "$FILENAME.$EXT" > /dev/null
fi

cd nim-$VERSION

# Add Nim to path
export PATH="$PATH:`pwd`/bin"

# Run testament
if [[ $ARCH == "arm"* ]]; then
  # Only megatest for arm
  export TESTS="cat megatest"
else
  export TESTS="all"
fi
testament --nim:`pwd`/bin/nim --pedantic $TESTS -d:nimCoroutines

cd ..