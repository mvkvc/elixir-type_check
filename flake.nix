{
  description = "TypeCheck development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      beam = pkgs.beam.packages.erlang_29;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          beam.elixir_1_20
          beam.rebar3
        ];

        shellHook = ''
          export HEX_HOME="$PWD/.hex"
          export MIX_HOME="$PWD/.mix"
          export MIX_ARCHIVES="$MIX_HOME/archives"
          export PATH="$HEX_HOME/bin:$MIX_HOME/bin:$MIX_HOME/escripts:$PATH"
          export MIX_REBAR3="${beam.rebar3}/bin/rebar3"
          export ERL_AFLAGS="-kernel shell_history enabled"

          mkdir -p "$HEX_HOME" "$MIX_HOME" "$HOME/.local/bin"
          mix local.hex --force --if-missing >/dev/null
        '';
      };
    };
}
