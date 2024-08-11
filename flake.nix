{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs-2405.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs = { self, nixpkgs-2405, nixpkgs-unstable }:
    let
      inherit (nixpkgs-2405) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      overlays.default = import ./overlay.nix;

      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);

      packages = forAllSystems
        (system:
          let
            pkgs-2405 = import nixpkgs-2405 {
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
            local-ai-nixos2405 = pkgs-2405.nix-local-ai.local-ai;
            local-ai-openblas-nixos2405 = pkgs-2405.nix-local-ai.local-ai.override { with_openblas = true; };
            local-ai-cublas-nixos2405 = pkgs-2405.nix-local-ai.local-ai.override { with_cublas = true; };
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
