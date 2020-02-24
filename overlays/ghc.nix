{ haskell-nix-source
}:

self: super:
# If anyone is aware of a way to lessen code duplication here, please let me know.
let
  installDeps = targetPrefix: ''
  for P in $($out/bin/${targetPrefix}ghc-pkg list --simple-output | sed 's/-[0-9][0-9.]*//g'); do
    mkdir -p $out/exactDeps/$P
    touch $out/exactDeps/$P/configure-flags
    touch $out/exactDeps/$P/cabal.config
    if id=$($out/bin/${targetPrefix}ghc-pkg field $P id --simple-output); then
      echo "--dependency=$P=$id" >> $out/exactDeps/$P/configure-flags
    elif id=$($out/bin/${targetPrefix}ghc-pkg field "z-$P-z-*" id --simple-output); then
      name=$($out/bin/${targetPrefix}ghc-pkg field "z-$P-z-*" name --simple-output)
      # so we are dealing with a sublib. As we build sublibs separately, the above
      # query should be safe.
      echo "--dependency=''${name#z-$P-z-}=$id" >> $out/exactDeps/$P/configure-flags
    fi
    if ver=$($out/bin/${targetPrefix}ghc-pkg field $P version --simple-output); then
      echo "constraint: $P == $ver" >> $out/exactDeps/$P/cabal.config
      echo "constraint: $P installed" >> $out/exactDeps/$P/cabal.config
    fi
  done
  mkdir -p $out/evalDeps
  for P in $($out/bin/${targetPrefix}ghc-pkg list --simple-output | sed 's/-[0-9.]*//g'); do
    touch $out/evalDeps/$P
    if id=$($out/bin/${targetPrefix}ghc-pkg field $P id --simple-output); then
      echo "package-id $id" >> $out/evalDeps/$P
    fi
  done
  '';
  bootPkgs = with self.buildPackages; {
    ghc = buildPackages.haskell-nix.bootstrap.compiler.ghc865;
    inherit (self.haskell-nix.bootstrap.packages) alex happy hscolour;
  };
  sphinx = with self.buildPackages; (python3Packages.sphinx_1_7_9 or python3Packages.sphinx);
  # Every other patch that would apply to GHC 8.10.1 has been upstreamed into it
  ghc8101Patches = map (patch: "${haskell-nix-source}/overlays/patches/ghc/" + patch) [
    # fails to patch
    #"mistuke-ghc-err_clean_up_error_handler-8ab1a89af89848f1713e6849f189de66c0ed7898.diff"
    "ghc-8.4.3-Cabal2201-no-hackage-tests.patch"
    "cabal-host.patch"
  ];
in {
  haskell-nix = super.haskell-nix // {
    compiler = super.haskell-nix.compiler // {
      ghc8101 = self.callPackage "${haskell-nix-source}/compiler/ghc" {
        extra-passthru = { buildGHC = self.buildPackages.haskell-nix.compiler.ghc8101; };
        
        inherit bootPkgs sphinx installDeps;
        
        buildLlvmPackages = self.buildPackages.llvmPackages_7;
        llvmPackages = self.llvmPackages_7;
        
        src-spec = rec {
          version = "8.10.0.20191210";
          url = "https://downloads.haskell.org/ghc/8.10.1-alpha2/ghc-${version}-src.tar.xz";
          sha256 = "1mmv8s9cs41kp7wh1qqnzin5wv32cvs3lmzgda7njz0ssqb0mmvj";
        };
        
        ghc-patches = ghc8101Patches;
      };
    };
  };
}
