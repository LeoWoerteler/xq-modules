
import module namespace int-set = "http://www.woerteler.de/xquery/modules/int-set"
    at '../../main/xquery/modules/int-set.xqm';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
    at '../../main/xquery/modules/pair.xqm';

declare variable $OPS := 2;

declare function local:insert($maps, $key, $i) {
  let $tree := $maps('tree'),
      $map  := $maps('map')
  return {
    'tree' : int-set:insert($tree, $key),
    'map'  : map:new(($map, { $key : () }))
  }
};

declare function local:lookup($maps, $key, $i) {
  let $tree := $maps('tree'),
      $map  := $maps('map'),
      $res1 := int-set:contains($tree, $key),
      $res2 := map:contains($map, $key)
  return
    if(deep-equal($res1, $res2)) then $maps
    else error(QName('test', 'asdf'), xs:string($i))
};

fold-left(
  for $r at $i in random:seeded-integer(42, 100000, 10000 * $OPS)
  return pair:new($r, $i),
  {
    'tree' : int-set:empty(),
    'map' : { }
  },
  function($maps, $pair) {
    pair:deconstruct(
      $pair,
      function($r, $i) {
        let $op := $r mod $OPS,
            $key := $r idiv $OPS
        return if($op eq 0) then local:insert($maps, $key, $i)
        else local:lookup($maps, $key, $i)
      }
    )
  }
)[2]
