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

(:~
 : Returns the empty AVL Tree.
 :
 : @return empty tree
 :)
declare %public function avltree:empty() {
  function($empty, $branch) {
    $empty()
  }
};

(:~
 : Creates a branch node.
 :
 : @param $left left sub-tree
 : @param $b balance of the branch node
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $right right sub-tree
 : @return branch node
 :)
declare %private function avltree:branch($left, $b, $k, $v, $right) {
  function($empty, $branch) {
    $branch($left, $b, $k, $v, $right)
  }
};

(:~
 : Finds the given key in the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $x key to look for
 : @param $found callback taking the bound value when the key was found
 : @param $not-found zero-argument callback for when the key was not found
 : @return result of the callback
 :)
declare %public function avltree:lookup($lt, $tree, $x, $found, $not-found) {
  let $go :=
    function($go, $node) {
      $node(
        $not-found,
        function($l, $_, $k, $v, $r) {
          if($lt($x, $k)) then $go($go, $l)
          else if($lt($k, $x)) then $go($go, $r)
          else $found($v)
        }
      )
    }
  return $go($go, $tree)
};

(:~
 : Inserts the given entry into the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $k key of the entry to insert
 : @param $v value of the entry to insert
 : @return tree where the entry was inserted
           and the amount of its height increase
 :)
declare %public function avltree:insert($lt, $tree, $k, $v) {
  avltree:ins($lt, $tree, $k, $v)[1]
};

(:~
 : Recursively inserts the given entry into the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree tree to insert into
 : @param $k key to insert
 : @param $y vlue to insert
 : @return two-element sequence of the tree where the entry was inserted
           and a boolean indicating if the tree's height changed
 :)
declare %private function avltree:ins($lt, $tree, $x, $y) {
  $tree(
    function() {
      avltree:branch(avltree:empty(), 0, $x, $y, avltree:empty()),
      true()
    },
    function($l, $b, $k, $v, $r) {
      if($lt($x, $k)) then (
        let $res := avltree:ins($lt, $l, $x, $y)
        return if($res[2]) then avltree:balance-left($res[1], $b, $k, $v, $r)
        else (avltree:branch($res[1], $b, $k, $v, $r), false())
      ) else if($lt($k, $x)) then (
        let $res := avltree:ins($lt, $r, $x, $y)
        return if($res[2]) then avltree:balance-right($l, $b, $k, $v, $res[1])
        else (avltree:branch($l, $b, $k, $v, $res[1]), false())
      ) else (
        avltree:branch($l, $b, $x, $y, $r),
        false()
      )
    }
  )
};

(:~
 : Deletes the given key from the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $k key to delete
 : @return tree where the entry of <code>$x</code> was deleted
 :)
declare %public function avltree:delete($lt, $tree, $x) {
  let $res := avltree:del($lt, $tree, $x)
  return if(empty($res)) then $tree else $res[1]
};

(:~
 : Recursively deletes the entry with the given key from the given Red-Black Tree.
 :
 : @param $lt less-than predicate
 : @param $tree tree to delete from
 : @param $x key to delete
 : @return an empty sequence if the tree does not contain the key,
 :         the tree where the key was deleted
 :         and a boolean indicating if the height changed otherwise
 :)
declare %private function avltree:del($lt, $tree, $x) {
  $tree(
    function() { () },
    function($l, $b, $k, $v, $r) {
      if($lt($x, $k)) then (
        let $res := avltree:del($lt, $l, $x)
        return if(empty($res)) then ()
        else if($res[2]) then (
          let $res2 := avltree:balance-right($res[1], $b, $k, $v, $r)
          return ($res2[1], not($res2[2]))
        ) else (
          avltree:branch($res[1], $b, $k, $v, $r),
          false()
        )
      ) else if($lt($k, $x)) then (
        let $res := avltree:del($lt, $r, $x)
        return if(empty($res)) then ()
        else if($res[2]) then (
          let $res2 := avltree:balance-left($l, $b, $k, $v, $res[1])
          return ($res2[1], not($res2[2]))
        ) else (
          avltree:branch($l, $b, $k, $v, $res[1]),
          false()
        )
      ) else (
        $r(
          function() { $l, true() },
          function($rl, $rb, $rk, $rv, $rr) {
            let $res := avltree:split-leftmost($rl, $rb, $rk, $rv, $rr)
            return pair:deconstruct(
              $res[1],
              function($k2, $v2) {
                if($res[3]) then (
                  let $res2 := avltree:balance-left($l, $b, $k2, $v2, $res[2])
                  return ($res2[1], not($res2[2]))
                ) else (
                  avltree:branch($l, $b, $k2, $v2, $res[2]),
                  false()
                )
              }
            )
          }
        )
      )
    }
  )
};

(:~
 : Deletes the leftmost (smallest) entry from the given tree and returns it
 : together with the tree where it is removed.
 :
 : @param $l left sub-tree
 : @param $b balance of the root node
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return three-element sequence vontaining a pair of the key and value of the removed entry,
           the tree where it was removed and a boolean indicating if its height changed
 :)
declare %private function avltree:split-leftmost($l, $b, $k, $v, $r) {
  $l(
    function() { pair:new($k, $v), $r, true() },
    function($ll, $lb, $lk, $lv, $lr) {
      let $res := avltree:split-leftmost($ll, $lb, $lk, $lv, $lr)
      return (
        $res[1],
        if($res[3]) then (
          let $res2 := avltree:balance-right($res[2], $b, $k, $v, $r)
          return ($res2[1], not($res2[2]))
        ) else (
          avltree:branch($res[2], $b, $k, $v, $r),
          false()
        )
      )
    }
  )
};

(:~
 : Rebalances the given tree after its balance value decreased.
 :
 : @param $l left sub-tree
 : @param $b old balance
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return the balanced tree and a boolean indicating if the height increased
 :)
declare %private function avltree:balance-left($l, $b, $k, $v, $r) {
  if($b eq -1) then (
    $l(
      error#0,
      function($ll, $lb, $lk, $lv, $lr) {
        if($lb le 0) then (
          avltree:branch(
            $ll,
            $lb + 1,
            $lk, $lv,
            avltree:branch($lr, -$lb - 1, $k, $v, $r)
          )
        ) else $lr(
          error#0,
          function($lrl, $lrb, $lrk, $lrv, $lrr) {
            avltree:branch(
              avltree:branch($ll, min((-$lrb, 0)), $lk, $lv, $lrl),
              0,
              $lrk, $lrv,
              avltree:branch($lrr, max((-$lrb, 0)), $k, $v, $r)
            )
          }
        ),
        $lb eq 0
      }
    )
  ) else (
    avltree:branch($l, $b - 1, $k, $v, $r),
    $b eq 0
  )
};

(:~
 : Rebalances the given tree after its balance value increased.
 :
 : @param $l left sub-tree
 : @param $b old balance
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return the balanced tree and a boolean indicating if the height increased
 :)
declare %private function avltree:balance-right($l, $b, $k, $v, $r) {
  if($b eq 1) then (
    $r(
      error#0,
      function($rl, $rb, $rk, $rv, $rr) {
        if($rb ge 0) then (
          avltree:branch(
            avltree:branch($l, -$rb + 1, $k, $v, $rl),
            $rb - 1,
            $rk, $rv,
            $rr
          )
        ) else $rl(
          error#0,
          function($rll, $rlb, $rlk, $rlv, $rlr) {
            avltree:branch(
              avltree:branch($l, min((-$rlb, 0)), $k, $v, $rll),
              0,
              $rlk, $rlv,
              avltree:branch($rlr, max((-$rlb, 0)), $rk, $rv, $rr)
            )
          }
        ),
        $rb eq 0
      }
    )
  ) else (
    avltree:branch($l, $b + 1, $k, $v, $r),
    $b eq 0
  )
};

(:~
 : Folds all entries of the given tree into one value in ascending order.
 :
 : @param $root root of the tree to fold
 : @param $acc accumulator
 : @param $f combining function
 : @return folded value
 :)
declare %public function avltree:fold($root, $acc, $f) {
  let $go :=
    function($go, $acc1, $tree) {
      $tree(
        function() { $acc1 },
        function($l, $_, $k, $v, $r) {
          let $acc2 := $go($go, $acc1, $l),
              $acc3 := $f($acc2, $k, $v),
              $acc4 := $go($go, $acc3, $r)
          return $acc4
        }
      )
    }
  return $go($go, $acc, $root)
};

(:~
 : Checks the given tree node for invariant violations.
 :
 : @param $lt less-than predicate
 : @param $tree current node
 : @param $min key that is smaller than all keys in <code>$tree</code>
 : @param $max key that is greater than all keys in <code>$tree</code>
 : @param $msg error message to show when an invariant is violated
 : @return empty sequence
 : @error rbtree:AVLT0001 if a key is smaller than <code>$min</code>
 : @error rbtree:AVLT0002 if a key is greater than <code>$max</code>
 : @error rbtree:AVLT0003 if the AVL Tree is unbalanced
 :)
declare %public function avltree:check($lt, $tree, $min, $max, $msg) {
  $tree(
    function() { 0 },
    function($l, $b, $k, $v, $r) {
      if(not($lt($min, $k))) then (
        error(xs:QName('avltree:AVLT0001'), $msg)
      ) else if(not($lt($k, $max))) then (
        error(xs:QName('avltree:AVLT0002'), $msg)
      ) else if(not($b = (-1, 0, 1))) then (
        error(xs:QName('avltree:AVLT0003'), $msg)
      ) else (
        let $h1 := avltree:check($lt, $l, $min, $k, $msg),
            $h2 := avltree:check($lt, $r, $k, $max, $msg)
        return if(($h2 - $h1) ne $b) then (
          error(xs:QName('avltree:AVLT0004'), $msg)
        ) else (
          max(($h1, $h2)) + 1
        )
      )
    }
  )
};

(:~
 : Returns an XML representation of the given tree's inner structure.
 :
 : @param $tree tree to show the structure of
 : @return the tree's structure
 :)
declare function avltree:to-xml($tree) {
  $tree(
    function() { <_/> },
    function($l, $b, $k, $v, $r) {
      element { exactly-one(('L', 'B', 'R')[$b + 2]) } {
        avltree:to-xml($l),
        <E key="{$k}">{$v}</E>,
        avltree:to-xml($r)
      }
    }
  )
};
