xquery version "3.0";

import module namespace ordered-map = 'http://www.woerteler.de/xquery/modules/ordered-map'
  at '../../../main/xquery/modules/ordered-map.xqm';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
  at '../../../main/xquery/modules/pair.xqm';

declare namespace map = 'http://www.w3.org/2005/xpath-functions/map';

ordered-map:to-xml(
  fold-left(
    for-each-pair(
      random:seeded-integer(42, 100000, 30000),
      1 to 100000,
      pair:new#2
    ),
    ordered-map:new(function($a, $b) { $a < $b }),
    function($tree, $pair) {
      pair:deconstruct(
        $pair,
        function($r, $i) {
          let $op := $r mod 3,
              $key := $r idiv 3
          return if($op eq 0) then (
            ordered-map:insert($tree, $key, $i)
          ) else if($op eq 1) then  (
            ordered-map:delete($tree, $key)
          ) else (
            $tree
          )
        }
      )
    }
  )
)
