USING: arrays assocs calendar checksums checksums.sha
  combinators command-line exercism.testing.private formatting
  globs http.client io io.directories io.encodings.utf8 io.files
  io.pathnames kernel locals math math.functions math.parser
  namespaces prettyprint sequences sorting splitting
  tools.scaffold.private unicode ;
IN: exercism.self-update

<PRIVATE

CONSTANT: own-rawgit-url-stub
  "https://raw.githubusercontent.com/catb0t/exercism.factor/master/exercism"

SYMBOL: self-update-now?
SYMBOL: version-lines

: with-exercism-root ( quot -- )
  [ "exercism" vocab>path absolute-path ] dip with-directory ; inline

: get-version ( version-type -- version-lines )
  [
    {
      { [ dup "local" = ] [ drop "VERSION.txt" utf8 file-lines version-lines set ] }
      { [ dup "remote" = ] [ drop own-rawgit-url-stub "/VERSION.txt" append http-get nip string-lines version-lines set ] }
        [ "bad cond to get-version" throw ]
    } cond
    version-lines get
  ] with-exercism-root ;

: do-update? ( -- self-update-now? )
  f self-update-now? set
  [
    { "local" "remote" }
    [ get-version ] map first2 swap 2dup =

    [ 2drop { t t } ]
    [
      zip
      [ first first2 = ]
      [ second [ string>number ] map first2 >= ]
      bi 2array
    ]
    if

    {
      { [ dup { f f } = ] [ drop "nocorrel; client is ahead, publish your local changes!" print ] }
      { [ dup { t f } = ] [ drop "samesha2; client is equal & newer: no update" print ] }
      { [ dup { f t } = ] [ drop "timegteq; server is ahead & newer: UPDATE" print t self-update-now? set ] }
      { [ dup { t t } = ] [ drop "bothtrue; server is equal & newer: no update" print ] }
    } cond
  ] with-exercism-root

  self-update-now? get ;

: generate-urls ( -- urls )
  [
    ! directories -> urls
    "." child-directories dup [
      own-rawgit-url-stub prepend-path
    ] map

    ! directories -> filenames
    over [
      ".factor"
      { "" "-docs" "-tests" }
      [ glue ]
      2with map
    ] map zip

    ! append and package
    [
      first2 [ append-path ] with map
    ] map zip
  ] with-exercism-root ;

: download-file-urls ( urls -- )
  [
    [
      first2 swap
      [
        [
          [ "GET: %s" printf ]
          [ download ] bi
        ]
        each
      ] with-directory
    ]
    each
  ] with-exercism-root ;

: self-update ( -- )
  [ generate-urls download-file-urls ] with-exercism-root ;

: bump-version ( -- )
  [
    "*/*.factor" glob natural-sort [
      utf8 file-lines
    ] map concat
    [ "\n" append ] map "" join ! Add newlines between and at the end (factor/factor#1708)
    sha-224 checksum-bytes bytes>hex-string

    now timestamp>unix-time >integer number>string

    2array
    [ [ print ] each ]
    [ "./VERSION.txt" utf8 set-file-lines ]
    bi
  ] with-exercism-root ;

: humanise-version ( -- )
  "versions:" print
  { "local" "remote" }
  [
    "\n" write
    [ print ]
    [
      get-version
      first2 [ print ] dip string>number
      [ "%d" printf ]
      [ unix-time>timestamp ago duration>minutes floor " (%s minutes ago)\n" printf ]
      bi
    ]
    bi
  ] each ;


PRIVATE>


: exercism-self-update ( -- )
  [ do-update? [ self-update bump-version ] when ] with-exercism-root ;

: choose-update-action ( arg -- )
  >lower
  [ {
      { [ dup "update"      = ] [ drop exercism-self-update ] }
      {
        [ dup [ "bumpver" = ] [ "bump" = ] bi or ]
        [ drop "bumping version" print bump-version ]
      }
      { [ dup "wouldupdate" = ] [ drop do-update? drop ] }
      { [ dup [ "version" = ] [ "curver" = ] bi or ] [ drop humanise-version ] }
        [ "exercism.self-update: exercism-update-main: bad last argument `%s', expected: 'update', 'bumpver', 'wouldupdate'\n" printf ]
    } cond
  ] with-exercism-root ;

: exercism-update-main ( -- )
  (command-line) last choose-update-action ;

MAIN: exercism-update-main