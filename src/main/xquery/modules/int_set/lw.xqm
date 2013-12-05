xquery version "3.0";

(:~
 : Implementation of a set of integers based on a Red-Black Map.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace int-set = 'http://www.woerteler.de/xquery/modules/int-set/lw';

import module namespace rbtree = "http://www.woerteler.de/xquery/modules/ordered-map/rbtree"
    at '../ordered_map/rbtree.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

declare function int-set:empty() {
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
