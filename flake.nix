{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pathmut.url = "github:rutrum/pathmut";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pathmut,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        _pathmut = pathmut.packages.${system}.pathmut;
        pkgs = import nixpkgs {
          inherit system;
        };
        pandoc-mustache = pkgs.python3Packages.buildPythonApplication rec {
            pname = "pandoc-mustache";
            version = "0.1.0";

            src = pkgs.fetchFromGitHub {
                owner = "michaelstepner";
                repo = "pandoc-mustache";
                rev = "0.1.0";
                sha256 = "sha256-lgbQV4X2N4VuIEtjeSA542yqGdIs5QQ7+bdCoy/aloE=";
            };

            propagatedBuildInputs = with pkgs.python3Packages; [
                pyyaml
                pystache
                future
                panflute
            ];
        };
        checkexec = pkgs.rustPlatform.buildRustPackage rec {
            pname = "checkexec";
            version = "0.2.0";

            src = pkgs.fetchCrate {
                inherit pname version;
                sha256 = "sha256-vqpqMAgt/2FuTkQXtw9he0aOf7/dLL0OoThO7VO0XMc=";
            };

            cargoSha256 = "sha256-BRPet34RmtYpXpxEcF5BLbfmCe3SYEr/WSPPeLijBaE=";
            cargoDepsName = pname;
        };
        aspell_with_dicts = pkgs.aspellWithDicts(d: [d.en]);
      in
        with pkgs; {
          devShells.default = mkShell {
            name = "cs142";
            # set the right data directory for aspell
            buildInputs = [
              pandoc
              watchexec
              fd
              just
              tree
              _pathmut
              checkexec
              pandoc-include
              pandoc-mustache
              texlive.combined.scheme-medium
              aspell_with_dicts
              yq-go
              # haskellPackages.pandoc-columns
            ];
          };
        }
    );
}
