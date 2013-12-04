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

declare function int-set:new() {
  impl:new()
};

declare function int-set:insert(
  $set as item()*,
  $x as xs:integer
) as item()* {
  impl:insert($set, $x)
};

declare function int-set:contains(
  $set as item()*,
  $x as xs:integer
) as item()* {
 impl:contains($set, $x)
};
