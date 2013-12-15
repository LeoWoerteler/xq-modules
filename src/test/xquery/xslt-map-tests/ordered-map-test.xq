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
    (
      ordered-map:new(function($a, $b) { $a < $b }),
      map:new()
    ),
    function($maps, $pair) {
      pair:deconstruct(
        $pair,
        function($r, $i) {
          let $op := $r mod 3,
              $key := $r idiv 3
          return if($op eq 0) then (
            ordered-map:check(
              ordered-map:insert($maps[1], $key, $i),
              -1, 100000,
              xs:string($i)
            ),
            map:new(($maps[2], map:entry($key, $i)))
          ) else if($op eq 1) then (
            ordered-map:check(
              ordered-map:delete($maps[1], $key),
              -1, 100000,
              xs:string($i)
            ),
            map:remove($maps[2], $key)
          ) else (
            ordered-map:lookup(
              $maps[1],
              $key,
              function($val) {
                if(map:get($maps[2], $key) eq $val) then $maps
                else error(QName('test', 'asdf'), xs:string($i))
              },
              function() {
                if(not(map:contains($maps[2], $key))) then $maps
                else error(QName('test', 'asdf'), xs:string($i))
              }
            )
          )
        }
      )
    }
  )[1]
)
