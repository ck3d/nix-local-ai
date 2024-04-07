{ buildNpmPackage
, nodejs
, fetchFromGitHub
, makeWrapper
, fetchzip
, vips
, pkg-config
}:
let
  inter = fetchzip {
    url = "https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip";
    stripRoot = false;
    hash = "sha256-6kUQUTFtxiJEU6sYC6HzMwm1H4wvaKIoxoY3F6GJJa8=";
  };
in
buildNpmPackage rec {
  pname = "chatbot-ui";
  version = "20240402";

  src = fetchFromGitHub {
    owner = "mckaywrigley";
    repo = pname;
    rev = "b865b0555f53957e96727bc0bbb369c9eaecd83b";
    hash = "sha256-9xg9Q+0rwxakaDqf5pIw9EDte4pdLUnaRaXtScpLWFI=";
  };

  patches = [
    ./default.patch
  ];

  npmDepsHash = "sha256-708oOP26UOZ0MfclDg5doke8O1OnwbP4m62WXpty8Mc=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    vips
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
