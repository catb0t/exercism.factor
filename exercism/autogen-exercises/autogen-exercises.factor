USING: assocs exercism formatting http.client
  json.reader kernel present sequences ;
IN: autogen-exercises

CONSTANT: factor-track-json "http://x.exercism.io/v3/tracks/factor"

CONSTANT: exercise-case-base "https://raw.githubusercontent.com/exercism/x-common/master/exercises/%s/canonical-data.json"

CONSTANT: unit-test-keys { "description" "expected" "input" }

M: f present
  drop "f" ;

M: array present
  [ present ] map
  dup length 2 * 1 + "%s " swap
  cycle vsprintf "{ " prepend " }" append ;

: my-http-get ( url -- data )
  [ "GET: %s\n" printf ]
  [ http-get nip ]
  bi ;

: get-todo-exercises ( -- todo-slugs )
  factor-track-json my-http-get json>
  "track" swap at "todo" swap at ;

: get-exercise-cases ( slug -- cases )
  exercise-case-base sprintf my-http-get json>
  "cases" swap at ;

: case>unit-test ( case -- code )
  [
    unit-test-keys select-keys
    first3 "! %s\n{ %s } [ %s %%s-testfunction ]\n" sprintf
  ] map ;