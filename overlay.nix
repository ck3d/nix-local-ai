final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    local-ai-cublas = callPackage ./local-ai { buildType = "cublas"; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
  };
}
