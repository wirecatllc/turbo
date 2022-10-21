{ lib
, stdenv
, nix-gitignore
, mdbook
, mdbook-linkcheck
, python3
, callPackage
, writeScript
, optionsMd ? null
, turbo ? null

  # Full version
, version ? if turbo != null then turbo.version else "unstable"

  # Whether this build is unstable
, unstable ? version == "unstable" || lib.hasInfix "-" version
}:

let
  apiVersion = builtins.concatStringsSep "." (lib.take 2 (lib.splitString "." version));

in
stdenv.mkDerivation {
  inherit version;

  pname = "turbo-manual" + (if unstable then "-unstable" else "");

  src = nix-gitignore.gitignoreSource [ ] ./.;

  nativeBuildInputs = [ mdbook mdbook-linkcheck python3 ];

  outputs = [ "out" ];

  TURBO_VERSION = version;
  TURBO_UNSTABLE = unstable;

  patchPhase = ''
    if [ -z "${toString unstable}" ]; then
        sed "s|@apiVersion@|${apiVersion}|g" book.stable.toml > book.toml
    fi
  '';

  buildPhase = ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v:
      ''
        cat "${v}" >> "src/reference/${k}.md"
        echo "Output(${v}) file ${k}.md"
      ''
    ) optionsMd) }

    mdbook build -d ./build
    cp -r ./build $out

    subdir="/unstable"
    if [ -z "${toString unstable}" ]; then
      subdir="/${apiVersion}"
    fi
  '';

  installPhase = "true";
}
