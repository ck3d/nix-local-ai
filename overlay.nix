final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = rec {
    local-ai = callPackage ./local-ai { inherit llama-cpp; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
    chatbot-ui-legacy = callPackage ./chatbot-ui-legacy { };
    open-webui = callPackage ./open-webui { };
    llama-cpp = callPackage ./llama-cpp { };
  };
}
