{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    npmlock2nix = {
      url = "github:nix-community/npmlock2nix";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    npmlock2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = (import nixpkgs {
        inherit system;
        config = {
          allowBroken = true;
        };
      });
      erl = pkgs.beam.interpreters.erlang_27;
      erlangPackages = pkgs.beam.packagesWith erl;
      elixir = erlangPackages.elixir;
      nodejs = pkgs.nodejs_22;
      postgresql = pkgs.postgresql_16;
      npm2nix = pkgs.callPackage npmlock2nix {};
    in
    with pkgs; {
      # ...
      devShells.default = mkShell {
          buildInputs = [
            erlang
            beam.packages.erlang.elixir
            nodejs
            postgresql
            pkgs.gigalixir
          ]
            ++ lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools
            ++ lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [CoreServices]);
        };
    });
}

  
