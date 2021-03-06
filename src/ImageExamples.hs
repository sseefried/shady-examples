{-# LANGUAGE ScopedTypeVariables, TypeOperators, FlexibleContexts, TypeFamilies #-}
{-# OPTIONS_GHC -Wall -fno-warn-missing-signatures #-}
-- {-# OPTIONS_GHC -fno-warn-unused-imports #-} -- TEMP
----------------------------------------------------------------------
-- |
-- Module      :  ImageExamples
-- Copyright   :  (c) Conal Elliott 2009
-- License     :  GPLv3
-- 
-- Maintainer  :  conal@conal.net
-- Stability   :  experimental
-- 
-- 2D shady examples
----------------------------------------------------------------------

module ImageExamples where

import Control.Applicative ((<$>),(<*>), liftA2)

import Control.Compose (result)

import Data.Boolean

import Data.VectorSpace
import Data.Derivative (pureD)

import Shady.Complex
import Shady.Misc (frac)
import Shady.Language.Exp
import Shady.Color
import Shady.Image
import Shady.Lighting (view1,intrinsic)
import Shady.ParamSurf (xyPlane,SurfD,T)
import Shady.CompileE (GLSL(..))
import Shady.CompileImage (ImageB,imageBProg)
import Shady.CompileSurface (FullSurf)

-- GLUT-based.  Doesn't make window border & buttons on mac os x in ghci.
-- import Shady.RunImage (runImageB)

-- For GUIs
import Interface.TV.Gtk.GL
-- import Data.Lambda
import Data.Title
import Shady.RunUI

import RunUtils

-- Testing
x :: HasColor c => Sink (ImageB c)
x = print . imageBProg

saveShader suffix name =
  writeFile ("../sample-shaders/" ++ name ++ "." ++ suffix)

saveVert, saveFrag, saveSh :: String -> Sink (GLSL R1 R2)

saveVert name (GLSL v _ _ _) = saveShader "vert" name v
saveFrag name (GLSL _ f _ _) = saveShader "frag" name f

saveSh name glsl = saveVert name glsl >> saveFrag name glsl

-- Save a fragment shader.  Don't bother with the vertex shader, since
-- they're all the same.
saveIm :: HasColor c => String -> Sink (ImageB c)
saveIm name = saveFrag name . imageBProg

-- Shared image vertex shader.  
saveImVert = saveVert "image" (imageBProg a0)

-- Hm.  Where did I put the code that loads & runs saved shaders?


-- | Animated region
type RegionB = ImageB BoolE

triv :: RegionB
triv = const (const false)

a0 :: RegionB
a0  t = uscale2 (sin t + 1.05) checker
a1' t = rotate2 t checker

a1 t = rotate2 t $ a0 t
a2 t = uscale2 (cos t) udisk

a3 = (liftA2.liftA2) (==*) a1 a2

a4 = (fmap.fmap) (boolean blue red) a1
a5 = (fmap.fmap) (boolean (blue ^/ 2) clear) a2
a6 = liftA2 over a5 a4

realPos :: Region
realPos = (>* 0) . realPart

imagPos :: Region
imagPos = (>* 0) . imagPart

a7 = (fmap.fmap) (boolean clear (black ^/ 2)) a2  -- blank on its own
a8 = liftA2 over a7 ((fmap.fmap) (boolean blue red) a1)

a9a t = a0 t . sin
a9b t = a0 t . cos
a9c t = a0 t . tan

a9d :: ImageB BoolE
a9d t = (>* sin t) . magnitude . cos

a10 :: ImageB Color
a10 t = rotate2 t $ uscale2 (sin t) $
        bilerpC red blue black white

a11 t = a5 t `over` a10 t

a12 t = fmap toColor (a1 t) `over` a10 t

a13 t = swirl (sin (0.3 * t)) $
        uscale2 (1.05 + cos (0.7 * t)) checker

a14 = intersectR udisk <$> a13

a15 t = uscale2 (1 + cos t / 2) utile (a10 t)

stripes (a :+ _) = frac a <* 0.5

a16 t = swirl (sin t / 3) stripes

a17 t = swirl (sin t / 5) (a15 t)

a18 _ = utile (disk 0.45)
a19 t = tile (w :+ w) (disk rad)
 where
   w   = 1 + sin (1.5 * t) / 7
   rad = 0.3 + cos (1.1 * t) / 9
a19b = rotate2 <*> a19

a19c = swirl  <*> a19b
a19d = swirl' <*> a19b
a19e = (uscale2 . (1.1 +) . cos . (+ pi/3) . (/ 2)) <*> a19d

a19f t = uscale2 (1.1 + cos (t/2 + pi/3)) (a19d t)
a19g t = uscale2 (cos t) (a19d t)
a19h t = uscale2 t (a19d t)
a19i t = translate2 (t:+t) (a19d t)

a19j t = translate2 (cis (t/5)) (a19 0)
a19k :: RegionB
a19k t = translate2 (t :+ 0) . uscale2 (1/4) $ a19 (pi/3)


lerpL lo hi t = lerp lo hi ((1 + cos t) / 2)

diskL :: FloatE -> FloatE -> FloatE -> Region
-- diskL lo hi t = disk (lerpL lo hi t)
diskL = (result.result.result) disk lerpL

a20a = diskL 0 1

a20 = utile . diskL 0.3 0.5

a20b t = translate2 (cis (t/5)) . uscale2 (1/2) $ a20 t 

a20c = utile . diskL 0 (sqrt 2 / 2)

a21 lo hi t = utile (uscale2 (lerpL lo hi t) $ annulus (1/2) (1/4))

a21a, a21b :: RegionB
a21a = a21 0 1
a21b = a21 (1/3) (2/3)

a21c = (result.result) (boolean red blue) a21a

-- wedges :: IntE -> Region
-- wedges n = 

-- | Swirl transformation
-- swirl' :: ITrans Point a => FloatE -> Filter a
swirl' s = rotate2Im ((2*pi* sin s*) . magnitude)

a22a = (swirl . sin) <*> a21b
a22b = (swirl . (* 0.2) . sin) <*> a21b


{--------------------------------------------------------------------
    Textures
--------------------------------------------------------------------}


-- Tweak for -1 to 1, and Y inversion.
samplerIm' :: Sampler N2 :=> Image Color
samplerIm' = translate2 (d:+d) . scale2 (s :+ (-s)) . samplerIm
 where
   d = -1
   s =  2

samplerIn' :: In (Sampler N2)
samplerIn' = title "texture" samplerIn




{--------------------------------------------------------------------
    Running examples
--------------------------------------------------------------------}

run :: HasColor c => Sink (ImageB c)
run imb = runUI'' (lambda1 clockIn renderOut) (model'' (const xyPlane) imb)
 where 
   runUI'' = runUI (2,2) (0,0,2)
   
   model'' :: HasColor c => (T -> SurfD) -> ImageB c -> SurfB'
   model'' surf im = liftA2 surfIm'' (surf . pureD) im
   
   surfIm'' :: HasColor c => SurfD -> Image c -> FullSurf
   surfIm'' surf im = (intrinsic, view1, surf, toColor . im)

saveAll = do saveImVert
             saveIm "a2" a2
             saveIm "a3" a3
             saveIm "a8" a8
             saveIm "a9b" a9b
             saveIm "a9c" a9c
             saveIm "a10" a10
             saveIm "a12" a12
             saveIm "a13" a13
             saveIm "a15" a15
             saveIm "a16" a16
             saveIm "a17" a17
             saveIm "a19" a19
             saveIm "a19b" a19b
             saveIm "a19c" a19c
             saveIm "a19d" a19d
             saveIm "a19e" a19e
             saveIm "a19j" a19j
             saveIm "a20c" a20c
             saveIm "a21a" a21a
             saveIm "a22b" a22b

main = run a22b
