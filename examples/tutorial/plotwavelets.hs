{-# LANGUAGE QuasiQuotes, ViewPatterns, ScopedTypeVariables, GADTs, DataKinds #-}

-- |
-- Copyright (C) 2023 by Dominick Samperi
-- License: BSD-3-Clause

-- This file plots the Daubechies (1988) wavelet psi_N for 2 <= N <= 10,
-- and indicates where the plot apears in the latter paper, or in other
-- places (like Numerical Recipes in C). To compare with the R
-- implementation in the package rgarden, remember that R vectors are
-- 1-based, so the position index in plotwavelet here must be one
-- unit smaller than the value used in the R implementation. This file
-- is basically a Haskell implementation of what can be done in R using:
--   library(rgarden)
--   example(wt1d)
-- The R implementation uses C++ to do the convolutions.

module Main where
  
import qualified Language.R as R
import Language.R (R)
import Language.R.QQ

import qualified H.Prelude as H

-- Why is this needed? I do not use I?
import qualified H.Prelude.Interactive as I

import Math.List.FFT
import Math.List.Wavelet
import Data.Int (Int32) -- R uses 32-bit ints, not 64-bit

plotWavelet :: Int -> Int -> IO ()  
plotWavelet k nw = do
  let n = 1024
      x = deltaFunc k n
      z = iwt1d x nw 0 10
      nw32 = fromIntegral nw :: Int32
  [r| plot(z_hs,type='l', 
           main=paste0("Daubechies wavelet (N=",nw32_hs,")")) 
      legend("topright",legend=bquote(psi[.(nw32_hs)]),bty='n',cex=2) |]
  putStrLn "Press Enter to continue"
  _ <- getLine
  return ()
  
main :: IO ()
main = H.withEmbeddedR H.defaultConfig $ do
  putStrLn $ unlines
    [ "\nShow classic Daubechies wavelets (psi)."
    , "The shapes look good, but the scaling and"
    , "time-shifts need work (not important for using"
    , "the transform). Note that some references index"
    , "wavelets by number of coefficients, so DAUB4"
    , "refers to psi_2.\n"
    , "N=2. Compare with Daubechies(1988),p.967"
    ]
  plotWavelet 6 2
  putStrLn $ unlines
    [ "\nN=3. Compare with Daubechies(1988),p.985" ]
  plotWavelet 11 3
  putStrLn $ unlines
    [ "N=4." ]
  plotWavelet 11 4
  putStrLn $ unlines
    [ "N=5. Compare with Daubechies(1988),p.987" ]
  plotWavelet 24 5
  putStrLn $ unlines
    [ "N=6." ]
  plotWavelet 23 6
  putStrLn $ unlines
    [ "N=7. Compare with Daubechies(1988),p.989" ]
  plotWavelet 23 7
  putStrLn $ unlines
    [ "N=8." ]
  plotWavelet 23 8
  putStrLn $ unlines
    [ "N=9. Compare with  Daubechies(1988),p.991" ]
  plotWavelet 23 9
  putStrLn $ unlines
    [ "N=10. Compare with Numerical Recipes in C,"
    , "2nd Ed (1992), p.598 (see DAUB20)."
    ]
  plotWavelet 23 10

        