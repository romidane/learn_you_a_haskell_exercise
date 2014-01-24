-- *Main> Just 3 >>= (\x -> Just (show x ++ "!"))
-- Just "3!"

-- *Main> Just 3 >>= (\x -> Just "!" >>= (\y -> Just (show x ++ y)))
-- Just "3!"
-- *Main> let x = 3; y = "!" in show x ++ y
-- "3!"

-- *Main> Nothing >>= (\x -> Just "!" >>= (\y -> Just (show x ++ y)))
-- Nothing
-- *Main> Just 3 >>= (\x -> Nothing >>= (\y -> Just (show x ++ y)))
-- Nothing
-- *Main> Just 3 >>= (\x -> Just "!" >>= (\y -> Nothing))
-- Nothing

foo :: Maybe String
foo = Just 3 >>= (\x ->
                   Just "!" >>= (\y ->
                                  Just (show x ++ y)))
foo' :: Maybe String
foo' = do
  x <- Just 3
  y <- Just "!"
  return (show x ++ y)

--- Do As I Do
-- *Main> Just 9 >>= (\x -> Just (x > 8))
-- Just True

marySue :: Maybe Bool
marySue = do
  x <- Just 9
  Just (x > 8)

--- Pierre Returns
type Birds = Int
type Pole = (Birds, Birds)

landLeft :: Birds -> Pole -> Maybe Pole
landLeft n (left, right)
  | abs ((left + n) - right) < 4 = Just (left + n, right)
  | otherwise = Nothing

landRight :: Birds -> Pole -> Maybe Pole
landRight n (left, right)
  | abs (left - (right + n)) < 4 = Just (left, right + n)
  | otherwise = Nothing

banana :: Pole -> Maybe Pole
banana _ = Nothing


routine :: Maybe Pole
routine = do
  start <- return (0, 0)
  first <- landLeft 2 start
  second <- landRight 2 first
  landLeft 1 second

-- *Main> routine
-- Just (3,2)

routine' :: Maybe Pole
routine' =
  case Just (0, 0) of
    Nothing -> Nothing
    Just start -> case landLeft 2 start of
      Nothing -> Nothing
      Just first -> case landRight 2 first of
        Nothing -> Nothing
        Just second -> landLeft 1 second

-- *Main> routine'
-- Just (3,2)

routine'' :: Maybe Pole
routine'' = do
  start <- return (0, 0)
  first <- landLeft 2 start
  Nothing
  second <- landRight 2 first
  landLeft 1 second

--- Pattern Matching and Failure
justH :: Maybe Char
justH = do
  (x:xs) <- Just "hello"
  return x

wopwop :: Maybe Char
wopwop = do
  (x:xs) <- Just ""
  return x
