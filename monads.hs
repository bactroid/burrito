-- First, some set up...

import Data.Char (toLower)

lower :: String -> String
lower = fmap toLower

-- No worries about this. I just make a function like toLowerCase that
-- lowercases a whole string.

-- One more bit of setup...

bind :: Monad m => m a -> (a -> m b) -> m b
bind = (>>=)

-- This is just for ease of understanding. "Bind" is how we pronounce
-- the line operator >>=. Don't worry about it.

-- Haskell has the concept of type aliases. I'm setting them up here for
-- code readability. This is (I would argue) good practice.

type GLID = String
type UFID = String
type Name = String

-- Getting a little fancy for our Person type. This JSON-looking thing
-- is Haskell record syntax.

data Person = Person { glid :: String
                     , ufid :: String
                     , name :: String
                     } deriving (Eq, Show)

-- Now let's make a Directory data type. It's just a list of Person(s).

type Directory = [Person]

-- Let's start with a function that gets a GLID.

-- Imagine that this function is doing an asynchronous network operation to
-- get the GLID from Shibboleth

getUserGlid :: () -> Maybe GLID
getUserGlid _ = Just "ALBERT"

-- What's up with that type declaration (the first line)?

-- Don't get too caught up on the details, but our function takes no
-- real input and give us back a Maybe GLID. In a real program, this
-- would involve IO and stuff, but this is just a teaching example.

-- Sample call and output...
-- λ> getUserGlid ()
-- Just "ALBERT"

-- As an aside, don't forget that data structures like Maybe allow us to
-- use map to apply functions to the data inside without fear of errors.

-- This is convenient because our getUserGlid seems to be giving us the
-- GLID back in all caps. Gross.

-- Let's map the built-in function `toLower` over our data...
-- (In Haskell, we use `fmap` rather than map.)

-- Sample call and output...
-- λ> fmap lower (getUserGlid ())
-- Just "albert"

-- And it even works if we didn't get a GLID back...

-- Sample call and output...
-- λ> fmap lower Nothing
-- Nothing

-- Let's turn that handy data cleaning into a function...

getCleanUserGlid :: () -> Maybe GLID
getCleanUserGlid = fmap lower . getUserGlid

-- Wait...What?

-- Remember how we talked a little bit about Ramda's compose/pipe?
-- Haskell has that built in. It has its own operator, the dot.

-- The above is the same as...

-- getCleanUserGlid :: () -> Maybe GLID
-- getCleanUserGlid = fmap lower (getUserGlid ())

-- In Haskell, we can fmap over almost anything. Maybe gives us a data
-- structure that gives us a representation for Failure (Nothing), but
-- there are other data structures that give us other meanings.

-- IO --> Side effects like reading from disk or the internet.
-- Either --> Often used to capture reasons for an error.
-- Lists ([]) --> Multiple data of the same type.

-- Okay...Time to make a fake directory.

directory :: Directory
directory = [ Person "albert" "00000000" "Albert Alligator"
            , Person "alberta" "11111111" "Alberta Alligator"
            ]

-- Basically, we have a list of Person(s). There are a lot of ways I
-- could have inputted that list. Don't worry about syntax.

-- We need a function that gets a UFID (if there is one) for a given
-- GLID. Keep in mind that this could fail (if we're given a GLID that
-- doesn't match a person in the directory). That means, we need a
-- Maybe involved to capture the possibility of Failure.

getUserUfid :: Directory -> GLID -> Maybe UFID
getUserUfid dir gl = foldr checkIfGlid Nothing dir
  where
    checkIfGlid val acc = if (glid val) == gl then Just (ufid val) else acc

-- You may be wondering why we have a Directory as our first function
-- argument. Mostly, that's because I'm allergic to calling data from
-- outside my function scope. I want to pass in my directory to the
-- function.

-- Incidentally, this makes things easier to unit test as well. We can
-- supply a fake directory to test instead of going out and calling a
-- real world directory.

-- In our code example, we will frequently want to use our "UF"
-- "directory", so let's use a partial application of a function like a
-- function generator...

getUserUfidFromDirectory :: GLID -> Maybe UFID
getUserUfidFromDirectory = getUserUfid directory

-- Now this looks like the type annotation I wrote on the board in our
-- Standards and Practices meeting. :)

-- Sample call and output...
-- λ> getUserUfidFromDirectory "alberta"
-- Just "11111111"

-- But what about if we're trying to get our current user using
-- getUserGlid and then we need to pipe that through
-- getUserUfidFromDirectory to get our UFID?

-- Sample call and output...
-- λ> fmap getUserUfidFromDirectory (getCleanUserGlid ())
-- Just (Just "00000000")

-- (Remember that...
--    getCleanUserGlid () ==> Just "albert"
-- )

-- We really don't want nested Maybes here. :-\

-- This is where monads are helpful. Monads provide us a way to take
-- a value in a context and apply a function that's going to give us
-- a value in that same context without getting nesting. That's it.

-- Sample call and output...
-- λ> bind (getCleanUserGlid ()) getUserUfidFromDirectory
-- Just "00000000"

-- Using the native inline Haskell bind operator...
-- λ> getCleanUserGlid () >>= getUserUfidFromDirectory
-- Just "00000000"

-- ...which maybe reads better? I find that it helps show that you can
-- keep chaining these forever. Kind of like dot notation in JavaScript.

-- Suppose we have a function that takes a UFID and gives back a name.
-- But since maybe our users don't have a name in the directory, that
-- could fail, so we know we should have a Maybe Name as our return
-- value.

getName :: Directory -> UFID -> Maybe Name
getName dir id = foldr checkIfUfid Nothing dir
  where
    checkIfUfid val acc = if (ufid val) == id then Just (name val) else acc

getNameFromDirectory :: UFID -> Maybe Name
getNameFromDirectory = getName directory

-- Sample call and output...
-- λ> getNameFromDirectory "00000000"
-- Just "Albert Alligator"

-- Now watch this.

-- Sample call and output...
-- λ> getCleanUserGlid () >>= getUserUfidFromDirectory >>= getNameFromDirectory
-- Just "Albert Alligator"

-- Errors are handled at every step of the way.

-- Sample call and output...
-- λ> Nothing >>= getUserUfidFromDirectory >>= getNameFromDirectory
-- Nothing

alwaysFail :: UFID -> Maybe UFID
alwaysFail _ = Nothing

-- Sample call and output...
-- λ> getCleanUserGlid () >>= alwaysFail >>= getNameFromDirectory
-- Nothing

-- Holy monads!

-- I need to admit something to you. I've oversimplified things a bit.
-- Because monads are based on math, they have to obey certain laws in
-- order to actually be a monad. This may seem weird at first, but
-- it's actually really great because it means that they act very
-- consistently. And that consistency means it's a lot easier to
-- reason about your code.

-- The first monad law is called Left Identity. It's usually written
-- as:
-- return a >>= f == f a

-- return is a function that must be defined for a monad. All it does
-- is "wrap" up the value in the monad in the simplest possible
-- context.

-- λ> return 5 :: Maybe Integer
-- Just 5

-- λ> return 5 :: [Integer]
-- [5]

-- See? It takes the value and puts it into a container or a context.

-- So if that first identity law holds then these two things should be
-- equivalent:

-- λ> getUserUfidFromDirectory "albert"
-- Just "00000000"
-- λ> return "albert" >>= getUserUfidFromDirectory
-- Just "00000000"

-- Sweet! It passes the first monad law (Left Identity).

-- The second monad law is called Right Identity. It's usually written
-- as:
-- m >>= return == m

-- So if we have a monadic value and we bind return over it, we get
-- the same value back.

-- λ> Just "albert" >>= return
-- Just "albert"

-- The idea that both the first two laws are getting it is that return
-- doesn't change anything, and it always gives a consistent result --
-- no matter which side it's on.

-- Finally, we have the third law: Associativity. It's usually written
-- as:
-- (m >>= f) >>= g == m >>= (\x -> f x >>= g)

-- λ> (getCleanUserGlid () >>= getUserUfidFromDirectory) >>= getNameFromDirectory
-- Just "Albert Alligator"
-- λ> getCleanUserGlid () >>= (\x -> getUserUfidFromDirectory x >>= getNameFromDirectory)
-- Just "Albert Alligator"

-- This one might look a little confusing because of the syntax. That
-- second one is using an inline lambda function. They're a lot like
-- fat arrow functions in JavaScript or lambdas in Python:

-- Haskell:
-- \x -> getUserUfidFromDirectory x >>= getNameFromDirectory

-- JavaScript:
-- x => getUserUfidFromDirectory(x).chain(getNameFromDirectory)

-- Python:
-- lambda x: get_user_ufid_from_directory(x).bind(get_name_from_directory)

-- We're using the inline lambda to let us say, "Whatever the result
-- from `getCleanUserGlid ()` is, take that value and apply it to
-- getUserUfidFromDirectory and then bind getNameFromDirectory over
-- that result."

-- Overall, the third law tells us that we can handle chunk our
-- calculations together however we want as long we we still do the
-- whole thing in order. This is the same as in arithmetic.

-- (1 + 2) + 3
-- 3 + 3
-- 6

-- 1 + (2 + 3)
-- 1 + 5
-- 6

-- So for our real definition of a monad, a monad is any data
-- structure that...

-- * Implements "bind" (>>=) to let us chain calls that would
--   otherwise cause context nesting.

-- * Implements "return" to let us wrap any value in a context.

-- * Obeys the three monad laws: left identity, right identity, and
--   associativity.

-- So you see, monads are like burritos. :kappa:
