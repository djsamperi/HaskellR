# djs-mods.md: Mods to HaskellR after fork

[nix] Add nix enable: true to stack.yaml
  - Eliminates need for --nix flag.

[gitignore] HaskellR/.gitignore
  - Ignore .o and .hi files

[mathlist] HaskellR/mathlist
  - 1D wavelet and fft Haskell package.
  - Modified HaskellR/stack.yaml to build.
  - Stackage version of mathlist is not used here.
  
[tutorial] HaskellR/examples/tutorial.hs
  - Interactive app that runs examples using R from Haskell.
  - Modified HaskellR/stack.yaml to build.
  - Added config in HaskellR/examples/HaskellR-examples.cabal
  - Added HaskellR/data (used in examples),
  - Modified shell.nix to install required R packages.

[plotwavelets] HaskellR/examples/plotwavelets.hs
  - Uses mathlist package to display 10 Daubechies mother wavelets.
  - Modified HaskellR/stack.yaml to build.
  - Added config in HaskellR/examples/HaskellR-examples.cabal

[hR] HaskellR/hR (experimental)
  - Modified version of Dylan Simon's hR package.
  - Modified HaskellR/stack.yaml to build.

[installwin] HaskellR/installwin.bat
  - Install script for Windows
  - Note: must comment out IHaskell and hR build in stack.yaml
  - Assumes R is in PATH
  - Works with R 4.2.1 (not with R 4.5.1)