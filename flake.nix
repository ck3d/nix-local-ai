{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      overlays.default = import ./overlay.nix;

      packages = forAllSystems
        (system:
          let
            pkgs-stable = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues self.overlays;
              config = { allowUnfree = true; };
            };
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              overlays = builtins.attrValues self.overlays;
              config = { allowUnfree = true; };
            };
          in
          {
            local-ai-openblas-nixos2311 = pkgs-stable.nix-local-ai.local-ai.override { with_openblas = true; };
            local-ai-cublas-nixos2311 = pkgs-stable.nix-local-ai.local-ai.override { with_cublas = true; };
            default = pkgs-unstable.nix-local-ai.local-ai;
          }
          // pkgs-unstable.nix-local-ai
          // builtins.listToAttrs
            (map
              (type: {
                name = "local-ai-" + type;
                value = pkgs-unstable.nix-local-ai.local-ai.override {
                  "with_${type}" = true;
                  # tinydream can not compiled with cublas gcc
                  with_tinydream = type != "cublas";
                };
              }) [ "cublas" "clblas" "openblas" ])
        );

      checks = forAllSystems
        (system:
          let
            packages = self.packages.${system};
          in
          packages
          // (builtins.foldl'
            (acc: package: acc // (lib.mapAttrs'
              (test: value: { name = package + "-test-" + test; inherit value; })
              (packages.${package}.tests or { }))
            )
            { }
            (builtins.attrNames packages))
        );
    };
}
