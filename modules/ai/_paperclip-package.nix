{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  nodejs_24,
  autoPatchelfHook,
  icu,
  libxml2,
  lz4,
  ncurses,
  openssl,
  zlib,
  zstd,
}:
buildNpmPackage (finalAttrs: {
  pname = "paperclipai";
  version = "2026.1012.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/paperclipai/-/paperclipai-${finalAttrs.version}.tgz";
    hash = "sha256-zCMxBYvZPLbU7hjNKbz2PAYh/E9u8MfPeMUkPL6cUK4=";
  };

  # The npm tarball ships no lockfile. Regenerate on update with:
  #   npm install --package-lock-only --ignore-scripts
  postPatch = ''
    cp ${./_paperclip-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-RU1wmbenGjfwky21NCmDmhEia0fIx99uYEiWqyaBS9o=";
  nodejs = nodejs_24;
  dontNpmBuild = true;

  # Patch the prebuilt embedded Postgres and agent SDK binaries. Leave sharp's
  # libvips untouched: patchelf/strip corrupt it (segfault on load). It only
  # needs libstdc++, which Node has already loaded.
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    icu
    libxml2
    lz4
    ncurses
    openssl
    zlib
    zstd
  ];
  dontStrip = true;
  dontAutoPatchelf = true;
  # Optional Postgres procedural languages (Perl, Python 3.6, Tcl) are unused.
  autoPatchelfIgnoreMissingDeps = [
    "libperl.so.*"
    "libpython3.6m.so.*"
    "libtcl8.6.so"
  ];
  postFixup = ''
    autoPatchelf $(find $out/lib/node_modules/paperclipai/node_modules \
      -mindepth 1 -maxdepth 1 ! -name @img)
  '';

  meta = {
    description = "Orchestration server and CLI for teams of AI agents";
    homepage = "https://github.com/paperclipai/paperclip";
    license = lib.licenses.mit;
    mainProgram = "paperclipai";
    platforms = [ "x86_64-linux" ];
  };
})
