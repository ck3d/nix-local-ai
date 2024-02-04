final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    local-ai-tts = callPackage ./local-ai { enableTts = true; }; # broken
    local-ai-tinydream = callPackage ./local-ai { enableTinydream = true; };
    local-ai-stablediffusion = callPackage ./local-ai { enableStablediffusion = true; }; # broken
    local-ai-cublas = callPackage ./local-ai { buildType = "cublas"; };
    local-ai-openblas = callPackage ./local-ai { buildType = "openblas"; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
  };
}
