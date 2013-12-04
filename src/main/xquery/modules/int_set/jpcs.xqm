(:~
 : Implementation of a set of integers based on John Snelson's Red-Black Tree.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace int-set = 'http://www.basex.org/modules/int-set/jpcs';

import module namespace rbtree = 'http://snelson.org.uk/functions/rbtree'
    at 'rbtree_jpcs.xqm';

declare variable $int-set:LT := function($a, $b) { $a lt $b };

declare function int-set:new() {
  rbtree:create()
};

declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:insert($int-set:LT, $set, $x)
};

declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
  rbtree:contains($int-set:LT, $set, $x)
};
