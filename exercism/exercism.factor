USING: accessors assocs io.directories io.files.info kernel
  sequences ;
IN: exercism
: child-directories ( path -- directories )
  directory-entries
  [ directory? ] filter
  [ name>>     ] map ;

: select-keys ( assoc keys -- alist )
  [ swap at ] with map ;
