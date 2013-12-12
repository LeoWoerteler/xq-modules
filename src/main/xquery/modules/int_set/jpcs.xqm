xquery version "3.0";

(:~
 : Implementation of a set of integers based on John Snelson's Red-Black Tree.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace int-set = 'http://www.woerteler.de/xquery/modules/int-set/jpcs';

import module namespace rbtree = 'http://snelson.org.uk/functions/rbtree'
    at 'rbtree_jpcs.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

(:~
 : Empty set, which is the empty Red-Black Tree.
 :
 : @return empty set
 :)
declare function int-set:empty() {
  rbtree:create()
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
  rbtree:insert($int-set:LT, $set, $x)
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
  rbtree:contains($int-set:LT, $set, $x)
};
