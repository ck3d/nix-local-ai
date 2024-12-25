{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs =
    {
      self,
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
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            overlays = builtins.attrValues self.overlays;
            config = {
              allowUnfree = true;
            };
          };
        in
        {
          default = pkgs-unstable.nix-local-ai.local-ai;
        }
        // pkgs-unstable.nix-local-ai
        // builtins.listToAttrs (
          map
            (type: {
              name = "local-ai-" + type;
              value = pkgs-unstable.nix-local-ai.local-ai.override {
                "with_${type}" = true;
                # tinydream can not compiled with cublas gcc
                with_tinydream = type != "cublas";
              };
            })
            [
              "cublas"
              "clblas"
              "openblas"
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
