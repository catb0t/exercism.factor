USING: arrays assocs calendar checksums checksums.sha
  combinators command-line exercism exercism.config
  exercism.testing exercism.testing.private formatting globs
  hashtables http.client io io.directories io.encodings.utf8
  io.files io.pathnames json json.reader kernel locals math
  math.functions math.parser namespaces present prettyprint regexp
  sequences sorting splitting strings tools.scaffold.private
  unicode ;
IN: autogen-exercises

<PRIVATE


CONSTANT: factor-track-json "http://x.exercism.io/v3/tracks/factor"

CONSTANT: exercise-case-base "https://raw.githubusercontent.com/exercism/problem-specifications/master/exercises/%s/canonical-data.json"

CONSTANT: unit-test-keys { "description" "property" "expected" "input" }

CONSTANT: ftype-using-ns
  H{
    { "tests" { { "USING: " " tools.test ;" } { "IN: " ".tests" } } }
    { "example" { { "USING: ; ! " "" } { "IN: " "" } } }
  }

CONSTANT: slugs-wordnames
  H{
    { "hello-world" "hello-name" }
    { "leap"        "leap-year?" }
  }

TUPLE: test-case
  { description string }
  { expected    string }
  { property    string }
  { input       string }

  { other-keys  hashtable } ;

M: json-null present
  drop "" ;

M: f present
  unparse ;

M: array present
  unparse ;

M: assoc present
  unparse ;

M: hashtable present
  unparse ;

!
! { "property" "expected" "description" } [ dup -rot swap delete-at* drop 2array ] with map
!

: raw-case>test-case ( raw-case -- test-case )
  [
    unit-test-keys select-keys test-case slots>tuple
  ]
  [
    [ drop unit-test-keys member? ] assoc-reject
  ] bi
  >>other-keys ;

: slug>wordname ( slug -- wordname )
  dup slugs-wordnames at
  [ nip ]
  [ "%s-test-fn" sprintf ]
  if* ;

: generate-using-ns ( slug type -- header-lines )
  ftype-using-ns at [ first2 surround ] with map ;

: get-todo-exercises ( -- todo-slugs )
  factor-track-json my-http-get json>
  "track" of "todo" of ;

: get-exercise-cases ( slug -- test-cases )
  exercise-case-base sprintf my-http-get json>
  "cases" of [ raw-case>test-cases ] map ;

: cases>unit-tests ( test-cases -- code-array )
  [
    unit-test-keys select-keys
    first3 "! %s\n{ %s } [ %s " sprintf
    " ] unit-test\n" 2array
  ] map ;

: slug>tests ( slug -- code-lines )
  [ "tests" generate-using-ns ]
  [ slug>wordname ]
  [ get-exercise-cases cases>unit-tests ]
  tri
  [ swap join "\n" append ] with map append ;

: example-file-contents ( slug -- code-lines )
  [ "example" generate-using-ns ]
  [
    slug>wordname
    "\n: " " ( input -- output ) ... ;\n"
    surround 1array
  ]
  bi append ;

: create-tests-file ( slug -- code-lines tests-fname )
  [ slug>tests ]
  [ "-tests.factor" append ]
  bi ;

: create-example-file ( slug -- code-lines tests-fname )
  [ example-file-contents ]
  [ "-example.factor" append ]
  bi ;

: (autogen-exercise) ( slug -- )
  dup dup make-directory [
    [ create-tests-file ]
    [ create-example-file ]
    bi
    [ set-new-file-lines ] 2bi@
  ] with-directory ;

PRIVATE>

: autogen-exercise ( slug -- )
  guess-project-env T{ dev-env } =
  [ "exercises" [ (autogen-exercise) ] with-directory ]
  [ drop "wrong current working directory (not a dev-env as told by guess-project-env)" print ]
  if ;

: autogen-all-todo-exericses ( -- )
  get-todo-exercises [ autogen-exercise ] each ;

: autogen-main ( -- )
  (command-line) last autogen-exercise ;

MAIN: autogen-main
