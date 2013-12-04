(:~
 : Implementation of a set of integers based on a Red-Black Map.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace int-set = 'int-set/lw';

import module namespace rbtree = "http://www.basex.org/modules/ordered-map/rbtree"
  at '../ordered_map/rbtree.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

declare function int-set:new() {
  rbtree:empty()
};

declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:insert($int-set:LT, $set, $x, ())
};

declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:lookup(
    $int-set:LT,
    $set,
    $x,
    function($val) { true() },
    function() { false() }
  )
};
