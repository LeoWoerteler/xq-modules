xquery version "3.0";

(:~
 : A library for typed pairs of XQuery sequences.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace pair = "http://www.woerteler.de/xquery/modules/pair";

(:~
 : Creates a pair from the given two values.
 : @param $fst first partner
 : @param $snd second partner
 : @return the pair
 :)
declare %public function pair:new(
  $fst as item()*,
  $snd as item()*
) as function(*) {
  function($f) { $f($fst, $snd) }
};

(:~
 : Gets the first partner of the given pair.
 : @param $p the pair
 : @return the first partner
 :)
declare %public function pair:first(
  $p as function(*)
) as item()* {
  $p(
    function($fst, $snd) { $fst }
  )
};

(:~
 : Gets the second partner of the given pair.
 : @param $p the pair
 : @return the second partner
 :)
declare %public function pair:second(
  $p as function(*)
) as item()* {
  $p(
    function($fst, $snd) { $snd }
  )
};

(:~
 : Deconstructs the given pair and calls the callback with the first and second partner.
 : @param $p the pair
 : @param $receiver the callback
 : @return the result of the callback
 :)
declare %public function pair:deconstruct(
  $p as function(*),
  $receiver as function(item()*, item()*) as item()*
) as item()* {
  $p($receiver)
};
