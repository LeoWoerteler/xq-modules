(:~
 : A module for converting between byte sequences and xs:base64Binary values.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 :)
module namespace base64 = 'http://www.basex.org/modules/base64';

(:~ Codepoint for the '=' padding character. :)
declare %private variable $base64:PAD as xs:integer := string-to-codepoints('=');

(:~ Encoding characters. :)
declare %private variable $base64:chars := string-to-codepoints(
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/');

(:~ Decoding table. :)
declare %private variable $base64:decode-table := map:new((
  map:entry($base64:PAD, -1),
  for $char at $pos in $base64:chars
  return map:entry($char, $pos - 1)
));

(:~
 : Encodes a sequence of <code>xs:byte</code>s into an <code>xs:base64Binary</code> value.
 : @param $bytes byte sequence to be converted
 : @return the <code>xs:base64Binary</code> value encoding the bytes
 :)
declare %public function base64:encode(
  $bytes as xs:byte*
) as xs:base64Binary {
  xs:base64Binary(
    codepoints-to-string(
      let $state :=
        fold-left(
          function($state as map(xs:string, xs:integer*), $byte as xs:byte) {
            let $bits  := $state('bits') * 256 + ($byte + 256) mod 256,
                $n     := ($state('n') + 8) mod 6,
                $rest  := (1, 4, 16)[$n idiv 2 + 1],
                $use   := $bits idiv $rest
            return map {
              'bits' := $bits mod $rest,
              'n'    := $n,
              'cps'  := (
                $state('cps'),
                if($n eq 0) then $base64:chars[$use idiv 64 + 1] else (),
                $base64:chars[$use mod 64 + 1]
              )
            }
          },
          map { 'bits' := 0, 'n' := 0, 'cps' := () },
          $bytes
        )
      return (
        $state('cps'),
        switch($state('n'))
          case 2 return ($base64:chars[$state('bits') * 16 + 1], $base64:PAD, $base64:PAD)
          case 4 return ($base64:chars[$state('bits') *  4 + 1], $base64:PAD)
          default return ()
      )
    )
  )
};

(:~
 : Decodes a sequence of bytes from a <code>xs:base64Binary</code> value.
 : @param $b64 value to be decoded
 : @return decoded bytes
 :)
declare %public function base64:decode(
  $b64 as xs:base64Binary
) as xs:byte* {
  let $start  := map { 'more' := 4, 'out' := 3, 'bits' := 0, 'bytes' := () },
      $result := fold-left(
        function($state as map(xs:string, xs:integer*), $val as xs:integer) {
          let $more := $state('more') - 1,
              $bits := if($val ge 0) then $state('bits') * 64 + $val else $state('bits'),
              $out  := if($val ge 0) then $state('out') else $state('out') - 1
          return if($more eq 0) then map:new((
            $start,
            map:entry('bytes', (
                $state('bytes'),
                switch($out)
                  case 3 return ($bits idiv 65536, $bits idiv 256 mod 256, $bits mod 256)
                  case 2 return ($bits idiv  1024, $bits idiv   4 mod 256)
                  default return $bits idiv    16
              )
            )
          )) else map {
            'more' := $more, 'out' := $out, 'bits' := $bits, 'bytes' := $state('bytes')
          }
        },
        $start,
        for $cp in string-to-codepoints(xs:string($b64))
        return $base64:decode-table($cp)
      )
  for $byte in $result('bytes')
  return xs:byte(if($byte ge 128) then $byte - 256 else $byte)
};

