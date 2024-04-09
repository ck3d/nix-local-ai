{ buildNpmPackage
, nodejs
, fetchFromGitHub
, makeWrapper
, fetchzip
}:
let
  inter = fetchzip {
    url = "https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip";
    stripRoot = false;
    hash = "sha256-6kUQUTFtxiJEU6sYC6HzMwm1H4wvaKIoxoY3F6GJJa8=";
  };
in
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
    # - updated package.json as recommended by npm
    # - use local font
    # - use next standalone output
    ./default.patch
  ];

  npmDepsHash = "sha256-Cg3TMIfpIEhoxYwXxlPPdWSsqkI+Wpvq98e1AxDC270=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postConfigure = ''
    cp "${inter}/Inter Desktop/Inter-Regular.otf" .
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