(:~
 : A simple heap implementation.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 :)
module namespace heap = 'http://www.basex.org/modules/heap';

(:~
 : Creates a new empty binary heap with a given comparison function.
 :
 : @param $leq comparison function, returns true() if
 :   the first argument is less-than-or-equal to the second one
 : @return a new empty binary heap
 :)
declare %public function heap:new(
  $leq as function(item()*, item()*) as xs:boolean
) as function(*) {
  function($f) {
    $f($leq, heap:empty())
  }
};

(:~
 : Inserts a value into a heap.
 :
 : @param $heap heap to insert the value into
 : @param $x value to insert
 : @return the heap where $x is inserted
 :)
declare %public function heap:insert(
  $heap as function(*),
  $x as item()*
) as function(*) {
  $heap(function($leq, $root) {
    heap:create(
      $leq,
      heap:union(
        $leq,
        function($_, $b) {
          $b(heap:empty(), $x, heap:empty())
        },
        $root
      )
    )
  })
};

(:~
 : tries to extract the minimum value from the given heap.
 : If the heap is empty, the empty sequence is returned.
 : Otherwise the result is a sequence of which the first element
 : is the heap where the minimum was deleted and the rest of
 : the sequence is the extracted minimum.
 :
 : @param $heap heap from which the minimum should be extracted
 : @return sequence of new heap and extracted minimum
 :)
declare %public function heap:extract-min(
  $heap as function(*)
) as item()* {
  $heap(function($leq, $root) {
    $root(
      function() { () },
      function($l, $x, $r) {
        (
          heap:create($leq, heap:union($leq, $l, $r)),
          $x
        )
      }
    )
  })
};

declare %public function heap:sort(
  $cmp as function(item(), item()) as item()*,
  $seq as item()*
) as item()* {
  if(empty($seq)) then ()
  else
    let $heap := heap:build(
          $seq ! heap:branch(heap:empty(), ., heap:empty()),
          $cmp
        )
    return heap:values($cmp, $heap, ())
};

(::::::::::::::::::::::::::: private functions :::::::::::::::::::::::::::)

declare %private function heap:build(
  $heaps as function(*)*,
  $cmp as function(item(), item()) as item()*
) as function(*) {
  if(count($heaps) eq 1) then $heaps
  else
    let $a := $heaps[1], $b := $heaps[2],
        $union := heap:union($cmp, $a, $b)
    return heap:build(
      (subsequence($heaps, 3), $union),
      $cmp
    )
};

declare %private function heap:values(
  $cmp as function(item(), item()) as item()*,
  $heap as function(*),
  $seq as item()*
) as item()* {
  $heap(
    function() { $seq },
    function($l, $x, $r) {
      heap:values($cmp, heap:union($cmp, $l, $r), ($seq, $x))
    }
  )
};

(:~
 : Creates a wrapper for the heap's root and its comparison function.
 :
 : @param $leq comparison function
 : @param $root root of the heap
 : @return wrapped heap
 :)
declare %private function heap:create(
  $leq as function(item()*, item()*) as xs:boolean,
  $root as function(*)
)as function(*) {
  function($f) { $f($leq, $root) }
};

(:~
 : The empty heap.
 :
 : @return an empty heap
 :)
declare %private function heap:empty() {
  function($empty, $branch) { $empty() }
};

(:~
 : Creates an inner node of a heap.
 :
 : @param $left left sub-tree
 : @param $x value contained in the root
 : @param $right right sub-tree
 : @return newly created heap
 :)
declare %private function heap:branch(
  $left as function(*),
  $x as item()*,
  $right as function(*)
) {
  function($empty, $branch) {
    $branch($left, $x, $right)
  }
};

(:~
 : Merges two heaps.
 :
 : @param $leq comparison function
 : @param $left left heap
 : @param $right right heap
 : @return the heap resulting from merging $left and $right
 :)
declare %private function heap:union(
  $leq as function(item()*, item()*) as xs:boolean,
  $left as function(*),
  $right as function(*)
) as function(*) {
  $left(
    function() { $right },
    function($ll, $lx, $lr) {
      $right(
        function() { $left },
        function($rl, $rx, $rr) {
          if($leq($lx, $rx))
            then heap:branch($lr, $lx, heap:union($leq, $ll, $right))
            else heap:branch($rr, $rx, heap:union($leq, $rl, $left))
        }
      )
    }
  )
};
