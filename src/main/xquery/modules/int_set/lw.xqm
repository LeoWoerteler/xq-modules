xquery version "3.0";

(:~
 : Implementation of a set of integers based on a Red-Black Map.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace int-set = 'http://www.woerteler.de/xquery/modules/int-set/lw';

import module namespace tree = "http://www.woerteler.de/xquery/modules/ordered-map/rbtree"
    at '../ordered_map/rbtree.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

(:~
 : Empty set, which is the empty Red-Black Tree.
 :
 : @return empty set
 :)
declare function int-set:empty() {
  tree:empty()
};

(:~
 : Inserts the given integer into the given set.
 :
 : @param $set the Red-Black Tree
 : @param $x the integer
 : @return tree where <code>$x</code> was inserted
 :)
declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  tree:insert($int-set:LT, $set, $x, ())
};

(:~
 : Checks if the given integer is contained in the given Red-Black Tree.
 :
 : @param $set the Red-Black Tree
 : @param $x the integer
 : @return <code>true()</code> if the integer is contained in the tree,
           <code>false()</code> otherwise
 :)
declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
  tree:lookup(
    $int-set:LT,
    $set,
    $x,
    function($val) { true() },
    function() { false() }
  )
};
