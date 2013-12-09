
import module namespace heap = 'http://www.woerteler.de/xquery/modules/heap'
    at '../../main/xquery/modules/heap.xqm';

import module namespace map = 'http://www.woerteler.de/xquery/modules/ordered-map'
    at '../../main/xquery/modules/ordered-map.xqm';

declare variable $doc := doc('../resources/southern_germany.xml');

declare variable $empty-map := map:new(function($a, $b) { $a < $b });

declare %basex:lazy variable $cities as function(*) :=
  fold-left(
    $doc//vertex,
    $empty-map,
    function($m, $v) {
      map:insert($m, xs:string($v/@name), xs:integer($v/@id))
    }
  );

declare %basex:lazy variable $names as function(*) :=
  fold-left(
    $doc//vertex,
    $empty-map,
    function($m, $v) {
      map:insert($m, xs:integer($v/@id), xs:string($v/@name))
    }
  );

declare %basex:lazy variable $dists :=
  fold-left(
    $doc//vertex,
    $empty-map,
    function($start, $v) {
      map:insert(
        $start,
        xs:integer($v/@id),
        fold-left(
          $v/edge,
          fold-left(
            $doc//edge[text() = $v/@id],
            $empty-map,
            function($dest, $e) {
              map:insert($dest, xs:integer($e/../@id), xs:double($e/@weight))
            }
          ),
          function($dest, $e) {
            map:insert($dest, xs:integer($e), xs:double($e/@weight))
          }
        )
      )
    }
  );

declare function local:dijkstra($from, $to) {
  local:dijkstra(
    $empty-map,
    map:insert($empty-map, $from, 0),
    heap:insert(
      heap:new(function($a, $b) { $a[1] < $b[1] }),
      (0, $from)
    ),
    $to
  )
};

declare function local:dijkstra($visited, $shortest, $heap, $to) {
  if(map:contains($visited, $to)) then
    (: We found a path :)
    <result distance="{map:get($shortest, $to)}">{
      local:path($visited, $to)
    }</result>
  else heap:extract-min(
    $heap,
    function() {
      (: priority queue is empty, no path found :)
      <no-result/>
    },
    function($path-to-a, $tail-heap) {
      let $dist-to-a := $path-to-a[1],
          $a         := $path-to-a[2],
          $before-a  := $path-to-a[3]
      let $inserted  :=
        (: insert newly found paths :)
        map:fold(
          map:get($dists, $a),
          ($tail-heap, $shortest),
          function($state, $b, $a-to-b) {
            let $curr-heap := $state[1],
                $shortest2 := $state[2],
                $dist-to-b := $dist-to-a + $a-to-b
            return if(map:get($shortest2, $b) < $dist-to-b) then $state
            else (
              (: this path to $b is the shortest until now, add it to the queue :)
              heap:insert($curr-heap, ($dist-to-b, $b, $a)),
              map:insert($shortest2, $b, $dist-to-b)
            )
          }
        )
      let $new-heap := $inserted[1],
          $new-seen := $inserted[2]
      return local:dijkstra(
        map:insert($visited, $a, $before-a),
        $new-seen,
        $new-heap,
        $to
      )
    }
  )
};

declare function local:path($visited, $pos) {
  if(empty($pos)) then ()
  else (
    local:path($visited, map:get($visited, $pos)),
    <step>{ map:get($names, $pos) }</step>
  )
};

map:for-each-entry(
  $cities,
  function($from, $fid) {
    map:for-each-entry(
      $cities,
      function($to, $tid) {
        <path from="{$from}" to="{$to}">{
          local:dijkstra($fid, $tid)
        }</path>
      }
    )
  }
)
