
module namespace tree="http://www.basex.org/modules/ordered-map/avltree";

import module namespace pair = 'http://www.basex.org/modules/pair'
  at '../pair.xqm';

declare %public function tree:empty() {
  function($empty, $branch) {
    $empty()
  }
};

declare %public function tree:lookup($lt, $tree, $x, $found, $notFound) {
  $tree(
    function() { $notFound() },
    function($l, $_, $k, $v, $r) {
      if($lt($x, $k)) then tree:lookup($lt, $l, $x, $found, $notFound)
      else if($lt($k, $x)) then tree:lookup($lt, $r, $x, $found, $notFound)
      else $found($v)
    }
  )
};

declare %public function tree:size($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) {
      tree:size($l) + 1 + tree:size($r)
    }
  )
};

declare %public function tree:insert($lt, $tree, $x, $y) {
  $tree(
    function() { tree:branch(tree:empty(), $x, $y, tree:empty()) },
    function($l, $h, $k, $v, $r) {
      if($lt($x, $k))      then tree:re-balance(tree:insert($lt, $l, $x, $y), $k, $v, $r)
      else if($lt($k, $x)) then tree:re-balance($l, $k, $v, tree:insert($lt, $r, $x, $y))
      else tree:branch($l, $x, $y, $r)
    }
  )
};

declare %public function tree:delete($lt, $tree, $x) {
  $tree(
    function() { $tree },
    function($l, $h, $k, $v, $r) {
      if($lt($x, $k))      then tree:re-balance(tree:delete($lt, $l, $x), $k, $v, $r)
      else if($lt($k, $x)) then tree:re-balance($l, $k, $v, tree:delete($lt, $r, $x))
      else
        $r(
          function() { $l },
          function($rl, $rh, $rk, $rv, $rr) {
            let $res := tree:split-leftmost($rl, $rk, $rv, $rr)
            return
              pair:deconstruct(
                $res[1],
                function($k2, $v2) {
                  tree:re-balance($l, $k2, $v2, $res[2])
                }
              )
          }
        )
    }
  )
};

declare function tree:to-xml($tree) {
  $tree(
    function() { <N/> },
    function($l, $h, $k, $v, $r) {
      <N height="{$h}">{
        tree:to-xml($l),
        <entry key="{$k}" value="{$v}" />,
        tree:to-xml($r)
      }</N>
    }
  )
};

declare %public function tree:check($lt, $tree, $min, $max, $msg) {
  $tree(
    function() { () },
    function($l, $h, $k, $v, $r) {
      if(not($lt($min, $k))) then (
        error(xs:QName('tree:AVLT0001'), $msg)
      ) else if(not($lt($k, $max))) then (
        error(xs:QName('tree:AVLT0002'), $msg)
      ) else if(abs(tree:balance($l, $r)) > 1) then (
        error(xs:QName('tree:AVLT0003'), $msg)
      ) else (
        tree:check($lt, $l, $min, $k, $msg),
        tree:check($lt, $r, $k, $max, $msg)
      )
    }
  )
};

declare %public function tree:fold($tree, $acc1, $f) {
  $tree(
    function() { $acc1 },
    function($l, $_, $k, $v, $r) {
      let $acc2 := tree:fold($l, $acc1, $f),
          $acc3 := $f($acc2, $k, $v),
          $acc4 := tree:fold($r, $acc3, $f)
      return $acc4
    }
  )
};

(:::::::::::::::::::::::::::::::: private functions ::::::::::::::::::::::::::::::::)

declare %private function tree:branch($left, $k, $v, $right) {
  let $h := max((tree:height($left), tree:height($right))) + 1
  return function($empty, $branch) {
    $branch($left, $h, $k, $v, $right)
  }
};

declare %private function tree:height($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) { $h }
  )
};

declare %private function tree:split-leftmost($l, $k, $v, $r) {
  $l(
    function() { (pair:new($k, $v), $r) },
    function($ll, $lh, $lk, $lv, $lr) {
      let $res := tree:split-leftmost($ll, $lk, $lv, $lr)
      return ($res[1], tree:re-balance($res[2], $k, $v, $r))
    }
  )
};

declare %private function tree:balance($left, $right) {
  tree:height($right) - tree:height($left)
};

declare %private function tree:re-balance($l, $k, $v, $r) {
  switch(tree:balance($l, $r))
    case  2 return tree:rotate-left($l, $k, $v, $r)
    case -2 return tree:rotate-right($l, $k, $v, $r)
    default return tree:branch($l, $k, $v, $r)
};

declare %private function tree:rotate-left($l, $k, $v, $r) {
  $r(
    error#0,
    function($rl, $rh, $rk, $rv, $rr) {
      if(tree:balance($rl, $rr) >= 0)
      then tree:branch(tree:branch($l, $k, $v, $rl), $rk, $rv, $rr)
      else $rl(
        error#0,
        function($rll, $rlh, $rlk, $rlv, $rlr) {
          tree:branch(
            tree:branch($l, $k, $v, $rll),
            $rlk, $rlv,
            tree:branch($rlr, $rk, $rv, $rr)
          )
        }
      )
    }
  )
};

declare %private function tree:rotate-right($l, $k, $v, $r) {
  $l(
    error#0,
    function($ll, $lh, $lk, $lv, $lr) {
      if(tree:balance($ll, $lr) <= 0)
      then tree:branch($ll, $lk, $lv, tree:branch($lr, $k, $v, $r))
      else $lr(
        error#0,
        function($lrl, $lrh, $lrk, $lrv, $lrr) {
          tree:branch(
            tree:branch($ll, $lk, $lv, $lrl),
            $lrk, $lrv,
            tree:branch($lrr, $k, $v, $r)
          )
        }
      )
    }
  )
};
