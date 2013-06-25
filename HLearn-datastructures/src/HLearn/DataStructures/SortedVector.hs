module HLearn.DataStructures.SortedVector
    ( SortedVector
    )
    where
    
import Control.Applicative
import qualified Data.Foldable as F
import Data.List
import Debug.Trace
import GHC.TypeLits
import qualified Data.Vector as V

import qualified Control.ConstraintKinds as CK

import HLearn.Algebra
import HLearn.Models.Distributions

-------------------------------------------------------------------------------
-- data types

newtype SortedVector a = SortedVector { vector :: V.Vector a}
    deriving (Read,Show,Eq,Ord)

bst2list :: SortedVector a -> [a]
bst2list (SortedVector vec) = V.toList vec

elem :: (Ord a) => a -> (SortedVector a) -> Bool
elem a (SortedVector vec) = go 0 (V.length vec - 1)
    where
        go lower upper
            | lower==upper      = (vec V.! lower)==a
            | a > (vec V.! mid) = go (mid+1) upper
            | a < (vec V.! mid) = go lower (mid-1)
            | otherwise         = True -- a==(vec V.! mid)
            where mid = floor $ (fromIntegral $ lower+upper)/2
    
-------------------------------------------------------------------------------
-- Algebra

instance (Ord a) => Monoid (SortedVector a) where
    {-# INLINE mempty #-}
    mempty = SortedVector $ V.empty
    
    {-# INLINE mappend #-}
    (SortedVector va) `mappend` (SortedVector vb) = SortedVector $ V.fromList $ merge2 (V.toList va) (V.toList vb)
        where
            merge2 xs [] = xs
            merge2 [] ys = ys
            merge2 (x:xs) (y:ys) =
                case compare x y of
                    LT        -> x: merge2 xs (y:ys)
                    otherwise -> y: merge2 (x:xs) ys

instance (Ord a, Invertible a) => Group (SortedVector a) where
    {-# INLINE inverse #-}
    inverse (SortedVector vec) = SortedVector $ V.map mkinverse vec

---------------------------------------

instance F.Foldable SortedVector where
    foldr f b (SortedVector vec) = V.foldr f b vec

instance CK.Functor SortedVector where
    type FunctorConstraint SortedVector a = Ord a
    fmap f (SortedVector v) = SortedVector . V.fromList . sort . V.toList $ fmap f v

instance CK.Pointed SortedVector where
    point = SortedVector . V.singleton

instance CK.Applicative SortedVector where
    (<*>) = undefined

instance CK.Monad SortedVector where
    type MonadConstraint SortedVector a = Ord a
    (>>=) = flip concatMapa

concatMapa :: (Ord a, Ord b) => (a -> SortedVector b) -> SortedVector a -> SortedVector b
concatMapa f v = reduce $ CK.fmap f v

join :: SortedVector (SortedVector a) -> SortedVector a
join = undefined

-------------------------------------------------------------------------------
-- Training

instance (Ord a) => HomTrainer (SortedVector a) where
    type Datapoint (SortedVector a) = a
    train1dp dp = SortedVector $ V.singleton dp
