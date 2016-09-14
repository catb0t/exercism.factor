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

CONSTANT: local-version-file  "VERSION.txt"
CONSTANT: remote-version-file "/VERSION.txt"

SYMBOL: self-update-now?
SYMBOL: version-lines

TUPLE: version-type ;
TUPLE: local  < version-type ; final
TUPLE: remote < version-type ; final

M: local  present drop "local"  ;
M: remote present drop "remote" ;

GENERIC: (get-version) ( -- version-lines )

M: local (get-version)
  local-version-file utf8 file-lines ;

M: remote (get-version)
  own-rawgit-url-stub remote-version-file append
  my-http-get nip string-lines ;

TYPED: serialise-nowtime ( -- nowtime: string )
  now timestamp>unix-time >integer number>string ;

TYPED: epoch>minutes ( epoch: number -- minutes: number )
  unix-time>timestamp ago duration>minutes floor ;

! pure
: directories>git-urls ( directories -- urls )
  [ own-rawgit-url-stub prepend-path ] map ;

! pure
: directories>filenames ( directories -- filenames )
  [
    ".factor" { "" "-docs" "-tests" }
    [ glue ]
    2with map
  ] map zip ;

: checksum-local-files ( -- checksum )
  "*/*.factor" glob natural-sort [
    utf8 file-lines
  ] map concat
  [ "\n" append ] map "" join ! Add newlines between and at the end (factor/factor#1708)
  sha-224 checksum-bytes bytes>hex-string ;


: get-version ( version-type -- version-lines )
  [ (get-version) ] with-exercism-root ;

: do-update? ( -- self-update-now? )
  f self-update-now? set

  [
    { local remote }
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
      { [ dup { f f } = ] [
        drop "nocorrel; local is ahead!" print ] }
      { [ dup { t f } = ] [
        drop "samesha2; local is equal  & older: no update" print ] }
      { [ dup { f t } = ] [
        drop "timegteq; remote is ahead & newer: UPDATE" print t self-update-now? set ] }
      { [ dup { t t } = ] [
        drop "bothtrue; remote is equal & newer: no update" print ] }
    } cond
    self-update-now? get

  ] with-exercism-root ;


: generate-urls ( -- urls )
  [
    "." child-directories
    [ directories>git-urls ]
    [ directories>filenames ]
    bi

    ! append and package
    [
      first2 [ append-path ] with map
    ] map zip
  ] with-exercism-root ;

: download-file-urls ( urls -- )
  [
    "\n" write
    [
      first2 swap
      [
        [
          [ "GET: %s\n" printf ]
          [ download ]
          bi
        ]
        each
      ] with-directory
    ]
    each
    "\n" write
  ] with-exercism-root ;

: self-update ( -- )
  [ generate-urls download-file-urls ] with-exercism-root ;

: bump-version ( -- )
  [
    checksum-local-files
    serialise-nowtime

    2array
    [ [ print ] each ]
    [ local-version-file utf8 set-file-lines ]
    bi
  ] with-exercism-root ;

: humanise-version ( -- )
  "versions:" print
  { local remote }
  [
    "\n" write
    [ print ]
    [
      get-version first2
      [ print ] dip string>number

      [ "%d" printf ]
      [ epoch>minutes " (%s minutes ago)\n" printf ]
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
