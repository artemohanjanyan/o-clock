{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE TypeInType           #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TypeApplications     #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}
{-# LANGUAGE UndecidableInstances #-}

module Time.Rational
       ( Rat (..)
       , type (:%)
       , type (*)
       , type (/)
       , Gcd
       , Normalize

        -- Utilities
       , RatioNat
       , KnownRat (..)
       , divRat
       ) where

import Data.Kind (Type)
import Data.Proxy (Proxy (..))
import GHC.Natural (Natural)
import GHC.Real (Ratio ((:%)))
import GHC.TypeNats (Div, KnownNat, Mod, Nat, natVal)
import qualified GHC.TypeNats

-- | Data structure represents the rational number.
-- Rational number can be represented as a pair of
-- natural numbers @n@ and @m@ where @m@ is nor equal
-- to zero.
data Rat = Nat ::% Nat

-- | The result kind of overloaded multiplication and division.
type family MulK (k1 :: Type) (k2 :: Type) :: Type

type instance MulK Nat Nat = Nat
type instance MulK Rat Rat = Rat
type instance MulK Rat Nat = Rat
type instance MulK Nat Rat = Rat

type family DivK (k1 :: Type) (k2 :: Type) :: Type

type instance DivK Nat Nat = Rat
type instance DivK Rat Rat = Rat
type instance DivK Rat Nat = Rat
type instance DivK Nat Rat = Rat

-- | Overloaded multiplication.
type family (*) (a :: k1) (b :: k2) :: MulK k1 k2

type instance (a :: Nat) * (b :: Nat) = (GHC.TypeNats.*) a b
type instance (a :: Rat) * (b :: Rat) = MulRat a b
type instance (a :: Rat) * (b :: Nat) = MulNatRat b a
type instance (a :: Nat) * (b :: Rat) = MulNatRat a b

-- | Overloaded division.
type family (/) (a :: k1) (b :: k2) :: DivK k1 k2

type instance (a :: Nat) / (b :: Nat) = a % b
type instance (a :: Rat) / (b :: Rat) = DivRat a b
type instance (a :: Rat) / (b :: Nat) = DivRatNat a b
type instance (a :: Nat) / (b :: Rat) = DivRat (a :% 1) b

-- | More convenient name for promoted constructor of 'Rat'.
type (:%) = '(::%)

-- | Type family for normalized pair of 'Nat's — 'Rat'.
type family (m :: Nat) % (n :: Nat) :: Rat where
    a % b = Normalize (a :% b)
infixl 7 %

{- | Division of type-level rationals.

If there are 'Rat' with 'Nat's @a@ and @b@ and another
'Rat' with @c@ @d@ then the following formula should be applied:
 \[
 \frac{a}{b} / \frac{c}{d} = \frac{a * d}{b * c}
 \]

__Example:__

>>> :kind! DivRat (9 % 11) (9 % 11)
DivRat (9 % 11) (9 % 11) :: Rat
= 1 :% 1
-}
type family DivRat (m :: Rat) (n :: Rat) :: Rat where
    DivRat (a :% b) (c :% d) = (a * d) % (b * c)

{- | Multiplication for type-level rationals.

__Example:__

>>> :kind!  MulRat (2 % 3) (9 % 11)
MulRat (2 % 3) (9 % 11) :: Rat
= 6 :% 11
-}
type family MulRat (m :: Rat) (n :: Rat) :: Rat where
    MulRat (a :% b) (c :% d) = (a * c) % (b * d)

{- | Multiplication of type-level natural with rational.

__Example:__

>>> :kind!  MulNatRat 2 (9 % 11)
MulNatRat 2 (9 % 11) :: Rat
= 18 :% 11
-}
type family MulNatRat (n :: Nat) (r :: Rat) :: Rat where
    MulNatRat x (a :% b) = (x * a) % b

{- | Division of type-level rational and natural.

__Example:__

>>> :kind!  DivRatNat (9 % 11) 2
DivRatNat (9 % 11) 2 :: Rat
= 9 :% 22
-}
type family DivRatNat (r :: Rat) (n :: Nat) :: Rat where
    DivRatNat (a :% b) x = a % (b * x)

{- | Greatest common divisor for type-level naturals.

__Example:__

>>> :kind! Gcd 9 11
Gcd 9 11 :: Nat
= 1

>>> :kind! Gcd 9 12
Gcd 9 12 :: Nat
= 3
-}
type family Gcd (m :: Nat) (n :: Nat) :: Nat where
    Gcd a 0 = a
    Gcd a b = Gcd b (a `Mod` b)

{- | Normalization of type-level rational.

__Example:__

>>> :kind! Normalize (9 % 11)
Normalize (9 % 11) :: Rat
= 9 :% 11

>>> :kind! Normalize (9 % 12)
Normalize (9 % 12) :: Rat
= 3 :% 4
-}
type family Normalize (r :: Rat) :: Rat  where
    Normalize (a :% b) = (a `Div` Gcd a b) :% (b `Div` Gcd a b)


-- | Rational numbers, with numerator and denominator of 'Natural' type.
type RatioNat = Ratio Natural

-- | This class gives the integer associated with a type-level rational.
class KnownRat (r :: Rat) where
  ratVal :: Proxy r -> Ratio Natural

instance (KnownNat a, KnownNat b) => KnownRat (a :% b) where
    ratVal _ = natVal (Proxy @a) :% natVal (Proxy @b)

divRat :: forall (m1 :: Rat) (m2 :: Rat) . Proxy m1 -> Proxy m2 -> Proxy (DivRat m1 m2)
divRat _ _ = Proxy
