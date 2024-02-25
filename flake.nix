{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
    prisma-utils.url = "github:VanCoding/nix-prisma-utils";
  };

  outputs = { self, nixpkgs, flake-utils, devenv, prisma-utils, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        # Prisma wants to install pre-compiled binaries and NixOS does not swing that way
        # This utils enables the flake to follow the package-lock version instead of
        # trying to match the package.json version to pkgs.nodePackages.prisma
        # https://github.com/prisma/prisma/issues/3026
        prisma = (prisma-utils.lib.prisma-factory {
          nixpkgs = pkgs;

          prisma-fmt-hash = "sha256-3YArAgnfj95UdT/7+P+v4Is7t746SAoHUm77XtJVC8s=";
          query-engine-hash = "sha256-XGDTAimNXLJqdLb4q8YKBg0+GCCeQz09bUJUQesFOfo=";
          libquery-engine-hash = "sha256-Lj0bOALAANtru6SLGrdtFQ1NUaupXe/l692g3Zk7l2Q=";
          schema-engine-hash = "sha256-99TWwC3lqVl3US8W5lhNt9iBiQgt5dsGRckbnSXMMp0=";
        }).fromNpmLock ./package-lock.json;
      in
      {
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              name = "t3-crud";
              languages = {
                javascript = {
                  enable = true;
                };
              };
              packages = with pkgs; [
                bruno
              ];
              enterShell = prisma.shellHook;
              env = with pkgs; {
                LD_LIBRARY_PATH = lib.makeLibraryPath [ openssl ];
              };
            }
          ];
        };
      });
}
