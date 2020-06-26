export OSVAR="${TRAVIS_OS_NAME}"

# Packages on OSX
if [[ "$OSVAR" == "osx" ]]
then
  brew update
  brew install boehmgc
  brew install sfml
  brew install gnu-tar
  brew upgrade node
fi

set -e

if [[ "$OSVAR" == "osx" ]]
then
  unset -f cd
  shell_session_update() { :; }
fi

# MinGW on Windows
if [[ "$OSVAR" == "windows" ]]
then
  if [[ ! -d "${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}" ]]
  then
    wget -nv "https://nim-lang.org/download/mingw${ARCH}.7z"
    7z x -y "mingw${ARCH}.7z" -o"${TRAVIS_BUILD_DIR}/mingw" > nul
  fi
  export PATH="${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}/bin:${PATH}"
  gcc --version
fi

# Archive extension
if [[ "$OSVAR" == "windows" ]]; then
  export EXT=zip
else
  export EXT=tar.xz
fi

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

# Get Nim version
wget "https://github.com/nim-lang/Nim/raw/$COMMIT/lib/system.nim"
export MAJOR=`grep NimMajor system.nim | head -n 1 | cut -f7,7 -d" "`
export MINOR=`grep NimMinor system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export PATCH=`grep NimPatch system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export VERSION="$MAJOR.$MINOR.$PATCH"
echo "Nim version: $VERSION"

# Register binfmt_misc to run arm binaries
if [[ $ARCH == "arm"* ]]
then
  docker run --rm --privileged multiarch/qemu-user-static:register
  if [[ $ARCH == "arm7l" ]]; then
    export ARCH="arm7"
  fi
else
  export ARCH="x$ARCH"
fi

# Fix OS filename
if [[ "$OSVAR" == "osx" ]]; then
  export OSVAR="macosx"
fi

# Download nightlies binary
export FILENAME="nim-$VERSION-${OSVAR}_$ARCH"
wget "https://github.com/alaviss/nightlies/releases/download/$TAG/$FILENAME.$EXT"

# Extract Nim
if [[ "$EXT" == "tar.xz" ]]; then
  tar xJf "$FILENAME.$EXT" -C "${TRAVIS_BUILD_DIR}" > /dev/null
else
  7z x -y "$FILENAME.$EXT" -o"${TRAVIS_BUILD_DIR}" > nul
fi

# Run tests
if [[ "$OSVAR" == "linux" ]]; then
  # linux-x86
  if [[ "$ARCH" == "32" ]]; then
    export ARCH="x86"
  fi
  # Use DockCross to test binaries
  docker run -t -i -e --rm -v $TRAVIS_BUILD_DIR/nim-$VERSION:/io dockcross/$OSVAR-$ARCH bash -c "cd /io && ./koch test"
else
  cd $TRAVIS_BUILD_DIR/nim-$VERSION && ./koch test
fi