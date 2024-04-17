{ buildNpmPackage
, nodejs
, fetchFromGitHub
, makeWrapper
, fetchzip
, inter
}:
buildNpmPackage rec {
  pname = "chatbot-ui-legacy";
  version = "20230404";

  src = fetchFromGitHub {
    owner = "mckaywrigley";
    repo = "chatbot-ui";
    rev = "6bdbf1cbe38ff3a40c6d14df4610656ea26b174e"; # branch legacy
    hash = "sha256-b9qrlKUs2PH0uhQesdbWMbpX38S+CFSovxtYcKII6Kk=";
  };

  patches = [
    ./0001-next.config-Add-output-standalone.patch
    ./0002-Use-local-font.patch
    ./0003-Update-npm-packages.patch
  ];

  npmDepsHash = "sha256-YF2TFXjdPyCVNWCJreP/GCAuVmKZf25m4gbyyX5OI+A=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postConfigure = ''
    cp ${inter.src}/*.ttf .
  '';

  # inspired by
  # https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile
  postInstall = ''
    rm -r $out/lib
    dest=$out/share/${pname}
    mkdir -p $dest/.next $out/bin
    cp -r -t $dest .next/standalone/. public
    cp -r -t $dest/.next .next/static
    makeWrapper ${nodejs}/bin/node $out/bin/${pname} \
      --set NEXT_TELEMETRY_DISABLED 1 \
      --add-flags "$dest/server.js"
  '';
}
