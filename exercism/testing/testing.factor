USING: combinators command-line exercism exercism.config
  formatting io.pathnames kernel locals parser
  namespaces sequences tools.test unicode vocabs.loader ;

IN: exercism.testing

<PRIVATE


SYMBOL: reversed-roots-this-session?


CONSTANT: name-clashes
  { "hello-world" "binary-search" "poker" }

: (handle-name-clash) ( -- )
  reversed-roots-this-session? namespaces:get not [
    vocab-roots namespaces:get reverse vocab-roots namespaces:set
  ] when
  reversed-roots-this-session? t namespaces:set ; inline

HOOK: handle-name-clash project-env ( name -- )

M: dev-env handle-name-clash
  exercises-folder prepend-path add-vocab-root
  (handle-name-clash) ; inline

M: user-env handle-name-clash
  add-vocab-root
  (handle-name-clash) ; inline

M: f handle-name-clash
  drop
  \ handle-name-clash not-an-exercism-folder ; inline

:: (run-exercism-test) ( exercise -- )
  exercise
  [
    name-clashes member?
    [ exercise handle-name-clash ] when
  ]
  [ "\ntesting exercise: %s\n\n" printf ]
  [ exercise>filenames ]
  tri
  run-file run-test-file ;

PRIVATE>


HOOK: run-exercism-test project-env ( exercise -- )
M: dev-env run-exercism-test
  (run-exercism-test) ;

M: user-env run-exercism-test
  (run-exercism-test) ;

M: f run-exercism-test
  drop \ run-exercism-test not-an-exercism-folder ;


: run-all-exercism-tests ( -- )
  exercises-folder child-directories [ run-exercism-test ] each ;

: choose-exercism-test-suite ( arg -- )
  >lower
  {
    { [ dup "verify"  =      ] [ drop verify-config ] }
    { [ dup "run-all" =      ] [ drop verify-config run-all-exercism-tests ] }
    { [ dup exercise-exists? ] [ verify-config run-exercism-test ] }
      [ verify-config "exercism.testing: choose-suite: bad last argument `%s', expected 'run-all' or an exercise slug\n\n" printf ]
  } cond ;

: exercism-testing-main ( -- )
  (command-line) last
  choose-exercism-test-suite ;

MAIN: exercism-testing-main
