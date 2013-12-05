xquery version "3.0";

(:~
 : Implementation of an ordered map based on a Red-Black Tree.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace rbtree = 'http://www.basex.org/modules/ordered-map/rbtree';

import module namespace pair = 'http://www.basex.org/modules/pair'
  at '../pair.xqm';

declare %private variable $rbtree:DBL_RED as xs:integer := -1;
declare %private variable $rbtree:RED as xs:integer := 0;
declare %private variable $rbtree:BLACK as xs:integer := 1;
declare %private variable $rbtree:DBL_BLACK as xs:integer := 2;

declare %public function rbtree:empty() {
  rbtree:leaf($rbtree:BLACK)
};

declare %public function rbtree:lookup($lt, $tree, $x, $found, $notFound) {
  $tree(
    function($c) { $notFound() },
    function($c, $l, $k, $v, $r) {
      if($lt($x, $k)) then rbtree:lookup($lt, $l, $x, $found, $notFound)
      else if($lt($k, $x)) then rbtree:lookup($lt, $r, $x, $found, $notFound)
      else $found($v)
    }
  )
};

declare %public function rbtree:size($tree) {
  $tree(
    function($c) { 0 },
    function($c, $l, $k, $v, $r) {
      rbtree:size($l) + 1 + rbtree:size($r)
    }
  )
};

declare %public function rbtree:insert($lt, $root, $k, $v) as item()* {
  rbtree:recolor(rbtree:ins($lt, $root, $k, $v), $rbtree:BLACK)
};

declare %private function rbtree:ins($lt, $tree, $x, $y) {
  $tree(
    function($c) { rbtree:branch($rbtree:RED, rbtree:leaf(), $x, $y, rbtree:leaf()) },
    function($c, $l, $k, $v, $r) {
      if($lt($x, $k)) then (
        rbtree:balance-l($c, rbtree:ins($lt, $l, $x, $y), $k, $v, $r)
      ) else if($lt($k, $x)) then (
        rbtree:balance-r($c, $l, $k, $v, rbtree:ins($lt, $r, $x, $y))
      ) else (: $k eq $x :) (
        rbtree:branch($c, $l, $x, $y, $r)
      )
    }
  )
};

declare %public function rbtree:delete($lt, $root, $k) {
  rbtree:recolor(rbtree:del($lt, $root, $k), $rbtree:BLACK)
};

declare %private function rbtree:del($lt, $tree, $x) {
  $tree(
    function($c) { $tree },
    function($c, $l, $k, $v, $r) {
      if($lt($x, $k)) then (
        (: delete in the left sub-tree :)
        rbtree:bubble($c, rbtree:del($lt, $l, $x), $k, $v, $r)
      ) else if($lt($k, $x)) then (
        (: delete in the right sub-tree :)
        rbtree:bubble($c, $l, $k, $v, rbtree:del($lt, $r, $x))
      ) else (
        (: delete from the current node :)
        $l(
          function($lc) {
            $r(
              function($rc) {
                (: both children are leaves :)
                rbtree:leaf(rbtree:next($c))
              },
              function($rc, $rl, $rk, $rv, $rr) {
                (: $r must be red, color it black and move it up :)
                rbtree:branch($rbtree:BLACK, $rl, $rk, $rv, $rr)
              }
            )
          },
          function($lc, $ll, $lk, $lv, $lr) {
            $r(
              function($rc) {
                (: $r is a leaf, $l must be red, color it black and move it up :)
                rbtree:branch($rbtree:BLACK, $ll, $lk, $lv, $lr)
              },
              function($rc, $rl, $rk, $rv, $rr) {
                (: both sub-trees are inner nodes, replace contents :)
                let $res := rbtree:split-leftmost($rc, $rl, $rk, $rv, $rr),
                    $kv  := $res[1],
                    $r2  := $res[2]
                return $kv(
                  function($k, $v) {
                    rbtree:bubble($c, $l, $k, $v, $r2)
                  }
                )
              }
            )
          }
        )
      )
    }
  )
};

declare %private function rbtree:split-leftmost($c, $l, $k, $v, $r) {
  $l(
    function($lc) {
      pair:new($k, $v), 
      $r(
        function($rc) {
          rbtree:leaf(rbtree:next($c))
        },
        function($rc, $rl, $rk, $rv, $rr) {
          rbtree:branch($rbtree:BLACK, $rl, $rk, $rv, $rr)
        }
      )
    },
    function($lc, $ll, $lk, $lv, $lr) {
      let $res  := rbtree:split-leftmost($lc, $ll, $lk, $lv, $lr),
          $tree := rbtree:bubble($c, $res[2], $k, $v, $r)
      return ($res[1], $tree)
    }
  )
};

declare %private function rbtree:bubble($c, $l, $k, $v, $r) {
  if(rbtree:color($l) eq $rbtree:DBL_BLACK) then (
    rbtree:balance-r(
      rbtree:next($c),
      rbtree:recolor($l, $rbtree:BLACK),
      $k, $v,
      rbtree:recolor($r, rbtree:prev(rbtree:color($r)))
    )
  ) else if(rbtree:color($r) eq $rbtree:DBL_BLACK) then (
    rbtree:balance-l(
      rbtree:next($c),
      rbtree:recolor($l, rbtree:prev(rbtree:color($l))),
      $k, $v,
      rbtree:recolor($r, $rbtree:BLACK)
    )
  ) else (
    rbtree:branch($c, $l, $k, $v, $r)
  )
};

declare %private function rbtree:balance-l($c, $l, $k, $v, $r) {
  if($c = ($rbtree:BLACK, $rbtree:DBL_BLACK)) then (
    if($c eq $rbtree:DBL_BLACK and rbtree:color($l) eq $rbtree:DBL_RED) then (
      $l(
        function($lc) { error() },
        function($lc, $ll, $lk, $lv, $lr) {
          $lr(
            function($lc) { error() },
            function($lrc, $lrl, $lrk, $lrv, $lrr) {
              rbtree:branch(
                $rbtree:BLACK,
                rbtree:balance-l($rbtree:BLACK, rbtree:recolor($ll, $rbtree:RED), $lk, $lv, $lrl),
                $lrk, $lrv,
                rbtree:branch($rbtree:BLACK, $lrr, $k, $v, $r)
              )
            }
          )
        }
      )
    ) else if(rbtree:color($l) eq $rbtree:RED) then (
      $l(
        function($lc) { error() },
        function($lc, $ll, $lk, $lv, $lr) {
          if(rbtree:color($ll) eq $rbtree:RED) then (
            rbtree:branch(
              rbtree:prev($c),
              rbtree:recolor($ll, $rbtree:BLACK),
              $lk, $lv,
              rbtree:branch($rbtree:BLACK, $lr, $k, $v, $r)
            )
          ) else if(rbtree:color($lr) eq $rbtree:RED) then (
            $lr(
              function($lrc) { error() },
              function($lrc, $lrl, $lrk, $lrv, $lrr) {
                rbtree:branch(
                  rbtree:prev($c),
                  rbtree:branch($rbtree:BLACK, $ll, $lk, $lv, $lrl),
                  $lrk, $lrv,
                  rbtree:branch($rbtree:BLACK, $lrr, $k, $v, $r)
                )
              }
            )
          ) else (
            rbtree:branch($c, $l, $k, $v, $r)
          )
        }
      )
    ) else (
      rbtree:branch($c, $l, $k, $v, $r)
    )
  ) else (
    rbtree:branch($c, $l, $k, $v, $r)
  )
};

declare %private function rbtree:balance-r($c, $l, $k, $v, $r) {
  if($c = ($rbtree:BLACK, $rbtree:DBL_BLACK)) then (
    if($c eq $rbtree:DBL_BLACK and rbtree:color($r) eq $rbtree:DBL_RED) then (
      $r(
        function($rc) { error() },
        function($rc, $rl, $rk, $rv, $rr) {
          $rl(
            function($rlc) { error() },
            function($rlc, $rll, $rlk, $rlv, $rlr) {
              rbtree:branch(
                $rbtree:BLACK,
                rbtree:branch($rbtree:BLACK, $l, $k, $v, $rll),
                $rlk, $rlv,
                rbtree:balance-r($rbtree:BLACK, $rlr, $rk, $rv, rbtree:recolor($rr, $rbtree:RED))
              )
            }
          )
        }
      )
    ) else if(rbtree:color($r) eq $rbtree:RED) then (
      $r(
        function($rc) { error() },
        function($rc, $rl, $rk, $rv, $rr) {
          if(rbtree:color($rl) eq $rbtree:RED) then (
            $rl(
              function($rlc) { error() },
              function($rlc, $rll, $rlk, $rlv, $rlr) {
                rbtree:branch(
                  rbtree:prev($c),
                  rbtree:branch($rbtree:BLACK, $l, $k, $v, $rll),
                  $rlk, $rlv,
                  rbtree:branch($rbtree:BLACK, $rlr, $rk, $rv, $rr)
                )
              }
            )
          ) else if(rbtree:color($rr) eq $rbtree:RED) then (
            rbtree:branch(
              rbtree:prev($c),
              rbtree:branch($rbtree:BLACK, $l, $k, $v, $rl),
              $rk, $rv,
              rbtree:recolor($rr, $rbtree:BLACK)
            )
          ) else (
            rbtree:branch($c, $l, $k, $v, $r)
          )
        }
      )
    ) else (
      rbtree:branch($c, $l, $k, $v, $r)
    )
  ) else (
    rbtree:branch($c, $l, $k, $v, $r)
  )
};

declare %private function rbtree:leaf() {
  function($leaf, $branch) {
    $leaf($rbtree:BLACK)
  }
};

declare %private function rbtree:leaf($c) {
  function($leaf, $branch) {
    $leaf($c)
  }
};

declare %private function rbtree:branch($c, $l, $k, $v, $r) {
  function($leaf, $branch) {
    $branch($c, $l, $k, $v, $r)
  }
};

declare %private function rbtree:color($tree) {
  $tree(
    function($c) { $c },
    function($c, $l, $k, $v, $r) { $c }
  )
};

declare %private function rbtree:prev($c) {
  switch($c)
    case $rbtree:DBL_BLACK return $rbtree:BLACK
    case $rbtree:BLACK     return $rbtree:RED
    case $rbtree:RED       return $rbtree:DBL_RED
    default return error()
};

declare %private function rbtree:next($c) {
  switch($c)
    case $rbtree:DBL_RED return $rbtree:RED
    case $rbtree:RED     return $rbtree:BLACK
    case $rbtree:BLACK   return $rbtree:DBL_BLACK
    default return error()
};

declare %private function rbtree:recolor($tree, $col) {
  $tree(
    function($c) {
      if($c eq $col) then $tree
      else rbtree:leaf($col)
    },
    function($c, $l, $k, $v, $r) {
      if($c eq $col) then $tree
      else rbtree:branch($col, $l, $k, $v, $r)
    }
  )
};

declare %public function rbtree:check($lt, $tree, $min, $max, $msg) {
  $tree(
    function($c) { 0 },
    function($c, $l, $k, $v, $r) {
      if(not($lt($min, $k))) then (
        error(xs:QName('rbtree:CHCK0001'), $msg)
      ) else if(not($lt($k, $max))) then (
        error(xs:QName('rbtree:CHCK0002'), $msg)
      ) else if($c eq $rbtree:RED and rbtree:color($l) eq $rbtree:RED) then (
        error(xs:QName('rbtree:CHCK0003'), $msg)
      ) else if($c eq $rbtree:RED and rbtree:color($r) eq $rbtree:RED) then (
        error(xs:QName('rbtree:CHCK0004'), $msg)
      ) else if($c = ($rbtree:DBL_RED, $rbtree:DBL_BLACK)) then (
        error(xs:QName('rbtree:CHCK0005'), $msg)
      ) else (
        let $h1 := rbtree:check($lt, $l, $min, $k, $msg),
            $h2 := rbtree:check($lt, $r, $k, $max, $msg)
        return if($h1 ne $h2) then (
          error(xs:QName('rbtree:CHCK0006'), $msg)
        ) else if($c eq $rbtree:RED) then $h1 else $h1 + 1
      )
    }
  )
};

declare %public function rbtree:to-xml($tree) {
  $tree(
    function($c) {
      element {
        if($c eq $rbtree:DBL_RED) then 'RR'
        else if($c eq $rbtree:RED) then 'R'
        else if($c eq $rbtree:BLACK) then 'B'
        else 'BB'
      } {}
    },
    function($c, $l, $k, $v, $r) {
      element {
        if($c eq $rbtree:DBL_RED) then 'RR'
        else if($c eq $rbtree:RED) then 'R'
        else if($c eq $rbtree:BLACK) then 'B'
        else 'BB'
      } {
        rbtree:to-xml($l),
        <entry key='{$k}' value='{$v}'/>,
        rbtree:to-xml($r)
      }
    }
  )
};

declare %public function rbtree:fold($node, $acc1, $f) {
  $node(
    function($_) { $acc1 },
    function($_, $l, $k, $v, $r) {
      let $acc2 := rbtree:fold($l, $acc1, $f),
          $acc3 := $f($acc2, $k, $v),
          $acc4 := rbtree:fold($r, $acc3, $f)
      return $acc4
    }
  )
};

