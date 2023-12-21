final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    local-ai-cublas = callPackage ./local-ai { buildType = "cublas"; };
    local-ai-openblas = callPackage ./local-ai { buildType = "openblas"; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
  };
}
