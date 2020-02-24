{ haskell-nix-source
}:

[
  (import ./overlays/ghc.nix { inherit haskell-nix-source; })
]
