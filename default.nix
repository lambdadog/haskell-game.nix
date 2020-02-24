{ haskell-nix-source ? builtins.fetchTarball https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz
}:

let
  haskell-nix = import haskell-nix-source;
in {
  config   = haskell-nix.config;
  overlays = haskell-nix.overlays ++ (import ./overlays.nix {
    inherit haskell-nix-source;
  });
}
