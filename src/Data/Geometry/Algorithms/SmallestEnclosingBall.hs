{-# LANGUAGE DeriveFunctor  #-}
module Data.Geometry.Algorithms.SmallestEnclosingBall where

import qualified Data.List as L

import           Control.Lens
import           Data.Ext
import           Data.Geometry.Ball
import           Data.Geometry.Point
import           Data.List.NonEmpty
import           Data.Maybe(fromMaybe)

import           System.Random
import           System.Random.Shuffle(shuffle)



-- | List of two or three elements
data TwoOrThree a = Two !a !a | Three !a !a !a deriving (Show,Read,Eq,Ord,Functor)

-- | The result of a smallest enclosing disk computation: The smallest ball
--    and the points defining it
data DiskResult d p r = DiskResult { _enclosingBall  :: Ball d r
                                   , _definingPoints :: TwoOrThree (Point d r :+ p)
                                   }

-- | O(n) expected time algorithm to compute the smallest enclosing disk of a
-- set of points. we need at least two points.
-- implemented using randomized incremental construction
smallestEnclosingDisk           :: (Ord r, Fractional r, RandomGen g)
                                => g
                                -> Point 2 r :+ p -> Point 2 r :+ p -> [Point 2 r :+ p]
                                -> DiskResult 2 p r
smallestEnclosingDisk g p q pts = let (p':q':pts') = shuffle g (p:q:pts)
                                  in smallestEnclosingDisk' p' q' pts'


-- | Smallest enclosing disk.
smallestEnclosingDisk'     :: (Ord r, Fractional r)
                           => Point 2 r :+ p -> Point 2 r :+ p -> [Point 2 r :+ p]
                           -> DiskResult 2 p r
smallestEnclosingDisk' a b = foldr addPoint (initial a b) . L.tails
  where
    -- The epty case occurs only initially
    addPoint []      br   = br
    addPoint (p:pts) br@(DiskResult d _)
      | (p^.core) `inClosedBall` d = br
      | otherwise                = smallestEnclosingDiskWithPoint p (a :| (b : pts))


-- | Smallest enclosing disk, given that p should be on it.
smallestEnclosingDiskWithPoint              :: (Ord r, Fractional r)
                                            => Point 2 r :+ p -> NonEmpty (Point 2 r :+ p)
                                               -> DiskResult 2 p r
smallestEnclosingDiskWithPoint p (a :| pts) = foldr addPoint (initial p a) $ L.tails pts
  where
    addPoint []      br   = br
    addPoint (q:pts) br@(DiskResult d _)
      | (q^.core) `inClosedBall` d = br
      | otherwise                = smallestEnclosingDiskWithPoints p q (a:pts)



-- | Smallest enclosing disk, given that p and q should be on it
smallestEnclosingDiskWithPoints     :: (Ord r, Fractional r)
                                    => Point 2 r :+ p -> Point 2 r :+ p -> [Point 2 r :+ p]
                                    -> DiskResult 2 p r
smallestEnclosingDiskWithPoints p q = foldr addPoint (initial p q)
  where
    addPoint r br@(DiskResult d _)
      | (r^.core) `inClosedBall` d = br
      | otherwise                  = DiskResult (circle' r) (Three p q r)

    circle' r = fromMaybe undefined $ circle (p^.core) (q^.core) (r^.core)


-- | Constructs the initial 'DiskResult' from two points
initial     :: Fractional r => Point 2 r :+ p -> Point 2 r :+ p -> DiskResult 2 p r
initial p q = DiskResult (fromDiameter (p^.core) (q^.core)) (Two p q)