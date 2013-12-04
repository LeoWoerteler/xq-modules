
import module namespace heap = 'http://www.basex.org/modules/heap'
    at '../../main/xquery/modules/heap.xqm';

heap:sort(
  function($a, $b) { $a > $b },
  1 to 10000
)
