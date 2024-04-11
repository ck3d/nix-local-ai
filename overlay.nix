final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    local-ai-cublas = callPackage ./local-ai { with_cublas = true; };
    local-ai-clblas = callPackage ./local-ai { with_clblas = true; };
    local-ai-openblas = callPackage ./local-ai { with_openblas = true; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
    chatbot-ui-legacy = callPackage ./chatbot-ui-legacy { };
    open-webui = callPackage ./open-webui { };
  };
}
