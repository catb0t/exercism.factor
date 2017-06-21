# exercism.factor

interacting with [Exercism.io][exercism] from [Factor][factorcode]

- - -

# `exercism.testing`

making it easy for end users and maintainers alike to [unit-test](http://docs.[factorcode].org/content/article-tools.test.html) [Factor](http://github.com/factor/factor) code on [Exercism.io](http://exercism.io)

## Rationale

Factor and Exercism both have rather strict naming conventions which make a consistent and simple unit test interface tricky.

This vocabulary allows end users to run the same unit tests on their code that [factor][factor] maintainers do, with a consistent interface.

## Getting started

1. Install a **0.98 nightly build** (0.97 stable will not work!!) from [[factorcode].org][factorcode] (the "Development release" section for your OS and arch), or build directly from [source](https://github.com/factor/factor)

2. Clone or download the repository, and copy the `exercism` folder to `resource:work`<sup>1</sup>.
3. Open a shell (`bash`, `cmd.exe`, Powershell, etc) and run the following from your `exercism/factor` Exercism directory or [`factor`][factor] clone:
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

<sup>1</sup> Refers to the `work` subfolder of Factor's installation directory. If Factor's installation directory is `/home/you/factor`, `resource:work` refers to `/home/you/factor/work`.

---

Check out `exercism.testing`'s documentation for more information.

If you need help, just open an issue here or on [factor][factor].

 [exercism]:   http://exercism.io
 [factorcode]: http://factorcode.org
 [factor]:     http://github.com/exercism/factor