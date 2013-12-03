(:~
 : Module for encoding and decoding <code>xs:string</code>s as <code>xs:byte</code>
 : sequences using the UTF-8 encoding scheme.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 :)
module namespace utf8 = 'http://www.basex.org/modules/utf8';

(:~ Number of states encoded in one block of 6 bits. :)
declare %private variable $utf8:ONE   := math:pow(2, 6);
(:~ Number of states encoded in two blocks of 6 bits. :)
declare %private variable $utf8:TWO   := $utf8:ONE * $utf8:ONE;
(:~ Number of states encoded in three blocks of 6 bits. :)
declare %private variable $utf8:THREE := $utf8:ONE * $utf8:TWO;

(:~ Codepoint of the Unicode Character 'REPLACEMENT CHARACTER' (U+FFFD). :)
declare %private variable $utf8:replacement := 65533;

(:~
 : Encodes a string as a sequence of bytes, using the UTF-8 encoding scheme.
 :
 : @param $str the input string
 : @return sequence of bytes encoding the given string
 :)
declare %public function utf8:encode(
  $str as xs:string
) as xs:byte* {
  for $cp in string-to-codepoints($str),
      $byte in
        if($cp lt 128) then $cp
        else if($cp lt 2048) then (
          $cp idiv $utf8:ONE -  64,
          $cp mod  $utf8:ONE - 128
        ) else if($cp lt 65536) then (
          $cp idiv $utf8:TWO -  32,
          $cp idiv $utf8:ONE mod $utf8:ONE - 128,
          $cp mod $utf8:ONE - 128
        ) else (
          $cp idiv $utf8:THREE - 16,
          $cp idiv $utf8:TWO mod $utf8:ONE - 128,
          $cp idiv $utf8:ONE mod $utf8:ONE - 128,
          $cp mod $utf8:ONE - 128
        )
  return xs:byte($byte)
};

(:~
 : Decodes a string from a sequence of bytes, assuming correct UTF-8 as input.
 : The string is decoded in lenient mode, non-parseable bytes are replaced.
 : @param $utf8 input byte sequence
 : @return the string decoded from the input sequence
 :)
declare %public function utf8:decode(
  $utf8 as xs:byte*
) as xs:string {
  utf8:decode($utf8, false())
};

(:~
 : Decodes a string from a sequence of bytes, assuming correct UTF-8 as input.
 : @param $utf8 input byte sequence
 : @param $strict strict parsing mode, <code>false</code>
 : @return the string decoded from the input sequence
 : @throws utf8:DECB0001 if a non-start byte occurs out of order
 : @throws utf8:DECB0002 if an invalid start byte was found
 : @throws utf8:DECB0003 if a start byte was found where it wasn't expected
 : @throws utf8:DECB0004 if the byte sequence ended unexpectedly
 :)
declare %public function utf8:decode(
  $utf8 as xs:byte*,
  $strict as xs:boolean
) as xs:string {
  let $result :=
    fold-left(
      utf8:decode-step(?, ?, $strict),
      map { 'more' := 0, 'bits' := 0, 'cps' := () },
      $utf8
    )
  let $str := codepoints-to-string($result('cps'))
  return if($result('more') eq 0) then $str
  else (
    utf8:error(
      $strict,
      4,
      'Unexpected end of input: "' || $str || '".',
      $result('cps')
    ),
    $str
  )[2]
};

(:~
 : Reads the next byte.
 : @param $state state of the decoding process
 : @param $byte next byte to read
 : @param $strict strictness flag
 : @return new state
 : @throws utf8:DECB0001 if a non-start byte occurs out of order
 : @throws utf8:DECB0002 if an invalid start byte was found
 : @throws utf8:DECB0003 if a start byte was found where it wasn't expected
 :)
declare %private function utf8:decode-step(
  $state as map(*),
  $byte as xs:byte,
  $strict as xs:boolean
) as map(*) {
  let $more := $state('more'),
      $cps  := $state('cps')
  return if($more eq 0) then
    if($byte ge 0) then map {
      'more' := 0,
      'bits' := 0,
      'cps'  := ($cps, $byte)
    } else if($byte lt -64) then (
      utf8:error(
        $strict,
        1,
        'Start byte expected after "' ||
          codepoints-to-string($cps) || '", found: ' || $byte,
        $cps
      )
    ) else if($byte lt -8) then (
      let $limit := (32, 16, 8),
          $size  := head($limit[. lt -$byte])
      return map {
        'more' := index-of($limit, $size),
        'bits' := ($byte + 256) mod $size,
        'cps'  := $cps
      }
    ) else utf8:error(
      $strict,
      2,
      'Invalid start byte ' || $byte || ' after: "' ||
        codepoints-to-string($cps) || '"',
      $cps
    )
  else if($byte ge -64) then utf8:decode-step(
    utf8:error(
      $strict,
      3,
      'Unexpected start byte after "' ||
        codepoints-to-string($cps) || '", found: ' || $byte,
      $cps
    ),
    $byte,
    $strict
  ) else
    let $more := $more - 1,
        $bits := $state('bits') * 64 + ($byte + 256) mod 64
    return map {
      'more' := $more,
      'bits' := $bits,
      'cps'  := if($more eq 0) then ($cps, $bits) else $cps
    }
};

(:~
 : Handles an error while decoding a UTF-8 byte sequence.
 : @param $strict strict parsing flag
 : @param $num error number
 : @param $msg error message
 : @return new state
 : @throws utf8:* error
 :)
declare %private function utf8:error(
  $strict as xs:boolean,
  $num as xs:integer,
  $msg as xs:string,
  $cps as xs:integer*
) as map(*)? {
  if($strict)
    then error(QName('http://www.basex.org/modules/utf8', 'utf8:DECB000' || $num), $msg)
    else map{ 'more' := 0, 'bits' := 0, 'cps' := ($cps, $utf8:replacement) }
};
