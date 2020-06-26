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
    wget -nv "https://nim-lang.org/download/mingw${ARCH}-6.3.0.7z"
    7z x -y "mingw${ARCH}-6.3.0.7z" -o"${TRAVIS_BUILD_DIR}/mingw" > nul
  fi
  export PATH="${TRAVIS_BUILD_DIR}/mingw/mingw${ARCH}/bin:${PATH}"
fi

export OSVAR="${TRAVIS_OS_NAME}"

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
export TAG=`git tag --sort=-taggerdate | grep $YEAR | grep $NIMBRANCH | head -n 1`
export COMMIT=`echo $TAG | cut -f5,5 -d"-"`
echo "Nightlies tag: $TAG"
cd ..

# Get Nim version
wget "https://github.com/nim-lang/Nim/raw/$COMMIT/lib/system.nim"
export MAJOR=`grep NimMajor system.nim | head -n 1 | cut -f7,7 -d" "`
export MINOR=`grep NimMinor system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export PATCH=`grep NimPatch system.nim | tail -n 2 | head -n 1 | cut -f7,7 -d" "`
export VERSION="$MAJOR.$MINOR.$PATCH"
echo "Nim version: $VERSION"

# Download nightlies binary
export FILENAME="nim-$VERSION-$OSVAR-$ARCH"
wget "https://github.com/alaviss/nightlies/releases/download/$TAG/$FILENAME.$EXT"

# Register binfmt_misc to run arm binaries
if [[ $ARCH == "arm"* ]]
then
  docker run --rm --privileged multiarch/qemu-user-static:register
fi

if [[ $ARCH == "arm7l" ]]; then
  export ARCH="arm7"
fi

# Extract Nim
if [[ "$EXT" == "tar.xz" ]]; then
  7z x -y "$FILENAME.$EXT" > nul
  export EXT=tar
fi
7z x -y "$FILENAME.$EXT" -o"${TRAVIS_BUILD_DIR}/nim" > nul

# Run tests
if [[ "$OSVAR" == "linux" ]]; then
  # Use DockCross to test binaries
  docker run -t -i -e --rm -v $TRAVIS_BUILD_DIR/nim:/io dockcross/$OSVAR-$ARCH bash -c "cd /io && ./koch test"
else
  cd $TRAVIS_BUILD_DIR/nim && ./koch test
fi