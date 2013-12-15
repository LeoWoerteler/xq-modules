xquery version "3.0";

(:~
 : Implementation of an ordered map based on a Red-Black Tree.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace rbtree = 'http://www.woerteler.de/xquery/modules/ordered-map/rbtree';

import module namespace pair = 'http://www.woerteler.de/xquery/modules/pair'
  at '../pair.xqm';

(:~
 : The empty Red-Black Tree, which is a black leaf.
 : @return the empty tree
 :)
declare %public function rbtree:empty() {
  rbtree:leaf()
};

(:~
 : Searches for the given key in the given Red-Black Tree.
 :
 : @param $lt less-than predicate
 : @param $tree Red-Black Tree
 : @param $x key to look for
 : @param $found callback taking the bound value when the key was found
 : @param zero-argument callback that is called when the key was not found
 : @return result of the callback
 :)
declare %public function rbtree:lookup($lt, $tree, $x, $found, $notFound) {
  let $go :=
    function($go, $tree) {
      $tree(
        $notFound,
        function($c, $l, $k, $v, $r) {
          if($lt($x, $k)) then $go($go, $l)
          else if($lt($k, $x)) then $go($go, $r)
          else $found($v)
        }
      )
    }
  return $go($go, $tree)
};

(:~
 : Calculates the number of entries in the given Red-Black Tree.
 :
 : @param $tree Red-Black Tree
 : @return number of entries in the tree
 :)
declare %public function rbtree:size($tree) {
  rbtree:fold($tree, 0, function($size, $k, $v) { $size + 1 })
};

(:~
 : Inserts the given entry into the given Read-Black Tree.
 :
 : @param $lt less-than predicate
 : @param $root root node of the tree
 : @param $k key of the entry to insert
 : @param $v value of the entry to insert
 : @return tree where the entry was inserted
 :)
declare %public function rbtree:insert($lt, $root, $k, $v) as item()* {
  (: the root node is always black :)
  rbtree:make-black(rbtree:ins($lt, $root, $k, $v))
};

(:~
 : Recursively inserts the given entry into the given tree node.
 :
 : @param $lt less-than predicate
 : @param $tree tree node
 : @param $x key of the entry to insert
 : @param $y value of the entry to insert
 : @return node where the entry was inserted
 :)
declare %private function rbtree:ins($lt, $tree, $x, $y) {
  $tree(
    function() {
      rbtree:red-branch(rbtree:leaf(), $x, $y, rbtree:leaf())
    },
    function($c, $l, $k, $v, $r) {
      if($lt($x, $k)) then (
        let $l2 := rbtree:ins($lt, $l, $x, $y)
        return if($c) then head(rbtree:balance-left(false(), $l2, $k, $v, $r))
        else rbtree:red-branch($l2, $k, $v, $r)
      ) else if($lt($k, $x)) then (
        let $r2 := rbtree:ins($lt, $r, $x, $y)
        return if($c) then head(rbtree:balance-right(false(), $l, $k, $v, $r2))
        else rbtree:red-branch($l, $k, $v, $r2)
      ) else (: $k eq $x :) (
        rbtree:branch($c, $l, $x, $y, $r)
      )
    }
  )
};

(:~
 : Deletes the given key from the given Red-Black Tree.
 :
 : @param $lt less-than predicate
 : @param $root root node of the tree
 : @param $k key to delete
 : @return tree where the entry of <code>$k</code> was deleted
 :)
declare %public function rbtree:delete($lt, $root, $k) {
  let $res := rbtree:del($lt, $root, $k)
  return if(empty($res)) then $root
  else rbtree:make-black($res[1])
};

(:~
 : Recursively deletes the given key from the given tree node.
 :
 : @param $lt less-than predicate
 : @param $tree tree node
 : @param $x key to delete
 : @return node where the key was deleted
 :         and a boolean indicating if it is double-black
:)
declare %private function rbtree:del($lt, $tree, $x) {
  $tree(
    function() { () },
    function($c, $l, $k, $v, $r) {
      if($lt($x, $k)) then (
        let $res := rbtree:del($lt, $l, $x),
            $l2  := $res[1],
            $bb  := $res[2]
        return if(empty($res)) then ()
        else if($bb) then rbtree:bubble-left($c, $l2, $k, $v, $r)
        else (rbtree:branch($c, $l2, $k, $v, $r), false())
      ) else if($lt($k, $x)) then (
        let $res := rbtree:del($lt, $r, $x),
            $r2  := $res[1],
            $bb  := $res[2]
        return if(empty($res)) then ()
        else if($bb) then rbtree:bubble-right($c, $l, $k, $v, $r2)
        else (rbtree:branch($c, $l, $k, $v, $r2), false())
      ) else (
        $l(
          function() {
            $r(
              function() { rbtree:leaf(), $c },
              function($rc, $rl, $rk, $rv, $rr) {
                rbtree:black-branch($rl, $rk, $rv, $rr),
                false()
              }
            )
          },
          function($lc, $ll, $lk, $lv, $lr) {
            $r(
              function() {
                rbtree:black-branch($ll, $lk, $lv, $lr),
                false()
              },
              function($rc, $rl, $rk, $rv, $rr) {
                let $res := rbtree:split-leftmost($rc, $rl, $rk, $rv, $rr),
                    $kv  := $res[1],
                    $r2  := $res[2],
                    $bb  := $res[3]
                return pair:deconstruct(
                  $kv,
                  function($k2, $v2) {
                    if($bb) then rbtree:bubble-right($c, $l, $k2, $v2, $r2)
                    else (rbtree:branch($c, $l, $k2, $v2, $r2), false())
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

(:~
 : Finds the leftmost (smallest) entry in the given tree and returns it
 : and the tree where the entry was deleted.
 :
 : @param $c color of the root node
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return three-element sequence containing the removed entry as a pair,
 :         the tree with the entry deleted and a boolean indicating
 :         if it is double-black
 :)
declare %private function rbtree:split-leftmost($c, $l, $k, $v, $r) {
  $l(
    function() {
      pair:new($k, $v), 
      $r(
        function() { rbtree:leaf(), $c },
        function($rc, $rl, $rk, $rv, $rr) {
          rbtree:black-branch($rl, $rk, $rv, $rr),
          false()
        }
      )
    },
    function($lc, $ll, $lk, $lv, $lr) {
      let $res := rbtree:split-leftmost($lc, $ll, $lk, $lv, $lr),
          $kv  := $res[1],
          $l2  := $res[2],
          $bb  := $res[3]
      return if($bb) then ($kv, rbtree:bubble-left($c, $l2, $k, $v, $r))
      else ($kv, rbtree:branch($c, $l2, $k, $v, $r), false())
    }
  )
};

(:~
 : Propagates a double black node color upwards in the tree.
 :
 : @param $c boolean indicating if the root node is black
 : @param $bbl double-black left child
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right child
 : @return pair of the reconstructed tree and a boolean indicating if it is double-black
 :)
declare %private function rbtree:bubble-left($c, $bbl, $k, $v, $r) {
  $r(
    error#0,
    function($rc, $rl, $rk, $rv, $rr) {
      if($rc) then (
        rbtree:balance-right($c, $bbl, $k, $v, rbtree:red-branch($rl, $rk, $rv, $rr))
      ) else $rl(
        error#0,
        function($rlc, $rll, $rlk, $rlv, $rlr) {
          rbtree:black-branch(
            rbtree:black-branch($bbl, $k, $v, $rll),
            $rlk, $rlv,
            head(rbtree:balance-right(false(), $rlr, $rk, $rv, rbtree:make-red($rr)))
          ),
          false()
        }
      )
    }
  )
};

(:~
 : Propagates a double black node color upwards in the tree.
 :
 : @param $c boolean indicating if the root node is black
 : @param $l left child
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $bbr double-black right child
 : @return pair of the reconstructed tree and a boolean indicating if it is double-black
 :)
declare %private function rbtree:bubble-right($c, $l, $k, $v, $bbr) {
  $l(
    error#0,
    function($lc, $ll, $lk, $lv, $lr) {
      if($lc) then (
        rbtree:balance-left($c, rbtree:red-branch($ll, $lk, $lv, $lr), $k, $v, $bbr)
      ) else $lr(
        error#0,
        function($lrc, $lrl, $lrk, $lrv, $lrr) {
          rbtree:black-branch(
            head(rbtree:balance-left(false(), rbtree:make-red($ll), $lk, $lv, $lrl)),
            $lrk, $lrv,
            rbtree:black-branch($lrr, $k, $v, $bbr)
          )
        }
      )
    }
  )
};

(:~
 : Rebalances the given node after a modification in the left sub-tree.
 :
 : @param $bb flag indicating if the root node is double-black
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return rebalanced tree and a boolean indicating if it is double-black
 :)
declare %private function rbtree:balance-left($bb, $l, $k, $v, $r) {
  $l(
    function() { rbtree:black-branch($l, $k, $v, $r), $bb },
    function($lc, $ll, $lk, $lv, $lr) {
      if($lc) then (rbtree:black-branch($l, $k, $v, $r), $bb)
      else (
        let $check-lr :=
          function() {
            $lr(
              function() { rbtree:black-branch($l, $k, $v, $r), $bb },
              function($lrc, $lrl, $lrk, $lrv, $lrr) {
                if($lrc) then (rbtree:black-branch($l, $k, $v, $r), $bb)
                else (
                  rbtree:branch(
                    $bb,
                    rbtree:black-branch($ll, $lk, $lv, $lrl),
                    $lrk, $lrv,
                    rbtree:black-branch($lrr, $k, $v, $r)
                  ),
                  false()
                )
              }
            )
          }
        return $ll(
          $check-lr,
          function($llc, $lll, $llk, $llv, $llr) {
            if($llc) then $check-lr()
            else (
              rbtree:branch(
                $bb,
                rbtree:black-branch($lll, $llk, $llv, $llr),
                $lk, $lv,
                rbtree:black-branch($lr, $k, $v, $r)
              ),
              false()
            )
          }
        )
      )
    }
  )
};

(:~
 : Rebalances the given node after a modification in the right sub-tree.
 :
 : @param $bb flag indicating if the root node is double-black
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return rebalanced tree and a boolean indicating if it is double-black
 :)
declare %private function rbtree:balance-right($bb, $l, $k, $v, $r) {
  $r(
    function() { rbtree:black-branch($l, $k, $v, $r), $bb },
    function($rc, $rl, $rk, $rv, $rr) {
      if($rc) then (rbtree:black-branch($l, $k, $v, $r), $bb)
      else (
        let $check-rl :=
          function() {
            $rl(
              function() { rbtree:black-branch($l, $k, $v, $r), $bb },
              function($rlc, $rll, $rlk, $rlv, $rlr) {
                if($rlc) then (rbtree:black-branch($l, $k, $v, $r), $bb)
                else (
                  rbtree:branch(
                    $bb,
                    rbtree:black-branch($l, $k, $v, $rll),
                    $rlk, $rlv,
                    rbtree:black-branch($rlr, $rk, $rv, $rr)
                  ),
                  false()
                )
              }
            )
          }
        return $rr(
          $check-rl,
          function($rrc, $rrl, $rrk, $rrv, $rrr) {
            if($rrc) then $check-rl()
            else (
              rbtree:branch(
                $bb,
                rbtree:black-branch($l, $k, $v, $rl),
                $rk, $rv,
                rbtree:black-branch($rrl, $rrk, $rrv, $rrr)
              ),
              false()
            )
          }
        )
      )
    }
  )
};

(:~
 : Creates a leaf node.
 :
 : @return leaf node
 :)
declare %private function rbtree:leaf() {
  function($leaf, $branch) {
    $leaf()
  }
};

(:~
 : Creates a branch node.
 :
 : @param $c color of the branch node
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return branch node
 :)
declare %private function rbtree:branch($c, $l, $k, $v, $r) {
  function($leaf, $branch) {
    $branch($c, $l, $k, $v, $r)
  }
};

(:~
 : Returns the color of the given node.
 :
 : @param $tree node to find the color of
 : @return the node's color
 :)
declare %private function rbtree:is-red($tree) {
  $tree(
    function() { false() },
    function($c, $l, $k, $v, $r) { not($c) }
  )
};

(:~
 : Creates a red branch node.
 :
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return branch node
 :)
declare %private function rbtree:red-branch($l, $k, $v, $r) {
  rbtree:branch(fn:false(), $l, $k, $v, $r)
};

(:~
 : Creates a black branch node.
 :
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return branch node
 :)
declare %private function rbtree:black-branch($l, $k, $v, $r) {
  rbtree:branch(fn:true(), $l, $k, $v, $r)
};

(:~
 : Returns an instance of the given node that is red.
 :
 : @param $tree tree to create a red version of
 : @return red version of <code>$tree</code>
 :)
declare %private function rbtree:make-red($tree) {
  $tree(
    error#0,
    function($c, $l, $k, $v, $r) {
      if($c) then rbtree:red-branch($l, $k, $v, $r)
      else $tree
    }
  )
};

(:~
 : Returns an instance of the given node that is black.
 :
 : @param $tree tree to create a black version of
 : @return black version of <code>$tree</code>
 :)
declare %private function rbtree:make-black($tree) {
  $tree(
    function() { $tree },
    function($c, $l, $k, $v, $r) {
      if($c) then $tree
      else rbtree:black-branch($l, $k, $v, $r)
    }
  )
};


(:~
 : Checks the given tree node for invariant violations.
 :
 : @param $lt less-than predicate
 : @param $tree current node
 : @param $min key that is smaller than all keys in <code>$tree</code>
 : @param $max key that is greater than all keys in <code>$tree</code>
 : @param $msg error message to show when an invariant is violated
 : @return black height of the tree
 : @error rbtree:CHCK0001 if a key is smaller than <code>$min</code>
 : @error rbtree:CHCK0002 if a key is greater than <code>$max</code>
 : @error rbtree:CHCK0003 if a red node has a red child
 : @error rbtree:CHCK0004 if the two sub-trees have different black heights
 :)
declare %public function rbtree:check($lt, $tree, $min, $max, $msg) {
  $tree(
    function() { 0 },
    function($c, $l, $k, $v, $r) {
      if(not($lt($min, $k))) then (
        error(xs:QName('rbtree:CHCK0001'), $msg)
      ) else if(not($lt($k, $max))) then (
        error(xs:QName('rbtree:CHCK0002'), $msg)
      ) else if(not($c) and rbtree:is-red($l)) then (
        error(xs:QName('rbtree:CHCK0003'), $msg)
      ) else if(not($c) and rbtree:is-red($r)) then (
        error(xs:QName('rbtree:CHCK0003'), $msg)
      ) else (
        let $h1 := rbtree:check($lt, $l, $min, $k, $msg),
            $h2 := rbtree:check($lt, $r, $k, $max, $msg)
        return if($h1 ne $h2) then (
          error(xs:QName('rbtree:CHCK0004'), $msg)
        ) else if($c) then $h1 + 1 else $h1
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
declare %public function rbtree:to-xml($tree) {
  $tree(
    function() { <L/> },
    function($c, $l, $k, $v, $r) {
      element { if($c) then 'B' else 'R' } {
        rbtree:to-xml($l),
        <E key='{$k}'>{$v}</E>,
        rbtree:to-xml($r)
      }
    }
  )
};

(:~
 : Folds all entries of the given tree into one value in ascending order.
 :
 : @param $node current tree node
 : @param $acc1 accumulator
 : @param $f combining function
 : @return folded value
 :)
declare %public function rbtree:fold($node, $acc1, $f) {
  $node(
    function() { $acc1 },
    function($_, $l, $k, $v, $r) {
      let $acc2 := rbtree:fold($l, $acc1, $f),
          $acc3 := $f($acc2, $k, $v),
          $acc4 := rbtree:fold($r, $acc3, $f)
      return $acc4
    }
  )
};
