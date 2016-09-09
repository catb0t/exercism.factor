# exercism.factor

interacting with [Exercism.io][exercism] from [Factor][factor]

- - -

# `exercism.testing`

making it easy for end users and maintainers alike to [unit-test](http://docs.factorcode.org/content/article-tools.test.html) [Factor](http://github.com/factor/factor) code on [Exercism.io](http://exercism.io)

## Rationale

Factor and Exercism both have rather strict naming conventions which make a consistent and simple unit test interface tricky.

This vocabulary allows end users to run the same unit tests on their code that [xfactor][xfactor] maintainers do, with a consistent interface.

## Getting started

1. Install `exercism.testing` to somewhere Factor can find it. Sticking it under `resource:work` (or `git clone`ing) it there is a good idea.
2. Open a shell (`bash`, `cmd.exe`, Powershell, etc) and run the following from your `exercism/factor` or `xfactor.git` directories:
  ```
  factor -run=exercism.testing run-all
  ```
  Or, from a Factor listener instance:
  ```factor
  IN: scratchpad USING: io.directories exercism.testing ;
  IN: scratchpad "place/you/want/to/test" [ run-all-exercism-tests ] with-directory
  ```
  If you get something like `Vocabulary does not exist`, then Factor couldn't find `exercism.testing`. Make sure it's within Factor's resource paths.
  Otherwise, you should see something like:
  ```
  working directory OK: /home/you/exercism/factor is a user-env
  config OK: all problems have implementations and unit tests

  testing exercise: hello-world

  Unit Test: { { "Hello, World!" } [ "" hello-name ] }
  Unit Test: { { "Hello, Alice!" } [ "Alice" hello-name ] }
  Unit Test: { { "Hello, Bob!" } [ "Bob" hello-name ] }
  ```

Viola!

Check out `exercism.testing`'s documentation for more information.

If you need help, just open an issue here or on [xfactor][xfactor].

 [exercism]: http://exercism.io
 [factor]:   http://factorcode.org
 [xfactor]:  http://github.com/exercism/xfactor