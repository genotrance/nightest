#! /bin/bash

# Configurable environment variables:
# - NIMBRANCH=devel|version-1-0|version-1-2
# - ARCH=32|64|arm64|arm7l

# Detect OSVAR if not Travis
if [[ -z "$OSVAR" ]]; then
  UNAME=`uname`
  if [[ "$UNAME" == "Linux" ]]; then
    export OSVAR="linux"
  elif [[ "$UNAME" == "Darwin" ]]; then
    export OSVAR="osx"
  else
    export OSVAR="windows"
  fi
fi

# Use local directory if not Travis
if [[ -z "$BUILDDIR" ]]; then
  export BUILDDIR=`pwd`
fi

# Test devel if no branch
if [[ -z "$NIMBRANCH" ]]; then
  export NIMBRANCH="devel"
fi

# Test 64-bit by default
if [[ -z "$ARCH" ]]; then
  export ARCH="64"
fi

set -e

if [[ "$OSVAR" == "osx" ]]
then
  unset -f cd
  shell_session_update() { :; }
fi

# Archive extension
if [[ "$OSVAR" == "windows" ]]; then
  export EXT=zip
else
  export EXT=tar.xz
fi

# Cleanup
rm -rf test
mkdir -p test
cd test
cp ../test.sh .

# Get nightlies tag and Nim commit
git clone https://github.com/alaviss/nightlies
cd nightlies
export YEAR=`date +%Y`
export TAG=`git tag --sort=-creatordate | grep $NIMBRANCH | head -n 1`
IFS='-' read -ra TAGSPLIT <<< "$TAG"
export COMMIT=${TAGSPLIT[${#TAGSPLIT[@]}-1]}
echo "Nightlies tag: $TAG"
echo "Commit: $COMMIT"
cd ..
rm -rf nightlies

# Get Nim version
wget -nv "https://github.com/nim-lang/Nim/raw/$COMMIT/lib/system.nim"
export MAJOR=`grep NimMajor system.nim | head -n 1 | cut -f7,7 -d" "`
export MINOR=`grep NimMinor system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export PATCH=`grep NimPatch system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export VERSION="$MAJOR.$MINOR.$PATCH"
echo "Nim version: $VERSION"
rm -rf system.nim

# Set filename
if [[ "$OSVAR" == "osx" ]]; then
  # OSX filename
  export FILENAME="nim-$VERSION-macosx_x$ARCH"
elif [[ $ARCH != "arm"* ]]; then
  # Windows / Linux - x86 / x64
  export FILENAME="nim-$VERSION-${OSVAR}_x$ARCH"
else
  # armv7l / arm64
  export FILENAME="nim-$VERSION-${OSVAR}_$ARCH"
fi

# Download nightlies binary
wget -nv "https://github.com/alaviss/nightlies/releases/download/$TAG/$FILENAME.$EXT"

# Run tests
if [[ "$OSVAR" == "linux" ]]; then
  # Fix arch for dockcross
  if [[ "$ARCH" == "32" ]]; then
    export IMAGE="$OSVAR-x86"
  elif [[ $ARCH == "64" ]]; then
    export IMAGE="$OSVAR-x64"
  elif [[ $ARCH == "armv7"* ]]; then
    export IMAGE="$OSVAR-armv7"
  else
    export IMAGE="$OSVAR-$ARCH"
  fi

  # Register binfmt_misc to run arm binaries
  if [[ $ARCH == "arm"* ]]; then
    docker run --rm --privileged multiarch/qemu-user-static:register
  fi

  # Use DockCross to test binaries
  docker run -t -i -e OSVAR=$OSVAR -e FILENAME=$FILENAME -e EXT=$EXT -e VERSION=$VERSION --rm -v `pwd`:/io dockcross/$IMAGE bash -c "cp /io/test.sh . && cp /io/$FILENAME.$EXT . && ./test.sh"
else
  ./test.sh
fi

cd ..
rm -rf test