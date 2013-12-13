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

(:~ Negative-black node color, only occurs while relabancing. :)
declare %private variable $rbtree:NEG_BLACK as xs:integer := -1;
(:~ Red node color. :)
declare %private variable $rbtree:RED       as xs:integer :=  0;
(:~ Black node color. :)
declare %private variable $rbtree:BLACK     as xs:integer :=  1;
(:~ Doble-black node color, only occurs while relabancing. :)
declare %private variable $rbtree:DBL_BLACK as xs:integer :=  2;

(:~
 : The empty Red-Black Tree, which is a black leaf.
 : @return the empty tree
 :)
declare %public function rbtree:empty() {
  rbtree:leaf($rbtree:BLACK)
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
        function($c) { $notFound() },
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
  $tree(
    function($c) { 0 },
    function($c, $l, $k, $v, $r) {
      rbtree:size($l) + 1 + rbtree:size($r)
    }
  )
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
  rbtree:recolor(rbtree:ins($lt, $root, $k, $v), $rbtree:BLACK)
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
    function($c) {
      rbtree:branch(
        $rbtree:RED,
        rbtree:leaf($rbtree:BLACK),
        $x, $y,
        rbtree:leaf($rbtree:BLACK)
      )
    },
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

(:~
 : Deletes the given key from the given Red-Black Tree.
 :
 : @param $lt less-than predicate
 : @param $root root node of the tree
 : @param $k key to delete
 : @return tree where the entry of <code>$k</code> was deleted
 : @see http://matt.might.net/articles/red-black-delete/
 :)
declare %public function rbtree:delete($lt, $root, $k) {
  rbtree:recolor(rbtree:del($lt, $root, $k), $rbtree:BLACK)
};

(:~
 : Recursively deletes the given key from the given tree node.
 :
 : @param $lt less-than predicate
 : @param $tree tree node
 : @param $x key to delete
 : @return node where the key was deleted
 :)
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

(:~
 : Finds the leftmost (smallest) entry in the given tree and returns it
 : and the tree where the entry was deleted.
 :
 : @param $c color of the root node
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return two-element sequence containing the removed entry as a pair
 :         and the tree with the entry deleted
 :)
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

(:~
 : Propagates a double-black node upwards in the tree.
 :
 : @param $c color of the root node
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return tree where none of the sub-trees is double-black
 :)
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

(:~
 : Rebalances the given node after a modification in the left sub-tree.
 :
 : @param $c color of the root node
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return rebalanced tree
 :)
declare %private function rbtree:balance-l($c, $l, $k, $v, $r) {
  if($c = ($rbtree:BLACK, $rbtree:DBL_BLACK)) then (
    if($c eq $rbtree:DBL_BLACK and rbtree:color($l) eq $rbtree:NEG_BLACK) then (
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

(:~
 : Rebalances the given node after a modification in the right sub-tree.
 :
 : @param $c color of the root node
 : @param $l left sub-tree
 : @param $k key of the root node
 : @param $v value of the root node
 : @param $r right sub-tree
 : @return rebalanced tree
 :)
declare %private function rbtree:balance-r($c, $l, $k, $v, $r) {
  if($c = ($rbtree:BLACK, $rbtree:DBL_BLACK)) then (
    if($c eq $rbtree:DBL_BLACK and rbtree:color($r) eq $rbtree:NEG_BLACK) then (
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

(:~
 : Creates a leaf node with the given color.
 :
 : @param $c color of the leaf node
 : @return leaf node with the given color
 :)
declare %private function rbtree:leaf($c) {
  function($leaf, $branch) {
    $leaf($c)
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
declare %private function rbtree:color($tree) {
  $tree(
    function($c) { $c },
    function($c, $l, $k, $v, $r) { $c }
  )
};

(:~
 : Subtracts one black unit from the given node color.
 :
 : @param $c initial color
 : @return previous color
 :)
declare %private function rbtree:prev($c) {
  switch($c)
    case $rbtree:DBL_BLACK return $rbtree:BLACK
    case $rbtree:BLACK     return $rbtree:RED
    default                return $rbtree:NEG_BLACK
};

(:~
 : Adds one black unit to the given node color.
 :
 : @param $c initial color
 : @return next color
 :)
declare %private function rbtree:next($c) {
  switch($c)
    case $rbtree:NEG_BLACK return $rbtree:RED
    case $rbtree:RED       return $rbtree:BLACK
    default                return $rbtree:DBL_BLACK
};

(:~
 : Returns a recolored version of the given node.
 :
 : @param $tree node to recolor
 : @param $col new color of the node
 : @return recolored node
 :)
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
 : @error rbtree:CHCK0004 if a node is double-black or negative black
 : @error rbtree:CHCK0005 if the two sub-trees have different black heights
 :)
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
        error(xs:QName('rbtree:CHCK0003'), $msg)
      ) else if($c = ($rbtree:NEG_BLACK, $rbtree:DBL_BLACK)) then (
        error(xs:QName('rbtree:CHCK0004'), $msg)
      ) else (
        let $h1 := rbtree:check($lt, $l, $min, $k, $msg),
            $h2 := rbtree:check($lt, $r, $k, $max, $msg)
        return if($h1 ne $h2) then (
          error(xs:QName('rbtree:CHCK0005'), $msg)
        ) else if($c eq $rbtree:RED) then $h1 else $h1 + 1
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
    function($c) {
      element {
        if($c eq $rbtree:NEG_BLACK) then 'RR'
        else if($c eq $rbtree:RED) then 'R'
        else if($c eq $rbtree:BLACK) then 'B'
        else 'BB'
      } {}
    },
    function($c, $l, $k, $v, $r) {
      element {
        if($c eq $rbtree:NEG_BLACK) then 'RR'
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
    function($_) { $acc1 },
    function($_, $l, $k, $v, $r) {
      let $acc2 := rbtree:fold($l, $acc1, $f),
          $acc3 := $f($acc2, $k, $v),
          $acc4 := rbtree:fold($r, $acc3, $f)
      return $acc4
    }
  )
};

