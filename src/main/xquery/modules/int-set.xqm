(:~
 : Abstract interface for a set of integers.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace int-set = 'http://www.basex.org/modules/int-set';

(:
import module namespace impl = "http://www.basex.org/modules/int-set/jpcs"
    at 'int_set/jpcs.xqm';
:)

import module namespace impl = "http://www.basex.org/modules/int-set/lw"
    at 'int_set/lw.xqm';

(:~
 : Returns the empty set.
 : @return the empty set
 :)
declare function int-set:empty() {
  impl:empty()
};

(:~
 : Inserts the given integer into the given set and returns the resulting set.
 : @param $set set to insert into
 : @param $x element to insert
 : @return the set that contains <code>$x</code> in addition to
           all elements of <code>$set</code>
 :)
declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  impl:insert($set, $x)
};

(:~
 : Checks if the given element is contained in the given check.
 : @param $set set to search in
 : @param $x element to look for
 : @return <code>true()</code> if the element is contained in the set,
           <code>false()</code> otherwise
 :)
declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
 impl:contains($set, $x)
};
