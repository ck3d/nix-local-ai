{ buildNpmPackage
, nodePackages
, fetchFromGitHub
, runtimeShell
}:
buildNpmPackage rec {
  pname = "open-webui";
  version = "0.1.117";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "${version}";
    hash = "";
  };

  npmDepsHash = "";

  postInstall = ''
    mkdir -p $out/lib
    cp -R ./build/. $out/lib

    mkdir -p $out/bin
    cat <<EOF >>$out/bin/${pname}
    #!${runtimeShell}
    ${nodePackages.http-server}/bin/http-server $out/lib
    EOF
    chmod +x $out/bin/${pname}
  '';
}
