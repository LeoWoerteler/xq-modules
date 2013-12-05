
import module namespace pair = 'http://www.basex.org/modules/pair'
    at '../../main/xquery/modules/pair.xqm';

import module namespace heap = 'http://www.basex.org/modules/heap'
    at '../../main/xquery/modules/heap.xqm';

heap:sort(
  function($a, $b) { $a > $b },
  for $r at $i in random:seeded-integer(1234, 10000)
  order by $r
  return $i
)
