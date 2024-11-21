{
  description = "Python shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ];
      localPkgs = forAllSystems (system: import nixpkgs { system=system; overlays=serverOverlays; config = serverConfig; });
      serverPkgs = forAllSystems (system: import nixpkgs { system=system; overlays=serverOverlays; config = serverConfig; });
      tex = pkgs: (pkgs.texlive.combine { 
        inherit (pkgs.texlive) scheme-small
          latexmk biber biblatex inconsolata helvetic
          photobook
          varwidth
        ;
      });
      serverOverlays = [
        (final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ 
            (pyFinal: pyPrev: {
              #autoawq = final.python3.pkgs.callPackage ./nix/autoawq { inherit (pyFinal.pkgs); };
            })
          ];
        })
      ];
      serverConfig= {
        allowUnfree = true;
      };
      pythonPackages = (ps: with ps; [
        ipython
        opencv4
        requests
      ]);
      otherPackages = (ps: with ps; [ 
        bash
        unzip 
        gnumake
        jq
      ]);
    in
    {
      devShells = forAllSystems (system: {
        default = let pkgs = localPkgs.${system}; in pkgs.mkShellNoCC {
          packages = with pkgs; [
            (python3.withPackages pythonPackages)
            (tex pkgs)
          ] ++ (otherPackages pkgs);
        };
      });
    };
}
