(:~
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 :)
module namespace int-set = 'int-set';

import module namespace impl = "int-set/jpcs" at 'int_set/jpcs.xqm';
(:import module namespace impl = "int-set/lw" at 'int_set/lw.xqm';:)

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
