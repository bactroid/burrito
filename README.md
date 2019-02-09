# burrito

There is a long-standing idea in functional programming circles that monads are cursed. Once you understand monads, the curse goes, you become completely unable to explain them to anyone else.

![Spider-Man Meme - How Do I Bind Monad](bind-monad.png)

On February 8, in my team’s Standards and Best Practices meeting, I gave a brief talk about monads. This repo is a follow-up reference to that talk, providing code that illustrates hopefully more accurately things I excitedly scrawled on a whiteboard. Examples are given in Haskell, JavaScript, and Python. Haskell, of course, uses the delivered Maybe type to illustrate its points. JavaScript uses a hastily implemented version of Maybe, and Python does the same.

## Using this Repo

For the most part, this code is designed to be read rather than executed, but it is 100% interpretable.

### Haskell

Load `monad.hs` in the GHCI REPL:

```
ghci monad.hs
```

You should be able to copy and paste sample runs in coments to get the appropriate output.

### JavaScript

`monad.js` should be executable using Node:

```
node monad.js
```

All of the `console.log` statements should output what they claim in comments.

### Python

`monad.py` should be executable with Python 3.

```
python monad.py
```

All of the `print` statements should output what they claim in comments.

## Questions?

If you know me from work, hit me up on Slack. If you’re an internet person, email is probably your best bet:
fuzzcat@bactroid.net
