USING: arrays assocs calendar checksums checksums.sha
  combinators command-line exercism exercism.config
  exercism.testing exercism.testing.private formatting globs
  hashtables http.client io io.directories io.encodings.utf8
  io.files io.pathnames json.reader kernel locals math
  math.functions math.parser namespaces present prettyprint
  sequences sorting splitting strings tools.scaffold.private
  unicode ;
IN: autogen-exercises

<PRIVATE


CONSTANT: factor-track-json "http://x.exercism.io/v3/tracks/factor"

CONSTANT: exercise-case-base "https://raw.githubusercontent.com/exercism/x-common/master/exercises/%s/canonical-data.json"

CONSTANT: unit-test-keys { "description" "expected" "input" }

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


M: f present
  drop "f" ;

M: array present
  [
    [
      dup string? [
        "\"" dup surround
      ] when
      present
    ] map
  ]
  [ length ]
  bi
  [ "%s " ] replicate "" join
  vsprintf "{ " " }"  surround ;

M: assoc present
  { } assoc-clone-like present ;

M: hashtable present
  { } assoc-clone-like present "H" prepend ;

: slug>wordname ( slug -- wordname )
  dup slugs-wordnames at
  [ nip ]
  [ "%s-test-fn" sprintf ]
  if* ;

: generate-using-ns ( slug type -- header-lines )
  ftype-using-ns at [ first2 surround ] with map ;

: get-todo-exercises ( -- todo-slugs )
  factor-track-json my-http-get json>
  "track" swap at "todo" swap at ;

: get-exercise-cases ( slug -- cases )
  exercise-case-base sprintf my-http-get json>
  "cases" swap at ;

: cases>unit-tests ( case -- code )
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
