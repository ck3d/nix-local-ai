{ mkYarnPackage
, lib
, fetchFromGitHub
, runCommand
, libuuid
, jq
, callPackage
, makeWrapper
, nodejs
, python3
  # canvas
, pkg-config
, pixman
, cairo
, pango
}:
let
  pname = "flowise";
  version = "1.3.6";
  vanillaSrc = fetchFromGitHub {
    owner = "FlowiseAI";
    repo = "Flowise";
    rev = "${pname}@${version}";
    hash = "sha256-7KYxS2YJROUttK+GF9YlgOG4VLQWtrQoMXH3MCqQAoQ=";
  };

  src = runCommand "patched-source"
    { nativeBuildInputs = [ jq ]; } ''
    cp -r ${vanillaSrc} $out
    chmod -R +w $out
    jq --slurp --from-file ${./package.jq} \
      ${vanillaSrc}/package.json ${vanillaSrc}/packages/*/package.json \
      > $out/package.json
    cp ${./yarn.lock} $out/yarn.lock
  '';
in
mkYarnPackage {
  pname = "flowise";
  inherit version src;

  extraBuildInputs = [ makeWrapper ];

  pkgConfig.sqlite3 = {
    nativeBuildInputs = [
      nodejs.pkgs.node-pre-gyp
      python3
    ];
    postInstall = ''
      export CPPFLAGS="-I${nodejs}/include/node"
      node-pre-gyp install --prefer-offline --build-from-source \
        --nodedir=${nodejs}/include/node
    '';
  };

  pkgConfig.canvas = {
    nativeBuildInputs = [
      nodejs.pkgs.node-pre-gyp
      python3
      pkg-config
    ];
    buildInputs = [
      pixman
      cairo
      pango
    ];
    postInstall = ''
      export CPPFLAGS="-I${nodejs}/include/node"
      node-pre-gyp install --prefer-offline --build-from-source \
        --nodedir=${nodejs}/include/node
    '';
  };

  installPhase = ''
    rm .yarnrc
    ln -s ../deps/${pname}/packages/components node_modules/flowise-components
    ln -s ../deps/${pname}/packages/ui node_modules/flowise-ui
    cd deps/${pname}
    sed -i packages/server/src/index.ts \
      -e "s;__dirname, '\.\.', 'uploads';'uploads';"
    yarn --offline build
    rm node_modules
    cp -r . $out
    makeWrapper \
      $out/packages/server/bin/run \
      $out/bin/${pname} \
      --suffix "LD_LIBRARY_PATH" : ${lib.makeLibraryPath [ libuuid.lib ]}
    cp -r ../../node_modules $out
    cd $out/node_modules
    ln -fs ../packages/components flowise-components
    ln -fs ../packages/ui flowise-ui
  '';
  distPhase = ":";
}
