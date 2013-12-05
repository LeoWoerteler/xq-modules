xquery version "3.0";

(:~
 : Implementation of an ordered map based on an AVL Tree.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace avltree = 'http://www.woerteler.de/xquery/modules/ordered-map/avltree';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
  at '../pair.xqm';

declare %public function avltree:empty() {
  function($empty, $branch) {
    $empty()
  }
};

declare %public function avltree:lookup($lt, $tree, $x, $found, $notFound) {
  $tree(
    function() { $notFound() },
    function($l, $_, $k, $v, $r) {
      if($lt($x, $k)) then avltree:lookup($lt, $l, $x, $found, $notFound)
      else if($lt($k, $x)) then avltree:lookup($lt, $r, $x, $found, $notFound)
      else $found($v)
    }
  )
};

declare %public function avltree:size($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) {
      avltree:size($l) + 1 + avltree:size($r)
    }
  )
};

declare %public function avltree:insert($lt, $tree, $x, $y) {
  $tree(
    function() { avltree:branch(avltree:empty(), $x, $y, avltree:empty()) },
    function($l, $h, $k, $v, $r) {
      if($lt($x, $k)) then
        avltree:re-balance(avltree:insert($lt, $l, $x, $y), $k, $v, $r)
      else if($lt($k, $x)) then
        avltree:re-balance($l, $k, $v, avltree:insert($lt, $r, $x, $y))
      else
        avltree:branch($l, $x, $y, $r)
    }
  )
};

declare %public function avltree:delete($lt, $tree, $x) {
  $tree(
    function() { $tree },
    function($l, $h, $k, $v, $r) {
      if($lt($x, $k)) then
        avltree:re-balance(avltree:delete($lt, $l, $x), $k, $v, $r)
      else if($lt($k, $x)) then
        avltree:re-balance($l, $k, $v, avltree:delete($lt, $r, $x))
      else
        $r(
          function() { $l },
          function($rl, $rh, $rk, $rv, $rr) {
            let $res := avltree:split-leftmost($rl, $rk, $rv, $rr)
            return
              pair:deconstruct(
                $res[1],
                function($k2, $v2) {
                  avltree:re-balance($l, $k2, $v2, $res[2])
                }
              )
          }
        )
    }
  )
};

declare function avltree:to-xml($tree) {
  $tree(
    function() { <N/> },
    function($l, $h, $k, $v, $r) {
      <N height="{$h}">{
        avltree:to-xml($l),
        <entry key="{$k}" value="{$v}" />,
        avltree:to-xml($r)
      }</N>
    }
  )
};

declare %public function avltree:check($lt, $tree, $min, $max, $msg) {
  $tree(
    function() { () },
    function($l, $h, $k, $v, $r) {
      if(not($lt($min, $k))) then (
        error(xs:QName('tree:AVLT0001'), $msg)
      ) else if(not($lt($k, $max))) then (
        error(xs:QName('tree:AVLT0002'), $msg)
      ) else if(abs(avltree:balance($l, $r)) > 1) then (
        error(xs:QName('tree:AVLT0003'), $msg)
      ) else (
        avltree:check($lt, $l, $min, $k, $msg),
        avltree:check($lt, $r, $k, $max, $msg)
      )
    }
  )
};

declare %public function avltree:fold($tree, $acc1, $f) {
  $tree(
    function() { $acc1 },
    function($l, $_, $k, $v, $r) {
      let $acc2 := avltree:fold($l, $acc1, $f),
          $acc3 := $f($acc2, $k, $v),
          $acc4 := avltree:fold($r, $acc3, $f)
      return $acc4
    }
  )
};

(:::::::::::::::::::::::::::: private functions ::::::::::::::::::::::::::::)

declare %private function avltree:branch($left, $k, $v, $right) {
  let $h := max((avltree:height($left), avltree:height($right))) + 1
  return function($empty, $branch) {
    $branch($left, $h, $k, $v, $right)
  }
};

declare %private function avltree:height($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) { $h }
  )
};

declare %private function avltree:split-leftmost($l, $k, $v, $r) {
  $l(
    function() { (pair:new($k, $v), $r) },
    function($ll, $lh, $lk, $lv, $lr) {
      let $res := avltree:split-leftmost($ll, $lk, $lv, $lr)
      return ($res[1], avltree:re-balance($res[2], $k, $v, $r))
    }
  )
};

declare %private function avltree:balance($left, $right) {
  avltree:height($right) - avltree:height($left)
};

declare %private function avltree:re-balance($l, $k, $v, $r) {
  switch(avltree:balance($l, $r))
    case  2 return avltree:rotate-left($l, $k, $v, $r)
    case -2 return avltree:rotate-right($l, $k, $v, $r)
    default return avltree:branch($l, $k, $v, $r)
};

declare %private function avltree:rotate-left($l, $k, $v, $r) {
  $r(
    error#0,
    function($rl, $rh, $rk, $rv, $rr) {
      if(avltree:balance($rl, $rr) >= 0)
      then avltree:branch(avltree:branch($l, $k, $v, $rl), $rk, $rv, $rr)
      else $rl(
        error#0,
        function($rll, $rlh, $rlk, $rlv, $rlr) {
          avltree:branch(
            avltree:branch($l, $k, $v, $rll),
            $rlk, $rlv,
            avltree:branch($rlr, $rk, $rv, $rr)
          )
        }
      )
    }
  )
};

declare %private function avltree:rotate-right($l, $k, $v, $r) {
  $l(
    error#0,
    function($ll, $lh, $lk, $lv, $lr) {
      if(avltree:balance($ll, $lr) <= 0)
      then avltree:branch($ll, $lk, $lv, avltree:branch($lr, $k, $v, $r))
      else $lr(
        error#0,
        function($lrl, $lrh, $lrk, $lrv, $lrr) {
          avltree:branch(
            avltree:branch($ll, $lk, $lv, $lrl),
            $lrk, $lrv,
            avltree:branch($lrr, $k, $v, $r)
          )
        }
      )
    }
  )
};
