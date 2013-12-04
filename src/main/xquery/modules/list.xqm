(:~
 : A linked list.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace list = 'http://www.basex.org/modules/list';

declare %public function list:nil() {
  function($nil, $cons) {
    $nil()
  }
};

declare %public function list:cons(
  $head as item()*,
  $tail as function(*)
) as function(*) {
  function($nil, $cons) {
    $cons($head, $tail)
  }
};

declare %public function list:match(
  $list as function(*),
  $nil as function(*),
  $cons as function(*)
) as item()* {
  $list($nil, $cons)
};

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

declare %public function list:reverse(
  $list as function(*)
) as function(*) {
  list:fold-left(
    function($xs, $x) { list:cons($x, $xs) },
    list:nil(),
    $list
  )
};
