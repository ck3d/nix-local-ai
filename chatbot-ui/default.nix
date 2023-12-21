{ mkYarnPackage
, buildNpmPackage
, fetchFromGitHub
, lib
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
  pname = "chatbot-ui";
  version = "20230820";

  src = fetchFromGitHub {
    owner = "mckaywrigley";
    repo = pname;
    rev = "138950c5520e80f69f059ecf0aea6a91a727cff9";
    hash = "sha256-P0n9PXaJOFW4PH8crcQkfSR+dlYlt/5rEghddFPssxg=";
  };

  patches = [
    ./font.patch
  ];

  npmDepsHash = "sha256-7mReAoIQcIk+n6UDYtLLlTyuT2F11jY9rvwJiykouVw=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postConfigure = ''
    cp "${inter}/Inter Desktop/Inter-Regular.otf" pages
  '';

  postInstall = ''
    rm -r .next/cache
    rm -r $out/lib
    mv -t $out \
      .next public next.config.js next-i18next.config.js node_modules
    makeWrapper $out/node_modules/.bin/next $out/${pname} \
      --add-flags "start"
  '';
}
