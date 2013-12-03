
import module namespace ordered-map = 'http://www.basex.org/modules/ordered-map'
  at 'modules/ordered-map.xqm';

declare function local:insert($maps, $key, $i) {
  prof:dump($key, 'insert'),
  let $tree := $maps('tree'),
      $map := $maps('map')
  return {
    'tree' : ordered-map:insert($tree, $key, $i),
    'map' : map:new(($map, { $key : $i }))
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
    'tree' : ordered-map:delete($tree, $key),
    'map' : map:remove($map, $key)
  }
};

ordered-map:to-xml(
  fold-left(
    for-each-pair(
      random:seeded-integer(42, 100000, 30000),
      1 to 5,
      function($r, $i) { function($f) { $f($r, $i) } }
    ),
    {
      'tree' : ordered-map:new(function($a, $b) { $a < $b }),
      'map' : { }
    },
    function($maps, $rnd) {
      $rnd(
        function($r, $i) {
          let $op := $r mod 3,
              $key := $r idiv 3
          return if($op eq 0) then local:insert($maps, $key, $i)
          else if($op eq 1) then local:delete($maps, $key, $i)
          else local:lookup($maps, $key, $i)
        }
      )
    }
  )('tree')
)
