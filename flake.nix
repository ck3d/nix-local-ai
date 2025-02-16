{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs-2411.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs-2411,
      nixpkgs-unstable,
    }:
    let
      inherit (nixpkgs-unstable) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      overlays.default = import ./overlay.nix;

      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);

      packages = forAllSystems (
        system:
        let
          pkgs-2411 = import nixpkgs-2411 {
            inherit system;
            overlays = builtins.attrValues self.overlays;
            config.allowUnfree = true;
          };

          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            overlays = builtins.attrValues self.overlays;
            config.allowUnfree = true;
          };
        in
        {
          local-ai-nixos2411 = pkgs-2411.nix-local-ai.local-ai;
          local-ai-openblas-nixos2411 = pkgs-2411.nix-local-ai.local-ai.override { with_openblas = true; };
          local-ai-cublas-nixos2411 = pkgs-2411.nix-local-ai.local-ai.override { with_cublas = true; };
          default = pkgs-unstable.nix-local-ai.local-ai;
        }
        // pkgs-unstable.nix-local-ai
        // builtins.listToAttrs (
          map
            (type: {
              name = "local-ai-" + type;
              value = pkgs-unstable.nix-local-ai.local-ai.override {
                "with_${type}" = true;
              };
            })
            [
              "cublas"
              "clblas"
              "openblas"
              "vulkan"
            ]
        )
      );

      checks = forAllSystems (
        system:
        let
          packages = self.packages.${system};
        in
        packages
        // (builtins.foldl' (
          acc: package:
          acc
          // (lib.mapAttrs' (test: value: {
            name = package + "-test-" + test;
            inherit value;
          }) (packages.${package}.tests or { }))
        ) { } (builtins.attrNames packages))
      );
    };
}
