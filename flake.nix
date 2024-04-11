{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      overlays.default = import ./overlay.nix;
    in
    {
      inherit overlays;

      packages = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = { allowUnfree = true; };
            };
          in
          pkgs.nix-local-ai
          // { default = pkgs.nix-local-ai.local-ai; }
        );

      legacyPackages = forAllSystems
        (system:
          let
            pkgs = import nixpkgs-unstable {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = { allowUnfree = true; };
            };
          in
          { unstable = pkgs.nix-local-ai; }
        );

      checks = forAllSystems
        (system:
          let
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = { allowUnfree = true; };
            };
          in
          {
            inherit (pkgs-unstable.nix-local-ai.local-ai.passthru.tests) version health tts;
          }
          // builtins.listToAttrs
            (map
              (type: {
                name = "health-" + type;
                value = (pkgs-unstable.nix-local-ai.local-ai.override {
                  "with_${type}" = true;
                  # tinydream can not compiled with cublas gcc
                  with_tinydream = type != "cublas";
                }).passthru.tests.health;
              })
              [ "cublas" "clblas" "openblas" ])
        );
    };
}
