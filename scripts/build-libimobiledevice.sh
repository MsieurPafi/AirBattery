#!/bin/bash
#
# Rebuilds the libimobiledevice stack embedded in AirBattery/libimobiledevice/:
# OpenSSL, libplist, libimobiledevice-glue, libusbmuxd, libtatsu, libimobiledevice, plus the
# idevice_id / ideviceinfo / idevicesyslog tools, comptest and wificonnection.
#
# - Pinned release tarballs, verified with SHA-256 before anything is built.
# - Universal binaries (arm64 + x86_64), minimum macOS 12.0 like the app.
# - Everything is built under build/libimobiledevice/ (git-ignored); nothing is
#   installed on the system. Only clang, make, perl and pkg-config are needed.
# - The result replaces AirBattery/libimobiledevice/{bin,lib}: dylib install names
#   are rewritten to @executable_path/../lib/ and every Mach-O is ad hoc signed
#   (Xcode does not sign files inside Resources).
#
# Usage: scripts/build-libimobiledevice.sh [--no-install]
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/build/libimobiledevice"
DEST="$ROOT/AirBattery/libimobiledevice"
MIN_MACOS="12.0"
ARCHS=(arm64 x86_64)
JOBS="$(sysctl -n hw.ncpu)"
INSTALL=1
[[ "${1:-}" == "--no-install" ]] && INSTALL=0

# name | version | url | sha256
SOURCES=(
  "openssl|3.5.9|https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz|603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a"
  "libplist|2.8.0|https://github.com/libimobiledevice/libplist/releases/download/2.8.0/libplist-2.8.0.tar.bz2|b1f59f7634c58b2481325a23ff4e3bf51574a42d868cbe466d2b39b04550752a"
  "libimobiledevice-glue|1.3.3|https://github.com/libimobiledevice/libimobiledevice-glue/releases/download/1.3.3/libimobiledevice-glue-1.3.3.tar.bz2|920ce01382a32695f49b23292b4979a03f0afd16c58e8755d8b7f41804acc1a9"
  "libusbmuxd|2.1.1|https://github.com/libimobiledevice/libusbmuxd/releases/download/2.1.1/libusbmuxd-2.1.1.tar.bz2|5546f1aba1c3d1812c2b47d976312d00547d1044b84b6a461323c621f396efce"
  "libtatsu|1.0.5|https://github.com/libimobiledevice/libtatsu/releases/download/1.0.5/libtatsu-1.0.5.tar.bz2|536fa228b14f156258e801a7f4d25a3a9dd91bb936bf6344e23171403c57e440"
  "libimobiledevice|1.4.0|https://github.com/libimobiledevice/libimobiledevice/releases/download/1.4.0/libimobiledevice-1.4.0.tar.bz2|23cc0077e221c7d991bd0eb02150a0d49199bcca1ddf059edccee9ffd914939d"
)
# comptest.c lives in scripts/libimobiledevice/ (gist revision + AirBattery changes,
# see its header); wificonnection.c in AirBattery/libimobiledevice/bin/.
COMPTEST_SRC="$ROOT/scripts/libimobiledevice/comptest.c"

log() { printf '\n==> %s\n' "$*"; }

download() {
  local url="$1" sha="$2" out="$3"
  if [[ ! -f "$out" ]]; then
    curl -fsSL --retry 3 -o "$out.part" "$url"
    mv "$out.part" "$out"
  fi
  local got
  got="$(shasum -a 256 "$out" | cut -d' ' -f1)"
  if [[ "$got" != "$sha" ]]; then
    echo "SHA-256 mismatch for $out: expected $sha, got $got" >&2
    exit 1
  fi
}

host_triple() { [[ "$1" == arm64 ]] && echo aarch64-apple-darwin || echo x86_64-apple-darwin; }

# --- Sources -------------------------------------------------------------------
mkdir -p "$WORK/downloads"
log "Downloading and verifying sources"
for entry in "${SOURCES[@]}"; do
  IFS='|' read -r name version url sha <<< "$entry"
  download "$url" "$sha" "$WORK/downloads/$(basename "$url")"
  echo "ok  $name $version"
done

# --- Per-architecture builds -----------------------------------------------------
for arch in "${ARCHS[@]}"; do
  PREFIX="$WORK/prefix-$arch"
  SRC="$WORK/src-$arch"
  rm -rf "$PREFIX" "$SRC"
  mkdir -p "$PREFIX" "$SRC"
  for entry in "${SOURCES[@]}"; do
    IFS='|' read -r name version url sha <<< "$entry"
    tar -xf "$WORK/downloads/$(basename "$url")" -C "$SRC"
  done

  export CFLAGS="-arch $arch -mmacosx-version-min=$MIN_MACOS -O2"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS="-arch $arch -mmacosx-version-min=$MIN_MACOS -Wl,-headerpad_max_install_names"
  export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
  export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"   # never pick up Homebrew's copies

  log "[$arch] OpenSSL"
  # OpenSSL records its prefix in libcrypto (config, engines and modules paths). Build it
  # for a neutral prefix that never exists, stage it with DESTDIR, then point install
  # names and pkg-config files at $PREFIX for the libraries built next.
  OSSL_PREFIX="/usr/local/airbattery-openssl"
  (cd "$SRC/openssl-3.5.9" &&
    ./Configure "darwin64-$arch-cc" shared no-tests no-docs no-apps \
      --prefix="$OSSL_PREFIX" --openssldir="$OSSL_PREFIX/ssl" --libdir=lib \
      "-mmacosx-version-min=$MIN_MACOS" > "$WORK/openssl-$arch.log" 2>&1 &&
    make -j"$JOBS" >> "$WORK/openssl-$arch.log" 2>&1 &&
    make install_sw DESTDIR="$WORK/ossl-stage-$arch" >> "$WORK/openssl-$arch.log" 2>&1)
  cp -R "$WORK/ossl-stage-$arch$OSSL_PREFIX/include" "$WORK/ossl-stage-$arch$OSSL_PREFIX/lib" "$PREFIX/"
  rm -rf "$WORK/ossl-stage-$arch"
  for l in libcrypto.3.dylib libssl.3.dylib; do
    chmod u+w "$PREFIX/lib/$l"
    install_name_tool -id "$PREFIX/lib/$l" "$PREFIX/lib/$l"
  done
  install_name_tool -change "$OSSL_PREFIX/lib/libcrypto.3.dylib" "$PREFIX/lib/libcrypto.3.dylib" "$PREFIX/lib/libssl.3.dylib"
  sed -i '' "s|$OSSL_PREFIX|$PREFIX|g" "$PREFIX"/lib/pkgconfig/*.pc

  common=(--host="$(host_triple "$arch")" --build=aarch64-apple-darwin --prefix="$PREFIX"
          --disable-static --enable-shared)
  build_autotools() {
    local dir="$1"; shift
    log "[$arch] $dir"
    (cd "$SRC/$dir" &&
      ./configure "${common[@]}" "$@" > "$WORK/$dir-$arch.log" 2>&1 &&
      make -j"$JOBS" >> "$WORK/$dir-$arch.log" 2>&1 &&
      make install >> "$WORK/$dir-$arch.log" 2>&1)
  }
  build_autotools libplist-2.8.0 --without-cython
  build_autotools libimobiledevice-glue-1.3.3
  build_autotools libusbmuxd-2.1.1
  # libtatsu (required since libimobiledevice 1.4.0) links macOS's own libcurl,
  # which has no pkg-config file: pass its flags directly.
  build_autotools libtatsu-1.0.5 \
    libcurl_CFLAGS="-I$(xcrun --sdk macosx --show-sdk-path)/usr/include" libcurl_LIBS="-lcurl"
  build_autotools libimobiledevice-1.4.0 --without-cython

  log "[$arch] comptest, wificonnection"
  for tool in comptest wificonnection; do
    src="$COMPTEST_SRC"
    [[ "$tool" == wificonnection ]] && src="$DEST/bin/wificonnection.c"
    # wificonnection.c prints PACKAGE_VERSION for --version (normally from config.h)
    clang $CFLAGS $LDFLAGS -DPACKAGE_VERSION='"1.4.0"' -I"$PREFIX/include" "$src" -o "$PREFIX/bin/$tool" \
      -L"$PREFIX/lib" -limobiledevice-1.0 -lplist-2.0 -lusbmuxd-2.0 -limobiledevice-glue-1.0
  done
done

# --- Universal binaries with relative install names ------------------------------
OUT="$WORK/out"
rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/lib"
TOOLS=(idevice_id ideviceinfo idevicesyslog comptest wificonnection)

# Libraries actually needed by the tools, following install names recursively.
deps_of() { otool -L "$1" | tail -n +2 | awk '{print $1}' | grep "^$WORK/prefix-arm64/lib/" || true; }
NEEDED=()
queue=()
for t in "${TOOLS[@]}"; do queue+=("$WORK/prefix-arm64/bin/$t"); done
while ((${#queue[@]})); do
  f="${queue[0]}"; queue=("${queue[@]:1}")
  for d in $(deps_of "$f"); do
    b="$(basename "$d")"
    if [[ ! " ${NEEDED[*]-} " == *" $b "* ]]; then NEEDED+=("$b"); queue+=("$d"); fi
  done
done

relink() {   # rewrite install names of a thin Mach-O built for $arch
  local file="$1" arch="$2" d
  for d in $(otool -L "$file" | tail -n +2 | awk '{print $1}' | grep "^$WORK/prefix-$arch/lib/" || true); do
    install_name_tool -change "$d" "@executable_path/../lib/$(basename "$d")" "$file"
  done
}

log "Universal binaries"
for kind in bin lib; do
  if [[ $kind == bin ]]; then names=("${TOOLS[@]}"); else names=("${NEEDED[@]}"); fi
  for n in "${names[@]}"; do
    thin=()
    for arch in "${ARCHS[@]}"; do
      t="$WORK/thin-$arch-$n"
      cp "$WORK/prefix-$arch/$kind/$n" "$t"
      chmod u+w "$t"
      [[ $kind == lib ]] && install_name_tool -id "@executable_path/../lib/$n" "$t"
      relink "$t" "$arch"
      thin+=("$t")
    done
    lipo -create "${thin[@]}" -output "$OUT/$kind/$n"
    rm -f "${thin[@]}"
    codesign --force --sign - "$OUT/$kind/$n"
    echo "$kind/$n: $(lipo -archs "$OUT/$kind/$n")"
  done
done

{
  echo "Built by scripts/build-libimobiledevice.sh on $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "macOS minimum: $MIN_MACOS, architectures: ${ARCHS[*]}"
  for entry in "${SOURCES[@]}"; do IFS='|' read -r name version url sha <<< "$entry"; echo "$name $version  sha256:$sha"; done
  echo "comptest.c: scripts/libimobiledevice/comptest.c (gist nikias/ebc6e975 rev f98832d8 + AirBattery changes)"
  echo "wificonnection.c from this repository"
} > "$OUT/VERSIONS.txt"

if (( INSTALL )); then
  log "Installing into $DEST"
  rm -rf "$DEST/lib"
  mkdir -p "$DEST/lib"
  cp "$OUT"/lib/* "$DEST/lib/"
  for t in "${TOOLS[@]}"; do cp "$OUT/bin/$t" "$DEST/bin/$t"; done
  cp "$OUT/VERSIONS.txt" "$DEST/VERSIONS.txt"
  # License texts of every component shipped in lib/ and bin/.
  rm -rf "$DEST/licenses"
  mkdir -p "$DEST/licenses"
  SRC="$WORK/src-arm64"
  cp "$SRC/openssl-3.5.9/LICENSE.txt" "$DEST/licenses/openssl-LICENSE.txt"
  for d in libplist-2.8.0 libimobiledevice-glue-1.3.3 libusbmuxd-2.1.1 libimobiledevice-1.4.0; do
    for f in COPYING COPYING.LESSER; do
      [[ -f "$SRC/$d/$f" ]] && cp "$SRC/$d/$f" "$DEST/licenses/${d%-*}-$f"
    done
  done
fi
log "Done"
