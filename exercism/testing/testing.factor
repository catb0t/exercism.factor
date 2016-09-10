USING: accessors arrays assocs classes.tuple combinators
  command-line formatting http.client io io.directories
  io.encodings.utf8 io.files io.files.info io.launcher
  io.pathnames json.reader kernel locals math math.parser
  multiline parser present sequences sets sorting splitting
  summary system tools.scaffold.private tools.test vocabs.loader ;
QUALIFIED: namespaces
QUALIFIED: sets
IN: exercism.testing

<PRIVATE

SYMBOL: reversed-roots-this-session?
SYMBOL: update-now?

: child-directories ( path -- directories )
  directory-entries
  [ directory? ] filter
  [ name>>     ] map ;

CONSTANT: own-rawgit-url-stub
  "https://raw.githubusercontent.com/catb0t/exercism.factor/master/exercism/testing"
CONSTANT: name-clashes
  { "hello-world" "binary-search" "poker" }
CONSTANT: git-dev-repo-name
  "xfactor"

TUPLE: config
      { problems   array }
      { deprecated array } ; final

SYMBOL: project-env
ERROR:  wrong-project-env word ;

TUPLE: user-env ; final
M:     user-env present
  drop "user-env" ;
ERROR: not-user-env  < wrong-project-env ; final
M:     not-user-env  summary
  word>> name>> "can't use word %s in dev environment" sprintf ;

TUPLE: dev-env ; final
M:     dev-env present
  drop "dev-env" ;
ERROR: not-dev-env  < wrong-project-env ; final
M:     not-dev-env  summary
  word>> name>> "can't use word %s in user environment"  sprintf ;

ERROR:  not-an-exercism-folder word ;
M:      not-an-exercism-folder summary
  word>> name>> "exercism.testing: %s: current directory is not an exercism folder" sprintf ;


HOOK: exercises-folder project-env ( -- dirname )
M: dev-env  exercises-folder  "exercises" ; inline
M: user-env exercises-folder  "."         ; inline
M: f        exercises-folder  \ exercises-folder not-an-exercism-folder ;


HOOK: exercise>filenames project-env
  ( test-name -- example-filename tests-filename )
M: dev-env exercise>filenames
  dup exercises-folder prepend-path prepend-path
  { "-tests.factor" "-example.factor" }
  [ append ] with map first2 ;

M: user-env exercise>filenames
  dup prepend-path
  { "-tests.factor" ".factor" } [ append ] with map
  first2 ;

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


HOOK: get-config-data project-env ( -- config )
M: dev-env get-config-data
  "config.json" path>json
  { "problems" "deprecated" } [ swap at ] with map
  config slots>tuple ;

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

:: (run-exercism-test) ( exercise -- )
  exercise
  [ name-clashes member?
    [ exercise handle-name-clash ] when
  ]
  [ "\ntesting exercise: %s\n\n" printf ]
  [ exercise>filenames ]
  tri
  run-file run-test-file ;

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

: do-update? ( -- ? )
  own-rawgit-url-stub "/VERSION.txt" append http-get nip string-lines
  "./VERSION.txt" utf8 file-lines
  2dup =

  [ 2drop { t t } ]
  [
    zip
    [ first first2 = ]
    [ second [ string>number ] map first2 >= ]
    bi 2array
  ]
  if ;

: self-update ( -- )
  own-rawgit-url-stub "testing" append
  ".factor" { "" "-docs" "-tests" } [ glue ] 2with map
  [ [ "GET: %s\n" printf ] [ download ] bi ] each ;


PRIVATE>


: exercism-testing-self-update ( -- )
  "exercism.testing" vocab>path absolute-path
  [
    do-update?
    {
      { [ dup { f f } = ] [ drop "nocorrel; client is ahead, publish your local changes!" print ] }
      { [ dup { t f } = ] [ drop "samesha2; client is equal & newer: not updating " print ] }
      { [ dup { f t } = ] [ drop "timegteq; server is ahead & newer: UPDATING" print self-update ] }
      { [ dup { t t } = ] [ drop "bothtrue; server is equal & newer: not updating" print ] }
    } cond

  ] with-directory ;

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
    print 2 exit ]
  if ;

M: user-env verify-config
  exercises-folder child-directories
  [ exercise>filenames [ exists? ] bi@ and ] all?

  [ "config OK: all problems have implementations and unit tests" print ]
  [ "invalid config: problems are missing implementations or tests\n"
    print 2 exit ]
  if ;

M: f verify-config
  \ verify-config not-an-exercism-folder ;


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
  {
    { [ dup "VERIFY"  =      ] [ drop verify-config ] }
    { [ dup "run-all" =      ] [ drop verify-config run-all-exercism-tests ] }
    { [ dup "update"  =      ] [ drop exercism-testing-self-update ] }
    { [ dup exercise-exists? ] [ verify-config run-exercism-test ] }
      [ verify-config "exercism.testing: choose-suite: bad last argument `%s', expected 'run-all' or an exercise slug\n\n" printf ]
  } cond ;

: guess-project-env ( -- )
  wd-is-user-env? wd-is-dev-env? xor
  [ current-directory project-env [ namespaces:get ] bi@
    "working directory OK: %s is a %s \n" printf
  ]
  [ current-directory namespaces:get
    "exercism.testing: `%s' is not an `exercism/factor' folder or `xfactor' git project \n\n" printf
    f project-env namespaces:set
  ] if ;

: exercism-testing-main ( -- )
  ! guess-project-env
  (command-line) last
  choose-exercism-test-suite ;

guess-project-env
MAIN: exercism-testing-main
