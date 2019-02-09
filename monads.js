// JavaScript doesn't have a Maybe type. Let's make one.

const Just = x => ({
  value: x,
  inspect: () => `Just ${x}`,
  toString: () => `Just ${x}`,
  map: f => Just(f(x)),
  chain: f => f(x)
})

const Nothing = {
  value: 'Nothing',
  inspect: () => 'Nothing',
  toString: () => 'Nothing',
  map: f => Nothing,
  chain: f => Nothing
}

const Maybe = {
  Just,
  Nothing,
  of: x => Just(x)
}

// These are pretty bad implementations because they're kind of fragile.
// A library like Folktale is way better. Just trying to show this an
// implementation here.

// Let's start with a function that gets a GLID.

// Imagine that this function is doing an asynchronous network operation to
// get the GLID from Shibboleth

const getUserGlid = () => Just("ALBERT")

console.log(
  getUserGlid()
) // Just ALBERT

// As an aside, don't forget that data structures like Maybe allow us to
// use map to apply functions to the data inside without fear of errors.

// This is convenient because our getUserGlid seems to be giving us the
// GLID back in all caps. Gross.

const toLower = x => x.toLowerCase()

console.log(
  getUserGlid().map(toLower)
) // Just albert

// And it even works if we didn't get a GLID back...

console.log(
  Nothing.map(toLower)
) // Nothing

// If you were using Ramda, you should be able to use the map function
// to call your map method:
// map(toLower, getUserGlid())

// Heck, you could even compose them up...
// const getCleanUserGlid = compose(
//   toLower,
//   getUserGlid
// )

// I want to keep this runnable without Ramda though, so let's do things
// the more vanilla way.

const getCleanUserGlid = () => getUserGlid().map(toLower)

console.log(
  getCleanUserGlid()
) // Just albert

// Maybe gives us a data structure that gives us a representation for
// Failure (Nothing), but Folktale provides other data structures that
// give us other meanings.

// Either --> Often used to capture reasons for an error.
// Task --> Side effects like reading from disk or the internet.

// And of course, JavaScript provides us with Arrays.
// Arrays ([]) --> Multiple data (but they better be of the same type if
//                 you want to map and don't hate yourself.)

// Okay...Time to make a fake directory.

const directory = [
  { glid: "albert", ufid: "00000000", name: "Albert Alligator"},
  { glid: "alberta", ufid: "11111111", name: "Alberta Alligator"},
]

// Basically, we have a list of Person(s).

// We need a function that gets a UFID (if there is one) for a given
// GLID. Keep in mind that this could fail (if we're given a GLID that
// doesn't match a person in the directory). That means, we need a
// Maybe involved to capture the possibility of Failure.

const getUserUfid = dir => gl => dir.reduce(
  (acc, val) => val.glid === gl ? Just(val.ufid) : acc,
  Nothing
)

// Wait. A function that takes and argument and then returns a function?
// We're using currying here kind of like a function generator. We
// supply our directory, and in return, we get a function that takes a
// Gatorlink as an argument and returns a Maybe of a UFID.

// Why do it this way? Mostly, that's because I'm allergic to calling
// data from outside my function scope. I want to pass in my directory
// to the function.

// Incidentally, this makes things easier to unit test as well. We can
// supply a fake directory to test instead of going out and calling a
// real world directory.

// In our code example, we will frequently want to use our "UF"
// "directory", so let's use a partial application of a function like a
// function generator...

const getUserUfidFromDirectory = getUserUfid(directory)

// getUserUfidFromDirectory takes a GLID and gives us a Maybe of UFID.

console.log(
  getUserUfidFromDirectory("alberta")
) // Just 11111111

// But what about if we're trying to get our current user using
// getUserGlid and then we need to pipe that through
// getUserUfidFromDirectory to get our UFID?

console.log(
  getCleanUserGlid().map(getUserUfidFromDirectory)
) // Just Just 00000000

// (Remember that...
//    getCleanUserGlid() ==> Just albert
// )

// We really don't want nested Maybes here. :-\

// This is where monads are helpful. Monads provide us a way to take
// a value in a context and apply a function that's going to give us
// a value in that same context without getting nesting. That's it.

console.log(
  getCleanUserGlid().chain(getUserUfidFromDirectory)
) // Just 00000000

// Suppose we have a function that takes a UFID and gives back a name.
// But since maybe our users don't have a name in the directory, that
// could fail, so we know we should have a Maybe Name as our return
// value.

const getName = dir => id => dir.reduce(
  (acc, val) => val.ufid === id ? Just(val.name) : acc,
  Nothing
)

const getNameFromDirectory = getName(directory)

console.log(
  getNameFromDirectory('00000000')
) // Just Albert Alligator

// Now watch this.

console.log(
  getCleanUserGlid()
    .chain(getUserUfidFromDirectory)
    .chain(getNameFromDirectory)
) // Just Albert Alligator

// Errors are handled at every step of the way.

console.log(
  Nothing
    .chain(getUserUfidFromDirectory)
    .chain(getNameFromDirectory)
) // Nothing

const alwaysFail = x => Nothing

console.log(
  getCleanUserGlid()
    .chain(alwaysFail)
    .chain(getNameFromDirectory)
) // Nothing

// Holy monads!

// I need to admit something to you. I've oversimplified things a bit.
// Because monads are based on math, they have to obey certain laws in
// order to actually be a monad. This may seem weird at first, but
// it's actually really great because it means that they act very
// consistently. And that consistency means it's a lot easier to
// reason about your code.

// The first monad law is called Left Identity. In Haskell, it's
// usually written as:
// return a >>= f == f a

// So let's try to represent this in JavaScript. Because I'm basing a lot of the terms in this JavaScript implementation on a standard called the Fantasyland spec (Yes, I know JavaScript has dumb names), We'll call return `of`.

console.log(
  Maybe.of(5)
) // Just 5

// Maybe we do a similar thing for Arrays/Lists...

const List = {
  of: x => [x]
}

console.log(
  List.of(5)
) // [5]

// `of` takes the value and puts it into a container or a context.

// So if that first identity law holds then these two things should be
// equivalent:

console.log(
  getUserUfidFromDirectory('albert')
) // Just 00000000

console.log(
  Maybe.of('albert').chain(getUserUfidFromDirectory)
) // Just 00000000

// Sweet! It passes the first monad law (Left Identity).

// The second monad law is called Right Identity. In Haskell, it's
// usually written as:
// m >>= return == m

// Again, let's try to represent this in JavaScript...

console.log(
  Just('albert').chain(Maybe.of)
) // Just albert

// The idea that both the first two laws are getting it is that return
// doesn't change anything, and it always gives a consistent result --
// no matter which side it's on.

// Finally, we have the third law: Associativity. In Haskell, it's
// usually written as:
// (m >>= f) >>= g == m >>= (\x -> f x >>= g)

// Okay. Time to do this in JavaScript.

console.log(
  (getCleanUserGlid().chain(getUserUfidFromDirectory))
    .chain(getNameFromDirectory)
) // Just Albert Alligator

console.log(
  getCleanUserGlid().chain(
    x => getUserUfidFromDirectory(x).chain(getNameFromDirectory)
  )
) // Just Albert Alligator

// We're using the inline lambda to let us say, "Whatever the result
// from `getCleanUserGlid()` is, take that value and apply it to
// getUserUfidFromDirectory and then bind getNameFromDirectory over
// that result."

// Overall, the third law tells us that we can handle chunk our
// calculations together however we want as long we we still do the
// whole thing in order. This is the same as in arithmetic.

// (1 + 2) + 3
// 3 + 3
// 6

// 1 + (2 + 3)
// 1 + 5
// 6

// So for our real definition of a monad, a monad is any data
// structure that...

// * Implements "bind" (chain) to let us chain calls that would
//   otherwise cause context nesting.

// * Implements "return" (of) to let us wrap any value in a context.

// * Obeys the three monad laws: left identity, right identity, and
//   associativity.

// So you see, monads are like burritos. :kappa:
