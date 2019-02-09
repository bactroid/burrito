# Python doesn't have a Maybe type. Let's make one.


class Just:

    def __init__(self, x):
        self.value = x

    def __str__(self):
        return "Just(" + str(self.value) + ")"

    def map(self, f):
        return Just(f(self.value))

    def bind(self, f):
        return f(self.value)


class Nothing:

    def __init__(self):
        self.value = None

    def __str__(self):
        return "Nothing"

    def map(self, f):
        return Nothing()

    def bind(self, f):
        return Nothing()

def MaybeReturn(x):
    return Just(x)


# These are pretty bad implementations because they're kind of fragile.
# Just trying to show this an implementation here.

# Let's start with a function that gets a GLID.

# Imagine that this function is doing an asynchronous network operation to
# get the GLID from Shibboleth

def get_user_glid():
    return Just("ALBERT")

print(get_user_glid())  # Just(ALBERT)

# As an aside, don't forget that data structures like Maybe allow us to
# use map to apply functions to the data inside without fear of errors.

# This is convenient because our getUserGlid seems to be giving us the
# GLID back in all caps. Gross.


def to_lower(s):
    return s.lower()

print(get_user_glid().map(to_lower))  # Just(albert)

# And it even works if we didn't get a GLID back...

print(Nothing().map(to_lower))  # Nothing

# This seems pretty useful, so let's make that a separate function.


def get_clean_user_glid():
    return get_user_glid().map(to_lower)

print(get_clean_user_glid())  # Just(albert)

# Maybe gives us a data structure that gives us a representation for
# Failure (Nothing), but there are other data structures that give us
# other meanings in other languages (like Haskell).

# IO --> Side effects like reading from disk or the internet.
# Either --> Often used to capture reasons for an error.

# And of course, Python provides us with Arrays.
# Arrays ([]) --> Multiple data (but they better be of the same type if
#                 you want to map and don't hate yourself.)

# Okay...Time to make a fake directory.

directory = [
  {"glid": "albert", "ufid": "00000000", "name": "Albert Alligator"},
  {"glid": "alberta", "ufid": "11111111", "name": "Alberta Alligator"},
]

# Basically, we have a list of Person(s).

# We need a function that gets a UFID (if there is one) for a given
# GLID. Keep in mind that this could fail (if we're given a GLID that
# doesn't match a person in the directory). That means, we need a
# Maybe involved to capture the possibility of Failure.


def get_user_ufid(dir):
    def find_ufid(gl):
        for person in dir:
            if person["glid"] == gl:
                return Just(person["ufid"])
        return Nothing()
    return find_ufid

# Wait. A function that takes and argument and then returns a function?
# We're using currying here kind of like a function generator. We
# supply our directory, and in return, we get a function that takes a
# Gatorlink as an argument and returns a Maybe of a UFID.

# Why do it this way? Mostly, that's because I'm allergic to calling
# data from outside my function scope. I want to pass in my directory
# to the function.

# Incidentally, this makes things easier to unit test as well. We can
# supply a fake directory to test instead of going out and calling a
# real world directory.

# In our code example, we will frequently want to use our "UF"
# "directory", so let's use a partial application of a function like a
# function generator...

get_user_ufid_from_directory = get_user_ufid(directory)

# get_user_ufid_from_directory takes a GLID and gives us a Maybe of UFID.

print(get_user_ufid_from_directory("alberta"))  # Just(11111111)

# But what about if we're trying to get our current user using
# getUserGlid and then we need to pipe that through
# getUserUfidFromDirectory to get our UFID?

print(
    get_clean_user_glid()
    .map(get_user_ufid_from_directory)
)  # Just(Just(00000000))

# (Remember that...
#    getCleanUserGlid() ==> Just albert
# )

# We really don't want nested Maybes here. :-\

# This is where monads are helpful. Monads provide us a way to take
# a value in a context and apply a function that's going to give us
# a value in that same context without getting nesting. That's it.

print(
    get_clean_user_glid()
    .bind(get_user_ufid_from_directory)
)  # Just(00000000)

# Suppose we have a function that takes a UFID and gives back a name.
# But since maybe our users don't have a name in the directory, that
# could fail, so we know we should have a Maybe Name as our return
# value.


def get_name(dir):
    def find_name(id):
        for person in dir:
            if person["ufid"] == id:
                return Just(person["name"])
        return Nothing()
    return find_name

get_name_from_directory = get_name(directory)

print(
    get_name_from_directory("00000000")
)  # Just(Albert Alligator)

# Now watch this.

print(
    get_clean_user_glid()
    .bind(get_user_ufid_from_directory)
    .bind(get_name_from_directory)
)  # Just(Albert Alligator)

# Errors are handled at every step of the way.

print(
    Nothing()
    .bind(get_user_ufid_from_directory)
    .bind(get_name_from_directory)
)  # Nothing


def always_fail(x):
    return Nothing()

print(
    get_clean_user_glid()
    .bind(always_fail)
    .bind(get_name_from_directory)
)  # Nothing

# Holy monads!

# I need to admit something to you. I've oversimplified things a bit.
# Because monads are based on math, they have to obey certain laws in
# order to actually be a monad. This may seem weird at first, but
# it's actually really great because it means that they act very
# consistently. And that consistency means it's a lot easier to
# reason about your code.

# The first monad law is called Left Identity. In Haskell, it's
# usually written as:
# return a >>= f == f a

# So let's try to represent this in Python. Since return is a keyword in Python, let's call our function MaybeReturn

print(
    MaybeReturn(5)
)  # Just(5)

# Maybe we do a similar thing for Arrays/Lists...

def ListReturn(x):
    return [x]

print(
    ListReturn(5)
)  # [5]

# Return takes the value and puts it into a container or a context.

# So if that first identity law holds then these two things should be
# equivalent:

print(
    get_user_ufid_from_directory("albert")
)  # Just(00000000)

print(
    MaybeReturn("albert").bind(get_user_ufid_from_directory)
)  # Just(00000000)

# Sweet! It passes the first monad law (Left Identity).

# The second monad law is called Right Identity. In Haskell, it's
# usually written as:
# m >>= return == m

# Again, let's try to represent this in Python...

print(
    Just("albert").bind(MaybeReturn)
)  # Just(albert)

# The idea that both the first two laws are getting it is that return
# doesn't change anything, and it always gives a consistent result --
# no matter which side it's on.

# Finally, we have the third law: Associativity. In Haskell, it's
# usually written as:
# (m >>= f) >>= g == m >>= (\x -> f x >>= g)

# Okay. Time to do this in JavaScript.

print(
    (get_clean_user_glid().bind(get_user_ufid_from_directory))
    .bind(get_name_from_directory)
)  # Just(Albert Alligator)

print(
    get_clean_user_glid().bind(
        lambda x: get_user_ufid_from_directory(x).bind(get_name_from_directory)
    )
)  # Just(Albert Alligator)

# We're using the inline lambda to let us say, "Whatever the result
# from `getCleanUserGlid()` is, take that value and apply it to
# getUserUfidFromDirectory and then bind getNameFromDirectory over
# that result."

# Overall, the third law tells us that we can handle chunk our
# calculations together however we want as long we we still do the
# whole thing in order. This is the same as in arithmetic.

# (1 + 2) + 3
# 3 + 3
# 6

# 1 + (2 + 3)
# 1 + 5
# 6

# So for our real definition of a monad, a monad is any data
# structure that...

# * Implements "bind" to let us chain calls that would
#   otherwise cause context nesting.

# * Implements "return" to let us wrap any value in a context.

# * Obeys the three monad laws: left identity, right identity, and
#   associativity.

# So you see, monads are like burritos. :kappa:
