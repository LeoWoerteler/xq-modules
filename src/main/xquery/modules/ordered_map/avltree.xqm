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
 : Finds the given key in the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $x key to look for
 : @param $found callback taking the bound value when the key was found
 : @param $notFound zero-argument callback for when the key was not found
 : @return result of the callback
 :)
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

(:~
 : Calculates the number of entries in the given AVL Tree.
 :
 : @param $tree AVL Tree
 : @return number of entries in the tree
 :)
declare %public function avltree:size($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) {
      avltree:size($l) + 1 + avltree:size($r)
    }
  )
};

(:~
 : Inserts the given entry into the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $k key of the entry to insert
 : @param $v value of the entry to insert
 : @return tree where the entry was inserted
 :)
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

(:~
 : Deletes the given key from the given AVL Tree.
 :
 : @param $lt less-than predicate
 : @param $tree AVL Tree
 : @param $k key to delete
 : @return tree where the entry of <code>$x</code> was deleted
 :)
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

(:~
 : Returns an XML representation of the given tree's inner structure.
 :
 : @param $tree tree to show the structure of
 : @return the tree's structure
 :)
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

(:~
 : Folds all entries of the given tree into one value in ascending order.
 :
 : @param $node current tree node
 : @param $acc1 accumulator
 : @param $f combining function
 : @return folded value
 :)
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

(:~
 : Creates a branch node.
 :
 : @param $left left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $right right sub-tree
 : @return branch node
 :)
declare %private function avltree:branch($left, $k, $v, $right) {
  let $h := max((avltree:height($left), avltree:height($right))) + 1
  return function($empty, $branch) {
    $branch($left, $h, $k, $v, $right)
  }
};

(:~
 : Returns the height of the given node.
 :
 : @param $tree node
 : @return the node's height
 :)
declare %private function avltree:height($tree) {
  $tree(
    function() { 0 },
    function($l, $h, $k, $v, $r) { $h }
  )
};

(:~
 : Finds the leftmost (smallest) entry in the given tree and returns it
 : and the tree where the entry was deleted.
 :
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return two-element sequence containing the removed entry as a pair
 :         and the tree with the entry deleted
 :)
declare %private function avltree:split-leftmost($l, $k, $v, $r) {
  $l(
    function() { (pair:new($k, $v), $r) },
    function($ll, $lh, $lk, $lv, $lr) {
      let $res := avltree:split-leftmost($ll, $lk, $lv, $lr)
      return ($res[1], avltree:re-balance($res[2], $k, $v, $r))
    }
  )
};

(:~
 : Returns the balance (between -2 and 2) between the two given sub-trees.
 :
 : @param $left left sub-tree
 : @param $right right sub-tree
 : @return the balance, i.e. the difference between the left and right height
 :)
declare %private function avltree:balance($left, $right) {
  avltree:height($right) - avltree:height($left)
};

(:~
 : Rebalances the given branch node.
 :
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return balanced branch node
 :)
declare %private function avltree:re-balance($l, $k, $v, $r) {
  switch(avltree:balance($l, $r))
    case  2 return avltree:rotate-left($l, $k, $v, $r)
    case -2 return avltree:rotate-right($l, $k, $v, $r)
    default return avltree:branch($l, $k, $v, $r)
};

(:~
 : Rotates the given branch node to the left.
 :
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return rotated branch node
 :)
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

(:~
 : Rotates the given branch node to the right.
 :
 : @param $l left sub-tree
 : @param $k key of the branch node
 : @param $v value of the branch node
 : @param $r right sub-tree
 : @return rotated branch node
 :)
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
