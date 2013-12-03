module namespace int-set = 'int-set/lw';

import module namespace rbtree = "http://www.basex.org/modules/ordered-map"
  at '../ordered-map.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

declare function int-set:new() {
  rbtree:new($int-set:LT)
};

declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:insert($set, $x, ())
};

declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:lookup(
    $set,
    $x,
    function($val) { true() },
    function() { false() }
  )
};
