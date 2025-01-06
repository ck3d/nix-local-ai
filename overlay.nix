final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    chatbot-ui = callPackage ./chatbot-ui { };
    chatbot-ui-legacy = callPackage ./chatbot-ui-legacy { };
    open-webui = callPackage ./open-webui { };
  };
}
