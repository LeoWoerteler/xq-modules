(:~
 : A linked list.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace list = 'http://www.basex.org/modules/list';

(:~
 : Returns the empty list.
 : @return empty list
 :)
declare %public function list:nil() {
  function($nil, $cons) {
    $nil()
  }
};

(:~
 : Creates a non-empty list with the given first element and rest of the list.
 :
 : @param $head the first element
 : @param $tail rest of the list
 : @return non-empty list
 :)
declare %public function list:cons(
  $head as item()*,
  $tail as function(*)
) as function(*) {
  function($nil, $cons) {
    $cons($head, $tail)
  }
};

(:~
 : Performs case analysis on the given list and calls the corresponding
 : callback for an empty and non-empty list.
 :
 : @param $list list to match
 : @param $nil callback for the empty list
 : @param $cons case for the non-empty list
 : @return result of the callback
 :)
declare %public function list:match(
  $list as function(*),
  $nil as function(*),
  $cons as function(*)
) as item()* {
  $list($nil, $cons)
};

(:~
 : Performs a left fold on the given list.
 :
 : @param $f combining function
 : @param $z starting value
 : @param $list list to fold over
 : @return the folding result
 :)
declare %public function list:fold-left(
  $f as function(item()*, item()*) as item()*,
  $z as item()*,
  $list as function(*)
) as item()* {
  let $go :=
      function($go, $acc, $xs) {
        $xs(
          function() { $acc },
          function($hd, $tl) { $go($go, $f($acc, $hd), $tl) }
        )
      }
  return $go($go, $z, $list)
};

(:~
 : Performs a right fold on the given list.
 :
 : @param $f combining function
 : @param $z starting value
 : @param $list list to fold over
 : @return the folding result
 :)
declare %public function list:fold-right(
  $f as function(item()*, item()*) as item()*,
  $z as item()*,
  $list as function(*)
) as item()* {
  let $go :=
      function($go, $xs) {
        $xs(
          function() { $z },
          function($hd, $tl) { $f($hd, $go($go, $tl)) }
        )
      }
  return $go($go, $list)
};

(:~
 : Reverses the given list.
 :
 : @param $list the list to reverse
 : @return the reversed list
 :)
declare %public function list:reverse(
  $list as function(*)
) as function(*) {
  list:fold-left(
    function($xs, $x) { list:cons($x, $xs) },
    list:nil(),
    $list
  )
};
