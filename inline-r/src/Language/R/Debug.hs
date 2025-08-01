-- |
-- Copyright: (C) 2013 Amgen, Inc.
--
-- Debugging facilities, in particular to analyze the internal structure of
-- a 'SEXP' as structured JSON.
--
-- This module is intended to be imported qualified.

{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ViewPatterns #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}

module Language.R.Debug
  ( inspect )
  where

import Control.Memory.Region (V)
import Data.String (fromString)
import qualified Data.Vector.SEXP as Vector
import qualified Foreign.R as R
import Foreign.R (SEXP, SomeSEXP(..), SEXPTYPE, SEXPInfo)
import Foreign.R.Type (IsVector)
import Foreign.Storable
import Language.R.Globals as H
import Language.R.HExp

import Data.Complex
import System.IO.Unsafe ( unsafePerformIO )

import Data.Aeson as A
import qualified Data.Text as T
import qualified Data.Vector as V
import qualified Data.ByteString.Lazy.Char8 as LBS

instance ToJSON SEXPTYPE where
  toJSON = A.String . T.pack . show

instance ToJSON SEXPInfo where
  toJSON x =
    object
      [ "type"  .= R.infoType x
      , "obj"   .= R.infoObj x
      , "named" .= R.infoNamed x
      , "gp"    .= R.infoGp x
      , "debug" .= R.infoDebug x
      ]

instance ToJSON a => ToJSON (Complex a) where
  toJSON (x :+ y) =
    object ["Re" .= x, "Im" .= y]

instance ToJSON (SEXP s a) where
  toJSON x =
      object
        [ "header" .= info
        , "attributes" .= if R.unsexp x == R.unsexp attr then "loop" else toJSON attr
        , tp .= go x
        ]
    where
      vector :: (IsVector a, ToJSON (Vector.ElemRep V a), Storable (Vector.ElemRep V a))
             => Vector.Vector a (Vector.ElemRep V a) -> V.Vector Value
      vector = V.fromList . map toJSON . Vector.toList -- XXX: do not use lists
      ub = R.unsexp H.unboundValue
      nil = R.unsexp H.nilValue
      miss = R.unsexp H.missingArg
      info = unsafePerformIO $ R.peekInfo x
      attr = unsafePerformIO $ R.getAttributes x
      tp = fromString . show $ R.infoType info
      go :: SEXP s a -> Value
      go y | R.unsexp y == ub   = A.String "UnboundValue"
           | R.unsexp y == nil  = A.String "NilValue"
           | R.unsexp y == miss = A.String "MissingArg"
      go (hexp -> Nil) = A.String "NilValue"
      go (hexp -> Lang i j) =
          object [ "function" .= i
                 , "parameters" .= j
                 ]
      go h@(hexp -> Symbol i j k) =
          object [ "name" .= i
                 , "value" .= if R.unsexp j == R.unsexp h then "loop" else toJSON j
                 , "internal" .= k
                 ]
      go (hexp -> Special) = object ["index" .= A.String "unknown"]
      go (hexp -> Builtin) = object ["index" .= A.String "unknown"]
      go (hexp -> Char v) = A.String (T.pack (Vector.toString v))
      go (hexp -> Int v) = A.Array (vector v)
      go (hexp -> Real v) = A.Array (vector v)
      go (hexp -> Complex v) = A.Array (vector v)
      go (hexp -> Vector _ v) = A.Array (vector v)
--  String    :: {-# UNPACK #-} !(Vector.Vector (SEXP (R.Vector Word8)))
--            -> HExp (R.Vector (SEXP (R.Vector Word8)))
      go (hexp -> List i j k) =
          object [ "value" .= i
                 , "next"  .= j
                 , "tag"   .= k
                 ]
      go (hexp -> Env _ _ _) = A.String "Environment"
      go (hexp -> Closure f b e) =
         object [ "formals" .= f
                , "body" .= b
                , "environment" .= e
                ]
      go (hexp -> Promise vl ex en) =
          object [ "value" .= vl
                 , "expr" .= ex
                 , "environment" .= en
                 ]
      go (hexp -> DotDotDot v) =
          object [ "promises" .= v]
      go (hexp -> Expr _ v)   = A.Array (vector v)
      go (hexp -> Bytecode) = A.String "Bytecode"
      go (hexp -> ExtPtr _ a b) =
          object [ "ptr" .= A.String "<PTR>"
                 , "second" .= a
                 , "symbol" .= b
                 ]
      go (hexp -> WeakRef k v fn nxt) =
          object [ "key" .= k
                 , "value" .= v
                 , "finalizer" .= fn
                 , "next" .= nxt
                 ]
      go (hexp -> Raw _bs) = A.String "<data>"
      go (hexp -> S4 s) =
          object [ "tagval" .= s ]
      go _ = A.String "Unimplemented."

instance ToJSON (SomeSEXP s) where
  toJSON (R.SomeSEXP s) = toJSON s

inspect :: SEXP s a -> String
inspect = LBS.unpack . A.encode
