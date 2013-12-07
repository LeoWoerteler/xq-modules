
import module namespace int-set = "http://www.woerteler.de/xquery/modules/int-set"
    at '../../main/xquery/modules/int-set.xqm';

import module namespace map = "http://www.woerteler.de/xquery/modules/ordered-map"
    at '../../main/xquery/modules/ordered-map.xqm';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
    at '../../main/xquery/modules/pair.xqm';

import module namespace rng = 'http://www.woerteler.de/xquery/modules/rng'
    at '../../main/xquery/modules/rng.xqm';

declare variable $OPS := 2;

declare function local:insert($set, $map, $key, $i) {
  (
    $i + 1,
    int-set:insert($set, $key),
    map:insert($map, $key, ())
  )
};

declare function local:lookup($set, $map, $key, $i) {
  let $res1 := int-set:contains($set, $key),
      $res2 := map:contains($map, $key)
  return
    if(deep-equal($res1, $res2)) then ($i + 1, $set, $map)
    else error(QName('test', 'asdf'), xs:string($i))
};

rng:with-random-ints(
  42,
  100000,
  (
    1,
    int-set:empty(),
    map:new(function($a, $b) { $a < $b })
  ),
  function($state, $rand) {
    let $r   := abs($rand) mod (10000 * $OPS),
        $op  := $r mod $OPS,
        $key := $r idiv $OPS,
        $i   := $state[1],
        $set := $state[2],
        $map := $state[3]
    return if($op eq 0) then local:insert($set, $map, $key, $i)
    else local:lookup($set, $map, $key, $i)
  }
)[1]
