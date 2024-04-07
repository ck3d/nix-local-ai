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
    rev = "v${version}";
    hash = "sha256-AmWLWzxt8+Nz7ahYTtMwtjxVzqTYZeMfKTF1IOi0lsA=";
  };

  npmDepsHash = "sha256-VW89XnzputCWw5dOAKg09kve7IMNlxGS6ShYEo1ZC7s=";

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
