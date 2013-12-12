xquery version "3.0";

import module namespace ordered-map = 'http://www.woerteler.de/xquery/modules/ordered-map'
  at '../../../main/xquery/modules/ordered-map.xqm';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
  at '../../../main/xquery/modules/pair.xqm';

declare namespace map = 'http://www.w3.org/2005/xpath-functions/map';

declare function local:insert($maps, $key, $i) {
  let $tree := $maps('tree'),
      $map := $maps('map')
  return map:new((
    map:entry(
      'tree',
      ordered-map:check(
        ordered-map:insert($tree, $key, $i),
        -1,
        100000,
        xs:string($i)
      )
    ),
    map:entry(
      'map',
       map:new(($map, map:entry($key, $i)))
    )
  ))
};

declare function local:lookup($maps, $key, $i) {
  let $tree := $maps('tree'),
      $map := $maps('map')
  return ordered-map:lookup(
    $tree,
    $key,
    function($val) {
      if($map($key) eq $val) then $maps
      else error(QName('test', 'asdf'), xs:string($i))
    },
    function() {
      if(empty($map($key))) then $maps
      else error(QName('test', 'asdf'), xs:string($i))
    }
  )
};

declare function local:delete($maps, $key, $i) {
  let $tree := $maps('tree'),
      $map := $maps('map')
  return map:new((
    map:entry(
      'tree',
      ordered-map:check(
        ordered-map:delete($tree, $key),
        -1,
        100000,
        xs:string($i)
      )
    ),
    map:entry(
      'map',
      map:remove($map, $key)
    )
  ))
};

ordered-map:to-xml(
  fold-left(
    for-each-pair(
      random:seeded-integer(42, 10000, 3000),
      1 to 100000,
      pair:new#2
    ),
    map:new((
      map:entry('tree', ordered-map:new(function($a, $b) { $a < $b })),
      map:entry('map',  map:new())
    )),
    function($maps, $pair) {
      pair:deconstruct(
        $pair,
        function($r, $i) {
          let $op := $r mod 3,
              $key := $r idiv 3
          return if($op eq 0) then local:insert($maps, $key, xs:string($i))
          else if($op eq 1) then local:delete($maps, $key, xs:string($i))
          else local:lookup($maps, $key, xs:string($i))
        }
      )
    }
  )('tree')
)
