#! /bin/bash

# Install packages
if [[ "$OSVAR" == "osx" ]]; then
  # Brew packages
  brew update > /dev/null
  brew install boehmgc sfml gnu-tar > /dev/null
  brew upgrade node > /dev/null
elif [[ "$OSVAR" == "linux" ]]; then
  # Apt packages
  set -e
  apt -q update
  apt -q -y upgrade
  apt -q -y install libcurl4-openssl-dev libsdl1.2-dev libgc-dev libsfml-dev nodejs
elif [[ "$OSVAR" == "windows" ]]; then
  if [[ ! -d "${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}" ]]
  then
    # MinGW on Windows
    wget -nv "https://nim-lang.org/download/mingw${ARCH}.7z"
    7z x -y "mingw${ARCH}.7z" -o"${TRAVIS_BUILD_DIR}/mingw" > /dev/null
  fi
  export PATH="${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}/bin:${PATH}"
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
testament --nim:`pwd`/bin/nim --pedantic all -d:nimCoroutines

cd ..