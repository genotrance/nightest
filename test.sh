#! /bin/bash

# Install packages
if [[ "$OSVAR" == "osx" ]]; then
  # Brew packages
  brew update
  brew install boehmgc
  brew install sfml
  brew install gnu-tar
  brew upgrade node
elif [[ "$OSVAR" == "linux" ]]; then
  # Apt packages
  apt update
  # apt upgrade -y
  apt install libcurl4-openssl-dev libsdl1.2-dev libgc-dev libsfml-dev nodejs -y
elif [[ "$OSVAR" == "windows" ]]; then
  if [[ ! -d "${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}" ]]
  then
    # MinGW on Windows
    wget -nv "https://nim-lang.org/download/mingw${ARCH}.7z"
    7z x -y "mingw${ARCH}.7z" -o"${TRAVIS_BUILD_DIR}/mingw" > nul
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