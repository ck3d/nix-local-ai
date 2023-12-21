{
  description = "Nix package of LocalAI";

  # package go_1_21 is needed
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    rec {
      overlays.default = import ./overlay.nix;

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
    };
}
