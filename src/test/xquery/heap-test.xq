xquery version "3.0";

import module namespace heap = 'http://www.woerteler.de/xquery/modules/heap'
    at '../../main/xquery/modules/heap.xqm';

import module namespace rng = 'http://www.woerteler.de/xquery/modules/rng'
    at '../../main/xquery/modules/rng.xqm';

heap:sort(
  function($a, $b) { $a > $b },
  for $r at $i in rng:random-ints(1234, 10000)
  order by $r
  return $i
)
