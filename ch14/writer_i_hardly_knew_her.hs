import Data.Monoid
import qualified Data.ByteString.Lazy as B
import Control.Monad.Writer

isBigGang :: Int -> Bool
isBigGang x = x > 9

-- *Main> isBigGang 3
-- False
-- *Main> isBigGang 10
-- True

isBigGang' :: Int -> (Bool, String)
isBigGang' x = (x > 9, "Compared gang size to 9.")

-- *Main> isBigGang' 3
-- (False,"Compared gang size to 9.")
-- *Main> isBigGang' 30
-- (True,"Compared gang size to 9.")

applyLog :: (a, String) -> (a -> (b, String)) -> (b, String)
applyLog (x, log) f = let (y, newlog) = f x in (y, log ++ newlog)

-- *Main> (3, "Smallish gang.") `applyLog` isBigGang'
-- (False,"Smallish gang.Compared gang size to 9.")
-- *Main> (30, "A freaking platoon.") `applyLog` isBigGang'
-- (True,"A freaking platoon.Compared gang size to 9.")

-- *Main> ("Tobin", "Got outlaw name.") `applyLog` (\x -> (length x, "Apply length."))
-- (5,"Got outlaw name.Apply length.")
-- *Main> ("Bathcat", "Got outlaw name.") `applyLog` (\x -> (length x, "Apply length."))
-- (7,"Got outlaw name.Apply length.")


--- Monoids to the Rescue

-- applyLog' :: (a, [c]) -> (a -> (b, [c])) -> (b, [c])

-- *Main> B.pack [99,104,105] `mappend` B.pack [104,117,97,104,117,97]
-- "chihuahua"
-- *Main> :t B.pack
-- B.pack :: [GHC.Word.Word8] -> B.ByteString

applyLog' :: (Monoid m) => (a, m) -> (a -> (b, m)) -> (b, m)
applyLog' (x, log) f = let (y, newLog) = f x in (y, log `mappend` newLog)


type Food = String
type Price = Sum Int

addDrink :: Food -> (Food, Price)
addDrink "beans" = ("milk", Sum 25)
addDrink "jerky" = ("whiskey", Sum 99)
addDrink _ = ("beer", Sum 30)

-- *Main> Sum 3 `mappend` Sum 9
-- Sum {getSum = 12}

-- *Main> ("beans", Sum 10) `applyLog'` addDrink
-- ("milk",Sum {getSum = 35})
-- *Main> ("jerky", Sum 25) `applyLog'` addDrink
-- ("whiskey",Sum {getSum = 124})
-- *Main> ("dogmeat", Sum 5) `applyLog'` addDrink
-- ("beer",Sum {getSum = 35})

-- *Main> ("dogmeat", Sum 5) `applyLog'` addDrink `applyLog'` addDrink
-- ("beer",Sum {getSum = 65})


--- The Writer Type

-- *Main> runWriter (return 3 :: Writer String Int)
-- (3,"")
-- *Main> runWriter (return 3 :: Writer (Sum Int) Int)
-- (3,Sum {getSum = 0})
-- *Main> runWriter (return 3 :: Writer (Product Int) Int)
-- (3,Product {getProduct = 1})


--- Using do Notation with Writer
logNumber :: Int -> Writer [String] Int
logNumber x = writer (x, ["Got number: " ++ show x])

multWithLog :: Writer [String] Int
multWithLog = do
  a <- logNumber 3
  b <- logNumber 5
  return (a*b)
---- during the processes, context ([String]) is kept so [string]s are appended
---- in each process.

-- *Main> runWriter multWithLog
-- (15,["Got number: 3","Got number: 5"])

-- *Main> :t tell
-- tell :: MonadWriter w m => w -> m ()

multWithLog' :: Writer [String] Int
multWithLog' = do
  a <- logNumber 3
  b <- logNumber 5
  tell ["Gonna multiply these two"]
  return (a*b)

-- *Main> runWriter multWithLog'
-- (15,["Got number: 3","Got number: 5","Gonna multiply these two"])


--- Adding Logging to Programs
gcd' :: Int -> Int -> Int
gcd' a b
  | b == 0 = a
  | otherwise = gcd' b (a `mod` b)

-- *Main> gcd' 8 3
-- 1

gcd'' :: Int -> Int -> Writer [String] Int
gcd'' a b
  | b == 0 = do
    tell ["Finished with " ++ show a]
    return a
  | otherwise = do
    tell [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)]
    gcd'' b (a `mod` b)

-- *Main> runWriter (gcd'' 8 3)
-- (1,["8 mod 3 = 2","3 mod 2 = 1","2 mod 1 = 0","Finished with 1"])

-- *Main> fst $ runWriter (gcd'' 8 3)
-- 1
-- *Main> mapM_ putStrLn $ snd $ runWriter (gcd'' 8 3)
-- 8 mod 3 = 2
-- 3 mod 2 = 1
-- 2 mod 1 = 0
-- Finished with 1

--- Inefficient List Construction
gcdReverse :: Int -> Int -> Writer [String] Int
gcdReverse a b
  | b == 0 = do
    tell ["Finished with " ++ show a]
    return a
  | otherwise = do
    result <- gcdReverse b (a `mod` b)
    tell [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)]
    return result

-- *Main> mapM_ putStrLn $ snd $ runWriter (gcdReverse 8 3)
-- Finished with 1
-- 2 mod 1 = 0
-- 3 mod 2 = 1
-- 8 mod 3 = 2


--- Using Difference Lists
newtype DiffList a = DiffList { getDiffList :: [a] -> [a] }

toDiffList :: [a] -> DiffList a
toDiffList xs = DiffList (xs++)

fromDiffList :: DiffList a -> [a]
fromDiffList (DiffList f) = f []

instance Monoid (DiffList a) where
  mempty = DiffList (\xs -> [] ++ xs)
  (DiffList f) `mappend` (DiffList g) = DiffList (\xs -> f (g xs))

-- *Main> fromDiffList (toDiffList [1,2,3,4] `mappend` toDiffList [1,2,3])
-- [1,2,3,4,1,2,3]

gcd''' :: Int -> Int -> Writer (DiffList String) Int
gcd''' a b
  | b == 0 = do
    tell (toDiffList ["Finished with " ++ show a])
    return a
  | otherwise = do
    result <- gcd''' b (a `mod` b)
    tell (toDiffList [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)])
    return result

-- *Main> mapM_ putStrLn . fromDiffList . snd . runWriter $ gcd''' 110 34
-- Finished with 2
-- 8 mod 2 = 0
-- 34 mod 8 = 2
-- 110 mod 34 = 8

--- Comparing Performance
finalCountDown :: Int -> Writer (DiffList String) ()
finalCountDown 0 = do
  tell (toDiffList ["0"])
finalCountDown x = do
  finalCountDown (x-1)
  tell (toDiffList [show x])

finalCountDown' :: Int -> Writer [String] ()
finalCountDown' 0 = do
  tell ["0"]
finalCountDown' x = do
  finalCountDown' (x-1)
  tell [show x]

-- mapM_ putStrLn . fromDiffList . snd . runWriter $ finalCountDown 500000
-- mapM_ putStrLn . snd . runWriter $ finalCountDown' 500000

-- *Main> length . fromDiffList . snd . runWriter $ finalCountDown 5000
-- 5001
-- *Main> length . snd . runWriter $ finalCountDown' 5000
-- 5001
