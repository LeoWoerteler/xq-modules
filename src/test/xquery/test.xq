
import module namespace ordered-map = 'http://www.basex.org/modules/ordered-map'
  at 'modules/ordered-map.xqm';

import module namespace pair = 'http://www.basex.org/modules/pair'
  at 'modules/pair.xqm';

declare function local:insert($maps, $key, $i) {
  prof:dump($key, 'insert'),
  let $tree := $maps('tree'),
      $map := $maps('map')
  return {
    'tree' : ordered-map:check(
               ordered-map:insert($tree, $key, $i),
               -1,
               100000,
               xs:string($i)
             ),
    'map'  : map:new(($map, { $key : $i }))
  }
};

declare function local:lookup($maps, $key, $i) {
  prof:dump($key, 'lookup'),
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
  prof:dump($key, 'delete'),
  let $tree := $maps('tree'),
      $map := $maps('map')
  return {
    'tree' : ordered-map:check(
               ordered-map:delete($tree, $key),
               -1,
               100000,
               xs:string($i)
             ),
    'map'  : map:remove($map, $key)
  }
};

ordered-map:to-xml(
  fold-left(
    for-each-pair(
      random:seeded-integer(42, 10000, 3000),
      1 to 100000,
      pair:new#2
    ),
    {
      'tree' : ordered-map:new(function($a, $b) { $a < $b }),
      'map' : { }
    },
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
