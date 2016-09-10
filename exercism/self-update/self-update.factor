USING: arrays assocs calendar checksums checksums.sha
  combinators exercism.testing.private formatting globs http.client io io.directories
  io.encodings.utf8 io.files io.pathnames kernel math math.parser
  prettyprint sequences sorting splitting tools.scaffold.private ;
IN: exercism.self-update

CONSTANT: own-rawgit-url-stub
  "https://raw.githubusercontent.com/catb0t/exercism.factor/master/exercism"

: do-update? ( -- ? )
  own-rawgit-url-stub "VERSION.txt" append http-get nip string-lines
  "VERSION.txt" utf8 file-lines
  2dup =

  [ 2drop { t t } ]
  [
    zip
    [ first first2 = ]
    [ second [ string>number ] map first2 >= ]
    bi 2array
  ]
  if ;

: generate-urls ( -- urls )
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
  ] map zip ;

: download-file-urls ( urls -- )
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
  each ;

: self-update ( -- )
  generate-urls download-file-urls ;

: bump-version ( -- )
  

  "testing*.factor" glob natural-sort [ utf8 file-lines ] map concat
  sha-224 checksum-lines bytes>hex-string
  now timestamp>unix-time >integer number>string
  2array . ! "./VERSION.txt" utf8 set-file-lines
  ;

: exercism-self-update ( -- )
  "exercism" vocab>path absolute-path
  [
    do-update?
    {
      { [ dup { f f } = ] [ drop "nocorrel; client is ahead, publish your local changes!" print ] }
      { [ dup { t f } = ] [ drop "samesha2; client is equal & newer: not updating " print ] }
      { [ dup { f t } = ] [ drop "timegteq; server is ahead & newer: UPDATING" print self-update bump-version ] }
      { [ dup { t t } = ] [ drop "bothtrue; server is equal & newer: not updating" print ] }
    } cond

  ] with-directory ;

MAIN: exercism-self-update