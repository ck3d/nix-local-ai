final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
  };
}
