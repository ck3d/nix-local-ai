final: prev:
let
  inherit (final) callPackage;
in
{
  nix-local-ai = {
    local-ai = callPackage ./local-ai { };
    local-ai-tts = callPackage ./local-ai { with_tts = true; }; # broken
    local-ai-tinydream = callPackage ./local-ai { enable_tinydream = true; };
    local-ai-stablediffusion = callPackage ./local-ai { with_stablediffusion = true; }; # broken
    local-ai-cublas = callPackage ./local-ai { with_cublas = true; };
    local-ai-openblas = callPackage ./local-ai { with_openblas = true; };
    flowise = callPackage ./flowise { };
    chatbot-ui = callPackage ./chatbot-ui { };
  };
}
