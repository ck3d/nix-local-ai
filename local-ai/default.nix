{ stdenv
, fetchFromGitHub
, ncurses
, cmake
, buildGoModule
}:
let
  go-llama = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-llama.cpp";
    rev = "cb8d7cd4cb95725a04504a9e3a26dd72a12b69ac";
    hash = "sha256-l1E85bSMm5S0bIBoPRGdzOmHtStAwufDQgSx8bV1HV4=";
    fetchSubmodules = true;
  };

  llama_cpp = fetchFromGitHub {
    owner = "mudler";
    repo = "llama.cpp";
    rev = "48ce8722a05a018681634af801fd0fd45b3a87cc";
    hash = "sha256-V2MrTl3AZc0oMV6A0JkLzsEbcPOpLTQKzX84Y1j3mHA=";
    fetchSubmodules = true;
  };

  go-ggllm = fetchFromGitHub {
    owner = "mudler";
    repo = "go-ggllm.cpp";
    rev = "862477d16eefb0805261c19c9b0d053e3b2b684b";
    hash = "sha256-WMinA9eFsuYqNywBqlAz2n4BvD6RCfi6xzwyZQCAHW4=";
    fetchSubmodules = true;
  };


  go-ggml-transformers = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-ggml-transformers.cpp";
    rev = "ffb09d7dd71e2cbc6c5d7d05357d230eea6f369a";
    hash = "sha256-WdCj6cfs98HvG3jnA6CWsOtACjMkhSmrKw9weHkLQQ4=";
    fetchSubmodules = true;
  };

  gpt4all = fetchFromGitHub {
    owner = "nomic-ai";
    repo = "gpt4all";
    rev = "cfd70b69fcf5e587b8e0e3e9b9aaa90e19cbbc51";
    hash = "sha256-1Fpi1wymSg1B8hAEIKK8Z57YcZgTEznClBuDZzwcryc=";
    fetchSubmodules = true;
  };

  go-piper = fetchFromGitHub {
    owner = "mudler";
    repo = "go-piper";
    rev = "56b8a81b4760a6fbee1a82e62f007ae7e8f010a7";
    hash = "sha256-5AAYLG2rGA4uf93SBX1poeW8ck/B4ZAsPxIHrQ6BytQ=";
    fetchSubmodules = true;
  };

  go-rwkv = fetchFromGitHub {
    owner = "donomii";
    repo = "go-rwkv.cpp";
    rev = "f5a8c45396741470583f59b916a2a7641e63bcd0";
    hash = "sha256-+p0J9c5EKf/KVSb8xtUCXo9cYfX1p5Ex7yRtOsEKQ1g=";
    fetchSubmodules = true;
  };

  whisper = fetchFromGitHub {
    owner = "ggerganov";
    repo = "whisper.cpp";
    rev = "85ed71aaec8e0612a84c0b67804bde75aa75a273";
    hash = "sha256-y36DZc+w0CJMI8DA77NZqLh/x1oiaiQlmDuEYd7Vt/k=";
    fetchSubmodules = true;
  };

  go-bert = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-bert.cpp";
    rev = "6069103f54b9969c02e789d0fb12a23bd614285f";
    hash = "sha256-MadP8/SMJGfZTInVn2R2HeOUsvZsPScnfw6+xc3pBOc=";
    fetchSubmodules = true;
  };

  bloomz = fetchFromGitHub {
    owner = "go-skynet";
    repo = "bloomz.cpp";
    rev = "1834e77b83faafe912ad4092ccf7f77937349e2f";
    hash = "sha256-Ys/kjBL8WMuByUSdjxtc5bCNWI04CcENuwRukhvvlw0=";
    fetchSubmodules = true;
  };

  go-stable-diffusion = fetchFromGitHub {
    owner = "mudler";
    repo = "go-stable-diffusion";
    rev = "d89260f598afb809279bc72aa0107b4292587632";
    hash = "sha256-B3irqzaWKcfZd129SaIQrdIHyWhmLy9zCwxwAaivRnA=";
    fetchSubmodules = true;
  };

in
buildGoModule rec {
  pname = "local-ai";
  version = "1.21.0";

  src = fetchFromGitHub {
    owner = "go-skynet";
    repo = "LocalAI";
    rev = "v${version}";
    hash = "sha256-uOeKT9BsTWfpPaRk/7jh+5fq8IlEeDQ0fi9b3TnF8iM=";
  };

  vendorSha256 = "sha256-JTqaDKJikH9xWxhFwI3ZrKz1srlT1Dx1my4WcTB/dWE=";

  # Workaround for
  # `cc1plus: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]`
  # when building jtreg
  env.NIX_CFLAGS_COMPILE = "-Wformat";

  postPatch = ''
    sed -i Makefile \
      -e 's;git clone.*go-llama$;cp -r --no-preserve=mode,ownership ${go-llama} go-llama;' \
      -e 's;git clone.*llama\.cpp.*$;cp -r --no-preserve=mode,ownership ${llama_cpp} llama\.cpp;' \
      -e 's;git clone.*go-ggllm$;cp -r --no-preserve=mode,ownership ${go-ggllm} go-ggllm;' \
      -e 's;git clone.*go-ggml-transformers$;cp -r --no-preserve=mode,ownership ${go-ggml-transformers} go-ggml-transformers;' \
      -e 's;git clone.*gpt4all$;cp -r --no-preserve=mode,ownership ${gpt4all} gpt4all;' \
      -e 's;git clone.*go-piper$;cp -r --no-preserve=mode,ownership ${go-piper} go-piper;' \
      -e 's;git clone.*go-rwkv$;cp -r --no-preserve=mode,ownership ${go-rwkv} go-rwkv;' \
      -e 's;git clone.*whisper\.cpp\.git$;cp -r --no-preserve=mode,ownership ${whisper} whisper\.cpp;' \
      -e 's;git clone.*go-bert$;cp -r --no-preserve=mode,ownership ${go-bert} go-bert;' \
      -e 's;git clone.*bloomz$;cp -r --no-preserve=mode,ownership ${bloomz} bloomz;' \
      -e 's;git clone.*diffusion$;cp -r --no-preserve=mode,ownership ${go-stable-diffusion} go-stable-diffusion;' \
      -e 's, && git checkout.*,,g' \
      -e '/mod download/ d'
  '';

  modBuildPhase = ''
    make prepare-sources
    go mod tidy -v
  '';

  proxyVendor = true;

  buildPhase = ''
    make VERSION=v${version} build
  '';

  installPhase = ''
    install -Dt $out/bin local-ai
  '';

  nativeBuildInputs = [
    ncurses
    cmake
  ];
}
