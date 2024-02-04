{ stdenv
, lib
, fetchFromGitHub
, ncurses
, abseil-cpp
, protobuf
, grpc
, openssl
, openblas
  # needed for audio-to-text
, ffmpeg
, opencv
, ncnn
, sonic
, spdlog
, fmt
, onnxruntime
, cmake
, buildGoModule
, pkg-config
, cudaPackages
, makeWrapper
, runCommand
, buildType ? ""
  # TODO: provide the right version of ncnn
, enableStablediffusion ? false
  # TODO: provide onnxruntime in the right way
, enableTts ? false
  # ./tiny-dream/tinydream.hpp:89:13: error: call to non-'constexpr' function 'std::function<_Res(_ArgTypes ...)>::operator bool()
  #  const [with _Res = void; _ArgTypes = {const char*, int, void*}]'
  # TODO: fix compiler error
  # possible workaround: Update gcc by switching nixpkgs to nixos-unstable
, enableTinydream ? false
}:
let
  go-llama = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-llama.cpp";
    rev = "aeba71ee842819da681ea537e78846dc75949ac0";
    hash = "sha256-ELoaJg7wOHloQws+do6TZUo7zOxUP0E85v80BlpUOJA=";
    fetchSubmodules = true;
  };

  go-llama-ggml = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-llama.cpp";
    rev = "50cee7712066d9e38306eccadcfbb44ea87df4b7";
    hash = "sha256-5qwUSg56fyHk5x8NgwLrgl+9Ibl2GTBP1Aq5sAvTs+s=";
    fetchSubmodules = true;
  };

  llama_cpp = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = "6db2b41a76ee78d5efdd5c3cddd5d7ad3f646855";
    hash = "sha256-fI5V4nly0G+Xh2VOJgf5SGGpL+qgpdrnAOtq18e81g8=";
    fetchSubmodules = true;
  };

  llama_cpp' = runCommand "llama_cpp_src" { } ''
    cp -r --no-preserve=mode,ownership ${llama_cpp} $out
    sed -i $out/CMakeLists.txt \
      -e 's;pkg_check_modules(DepBLAS REQUIRED openblas);pkg_check_modules(DepBLAS REQUIRED openblas64);'
  '';

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
    rev = "27a8b020c36b0df8f8b82a252d261cda47cf44b8";
    hash = "sha256-djq1eK6ncvhkO3MNDgasDBUY/7WWcmZt/GJsHAulLdI=";
    fetchSubmodules = true;
  };

  go-piper = fetchFromGitHub {
    owner = "mudler";
    repo = "go-piper";
    rev = "d6b6275ba037dabdba4a8b65dfdf6b2a73a67f07";
    hash = "sha256-p589giBsEPsoR+RQU7qfGfpfqpTdBI51lvnLs4DmE0Y=";
    fetchSubmodules = true;
  };

  go-rwkv = fetchFromGitHub {
    owner = "donomii";
    repo = "go-rwkv.cpp";
    rev = "633c5a3485c403cb2520693dc0991a25dace9f0f";
    hash = "sha256-BECmBLbtAh5pdZZz0NBLbt+BX2TaC2NjHYwSEEAFPlI=";
    fetchSubmodules = true;
  };

  whisper = fetchFromGitHub {
    owner = "ggerganov";
    repo = "whisper.cpp";
    rev = "9286d3f584240ba58bd44a1bd1e85141579c78d4";
    hash = "sha256-hLPtfJVYiopnSdDqu9n/k9Avb4ibgbjmrVr81BTWW/w=";
    fetchSubmodules = true;
  };

  go-bert = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-bert.cpp";
    rev = "6abe312cded14042f6b7c3cd8edf082713334a4d";
    hash = "sha256-lh9cvXc032Eq31kysxFOkRd0zPjsCznRl0tzg9P2ygo=";
    fetchSubmodules = true;
  };

  go-stable-diffusion = fetchFromGitHub {
    owner = "mudler";
    repo = "go-stable-diffusion";
    rev = "902db5f066fd137697e3b69d0fa10d4782bd2c2f";
    hash = "sha256-MbVYeWQF/aJNsg2NpTMVx5tD31BK5pQ8Zg92uoWRkcU=";
    fetchSubmodules = true;
  };

  go-tiny-dream = fetchFromGitHub {
    owner = "M0Rf30";
    repo = "go-tiny-dream";
    rev = "772a9c0d9aaf768290e63cca3c904fe69faf677a";
    hash = "sha256-r+wzFIjaI6cxAm/eXN3q8LRZZz+lE5EA4lCTk5+ZnIY=";
    fetchSubmodules = true;
  };

  go-tiny-dream' = runCommand "go_tiny_dream_src" { } ''
    cp -r --no-preserve=mode,ownership ${go-tiny-dream} $out
    sed -i $out/Makefile \
      -e 's;lib/libncnn;lib64/libncnn;g'
  '';

  GO_TAGS = lib.optional enableTinydream "tinydream"
    ++ lib.optional enableTts "tts"
    ++ lib.optional enableStablediffusion "stablediffusion";
in
buildGoModule rec {
  pname = "local-ai";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "go-skynet";
    repo = "LocalAI";
    rev = "v${version}";
    hash = "sha256-w5dRIqan6+4idW2dKVEH0xeQ4iAspmAnxRyGAozbRvY=";
  };

  vendorHash = "sha256-WUgDyRzShftJ15yumlvcSN0rUx8ytQPQGAO37AxMHeA=";

  # Workaround for
  # `cc1plus: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]`
  # when building jtreg
  env.NIX_CFLAGS_COMPILE = "-Wformat"
    + lib.optionalString enableStablediffusion " -isystem ${opencv}/include/opencv4";

  postPatch =
    let
      cp = "cp -r --no-preserve=mode,ownership";
    in
    ''
      sed -i Makefile \
        -e 's;git clone.*go-llama$;${cp} ${go-llama} sources/go-llama;' \
        -e 's;git clone.*go-llama-ggml$;${cp} ${go-llama-ggml} sources/go-llama-ggml;' \
        -e 's;git clone.*go-ggml-transformers$;${cp} ${go-ggml-transformers} sources/go-ggml-transformers;' \
        -e 's;git clone.*gpt4all$;${cp} ${gpt4all} sources/gpt4all;' \
        -e 's;git clone.*go-piper$;${cp} ${go-piper} sources/go-piper;' \
        -e 's;git clone.*go-rwkv$;${cp} ${go-rwkv} sources/go-rwkv;' \
        -e 's;git clone.*whisper\.cpp$;${cp} ${whisper} sources/whisper\.cpp;' \
        -e 's;git clone.*go-bert$;${cp} ${go-bert} sources/go-bert;' \
        -e 's;git clone.*diffusion$;${cp} ${go-stable-diffusion} sources/go-stable-diffusion;' \
        -e 's;git clone.*go-tiny-dream$;${cp} ${go-tiny-dream'} sources/go-tiny-dream;' \
        -e 's, && git checkout.*,,g' \
        -e '/mod download/ d' \

      sed -i backend/cpp/llama/Makefile \
        -e 's;git clone.*llama\.cpp$;${cp} ${llama_cpp'} llama\.cpp;' \
        -e 's, && git checkout.*,,g' \

    ''
  ;

  modBuildPhase = ''
    mkdir sources
    make prepare-sources
    go mod tidy -v
  '';

  proxyVendor = true;

  buildPhase = ''
    mkdir sources
    make \
      VERSION=v${version} \
      BUILD_TYPE=${buildType} \
      GO_TAGS="${builtins.concatStringsSep " " GO_TAGS}" \
      build
  '';

  installPhase = ''
    install -Dt $out/bin ${pname}
  '';

  buildInputs = [
    abseil-cpp
    protobuf
    grpc
    openssl
  ]
  ++ lib.optionals enableStablediffusion [ opencv ncnn ]
  ++ lib.optionals enableTts [ sonic spdlog fmt onnxruntime ]
  ++ lib.optional (buildType == "cublas") cudaPackages.cudatoolkit
  ++ lib.optional (buildType == "openblas") openblas.dev
  ;

  # patching rpath with patchelf doens't work. The execuable
  # raises an segmentation fault
  postFixup = ''
    wrapProgram $out/bin/${pname} \
  '' + lib.optionalString (buildType == "cublas") ''
    --prefix LD_LIBRARY_PATH : "${cudaPackages.libcublas}/lib:${cudaPackages.cuda_cudart}/lib:/run/opengl-driver/lib" \
  '' + lib.optionalString (buildType == "openblas") ''
    --prefix LD_LIBRARY_PATH : "${openblas}/lib" \
  '' + ''
    --prefix PATH : "${ffmpeg}/bin"
  '';

  nativeBuildInputs = [
    ncurses
    cmake
    makeWrapper
  ]
  ++ lib.optional (buildType == "openblas") pkg-config
  ++ lib.optional (buildType == "cublas") cudaPackages.cuda_nvcc
  ;
}
