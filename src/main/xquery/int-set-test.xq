
import module namespace int-set = "int-set" at 'modules/int-set.xqm';

import module namespace pair = 'http://www.basex.org/modules/pair'
  at 'modules/pair.xqm';

declare variable $OPS := 2;

declare function local:insert($maps, $key, $i) {
  prof:dump($key, 'insert'),
  let $tree := $maps('tree'),
      $map  := $maps('map')
  return {
    'tree' : int-set:insert($tree, $key),
    'map'  : map:new(($map, { $key : () }))
  }
};

declare function local:lookup($maps, $key, $i) {
  prof:dump($key, 'lookup'),
  let $tree := $maps('tree'),
      $map  := $maps('map'),
      $res1 := int-set:contains($tree, $key),
      $res2 := map:contains($map, $key)
  return
    if(deep-equal($res1, $res2)) then $maps
    else error(QName('test', 'asdf'), xs:string($i))
};

fold-left(
  for-each-pair(
    random:seeded-integer(42, 100000, 10000 * $OPS),
    1 to 100000,
    pair:new#2
  ),
  {
    'tree' : int-set:new(),
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
