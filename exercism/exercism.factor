USING: accessors assocs continuations formatting http.client io
  io.directories io.encodings.utf8 io.files io.files.info
  io.pathnames kernel sequences summary tools.scaffold.private ;
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

CONSTANT: slugs-wordnames H{
    { "hello-world" "hello-name" }
    { "leap"        "leap-year?" }
  }