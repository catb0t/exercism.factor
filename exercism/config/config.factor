USING: exercism
  accessors arrays classes.tuple exercism formatting io
  io.encodings.utf8 io.files io.launcher io.pathnames json.reader
  kernel locals math namespaces sets sequences sorting strings
  system ;

IN: exercism.config

TUPLE: exercise
      { slug       string }
      { difficulty number }
      { topics     array  } ; final

TUPLE: relevant-config
      { problems   array }
      { deprecated array }
      { exercises  array } ; final

TUPLE: entire-config-file
      { slug         string  }
      { language     string  }
      { repository   string  }
      { active       boolean }
      { test_pattern string  }
      { problems     array   }
      { exercises    array   }
      { deprecated   array   }
      { ignored      array   }
      { foregone     array   } ; final

: (config>objects) ( json -- config )
  config-keys select-keys

  V{ } clone-like dup pop [
    exercise-keys select-keys
    exercise slots>tuple
  ] map
  over push

  relevant-config slots>tuple ;

HOOK: exercise>filenames project-env ( test-name -- example-filename tests-filename )

M: dev-env exercise>filenames
  dup exercises-folder prepend-path prepend-path
  { "-tests.factor" "-example.factor" }
  [ append ] with map first2 ;

M: user-env exercise>filenames
  dup prepend-path
  { "-tests.factor" ".factor" } [ append ] with map
  first2 ;

: config-add-exercise ( config exercise -- config )
  [ slug>> [ problems>> ] dip 1array append ]
  [ [ dup exercises>> ] dip 1array append >>exercises ]
  2bi
  swap >>problems ;


: prettify-config ( -- )
  [
    "(cat config.json | jq) > config.json"
    utf8 [ contents ] with-process-reader
    drop
  ]
  with-exercism-root ;

HOOK: get-config-data project-env ( -- config )
M: dev-env get-config-data
  "config.json" path>json (config>objects) ;

M: user-env get-config-data
  M\ user-env get-config-data not-user-env ;

HOOK: exercise-exists? project-env ( exercise -- ? )
M:: dev-env exercise-exists? ( name -- ? )
  name
  [ get-config-data problems>> member? ]
  [ exercises-folder prepend-path exists? ]
  bi and
  [ name exercise>filenames [ exists? ] bi@ and ]
  [ f ]
  if ;

M: user-env exercise-exists?
  dup exercise>filenames [ exists? ] tri@ and and ;

M: f exercise-exists?
  drop \ exercise-exists? not-an-exercism-folder ;


HOOK: config-exclusive? project-env ( problems deprecated -- ? )
M: dev-env config-exclusive?
  sets:intersect { } = ;

M: user-env config-exclusive?
  M\ user-env config-exclusive? not-dev-env ;

HOOK: config-matches-fs? project-env ( dirs problems deprecated -- ? )
M: dev-env config-matches-fs?
  [ over ] dip sets:intersect { } = -rot
  [ natural-sort ] bi@ = and ;

M: user-env config-matches-fs?
  \ config-matches-fs? not-dev-env ;

HOOK: wd-git-name os ( -- name )
M: windows wd-git-name "" ;

M: unix wd-git-name
  "git rev-parse --show-toplevel" utf8 [ contents ] with-process-reader*
  nip 0 =
  [ path-components last dup length 1 - head ]
  [ drop "" ]
  if ;

: dev-files-exist? ( -- ? )
  "exercises" { ".keep" "hello-world" }
  [ append-path ] with map
  {
    "config.json"
    ".git"
    ".gitignore"
    "exercises"
  }
  append
  [ exists? ] all? ;

: valid-git-repo-name? ( -- ? )
  wd-git-name git-dev-repo-name = ;

: dev-wd? ( -- ? )
  git-dev-repo-name ".." prepend-path absolute-path
  current-directory namespaces:get = ;

: wd-is-dev-env? ( -- ? )
  dev-files-exist? valid-git-repo-name? dev-wd? 3array [ ] all?
  dup [ T{ dev-env } project-env namespaces:set ] when ;

: wd-is-user-env? ( -- ? )
  "hello-world" exists?
  dup [ T{ user-env } project-env namespaces:set ] when ;

HOOK: verify-config project-env ( -- )
M: dev-env verify-config
  get-config-data dup problems>> [ deprecated>> ] dip 2dup
  [ config-exclusive? ] 2dip

  swap exercises-folder child-directories -rot
  config-matches-fs?
  and

  exercises-folder child-directories
  [ exercise>filenames [ exists? ] bi@ and ] all?
  and

  [ "config.json and exercises OK" print ]
  [ "invalid config.json\n"
    print ]
  if ;

M: user-env verify-config
  exercises-folder child-directories
  [ exercise>filenames [ exists? ] bi@ and ] all?

  [ "config OK: all problems have implementations and unit tests" print ]
  [ "invalid config: problems are missing implementations or tests\n"
    print ]
  if ;

M: f verify-config
  \ verify-config not-an-exercism-folder ;


: guess-project-env ( -- env )
  wd-is-user-env? wd-is-dev-env? xor
  [ current-directory project-env [ namespaces:get ] bi@
    "working directory OK: %s is a %s \n" printf
  ]
  [ current-directory namespaces:get
    "exercism.testing: `%s' is not an `exercism/factor' folder or `xfactor' git project \n\n" printf
    f project-env namespaces:set
  ] if
  project-env namespaces:get ;

guess-project-env drop
