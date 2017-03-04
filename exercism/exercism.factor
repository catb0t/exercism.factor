USING: accessors assocs continuations formatting http.client io
  io.directories io.encodings.utf8 io.files io.files.info
  io.pathnames kernel present sequences summary
  tools.scaffold.private ;
IN: exercism

<PRIVATE

: (my-http-get) ( url -- data )
  [ "GET: %s" printf ]
  [ http-get ]
  bi
  [
    [ code>>    ]
    [ message>> ]
    bi
    "\n%s %s\n" printf
  ] dip ;

PRIVATE>

! COMMON

CONSTANT: git-dev-repo-name
  "xfactor"

CONSTANT: config-keys
  { "problems" "deprecated" "exercises" }

CONSTANT: exercise-keys
  { "slug" "difficulty" "topics"   }


: set-new-file-lines ( seq path -- )
  [ touch-file ]
  [ utf8 set-file-lines ]
  bi ;

: with-exercism-root ( quot -- )
  [ "exercism" vocab>path absolute-path ] dip with-directory ; inline

: child-directories ( path -- directories )
  directory-entries
  [ directory? ] filter
  [ name>>     ] map ;

: select-keys ( assoc keys -- alist )
  [ swap at ] with map ;

: my-http-get ( url -- data )
  [ (my-http-get) ]
  [
    summary "%s, retrying" printf
    [ (my-http-get) ] [ summary "%s, not retrying" printf ] recover
  ]
  recover ;

! project-env stuff

SYMBOL: project-env
ERROR:  wrong-project-env word ;

TUPLE: user-env ; final
M:     user-env present drop "user-env" ;

ERROR: not-user-env < wrong-project-env ; final
M:     not-user-env
  summary word>> name>> "can't use word %s in dev environment" sprintf ;

TUPLE: dev-env ; final
M:     dev-env present drop "dev-env" ;

ERROR: not-dev-env < wrong-project-env ; final
M:     not-dev-env
  summary word>> name>> "can't use word %s in user environment"  sprintf ;

ERROR:  not-an-exercism-folder word ;
M:      not-an-exercism-folder summary
  word>> name>> "exercism.testing: %s: current directory is not an exercism folder" sprintf ;

HOOK: exercises-folder project-env ( -- dirname )
M: dev-env  exercises-folder  "exercises" ; inline
M: user-env exercises-folder  "."         ; inline
M: f        exercises-folder  \ exercises-folder not-an-exercism-folder ;
