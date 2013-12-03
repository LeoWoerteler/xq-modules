(:~
 : A library for typed pairs of XQuery sequences.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 :)
module namespace pair = "http://www.basex.org/modules/pair";

declare %public function pair:new(
  $fst as item()*,
  $snd as item()*
) as function(*) {
  function($f) { $f($fst, $snd) }
};

declare %public function pair:first(
  $p as function(*)
) as item()* {
  $p(
    function($fst, $snd) { $fst }
  )
};

declare %public function pair:second(
  $p as function(*)
) as item()* {
  $p(
    function($fst, $snd) { $snd }
  )
};

declare %public function pair:deconstruct(
  $p as function(*),
  $receiver as function(item()*, item()*) as item()*
) as item()* {
  $p($receiver)
};
