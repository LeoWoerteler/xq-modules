xquery version "3.0";

(:~
 : A simple queue implementation.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace queue = 'http://www.basex.org/modules/queue';

import module namespace pair = 'http://www.basex.org/modules/pair'
    at 'pair.xqm';

import module namespace list = 'http://www.basex.org/modules/list'
    at 'list.xqm';

(:~
 : The empty queue.
 : @return the empty queue
 :)
declare %public function queue:empty() {
  pair:new(list:nil(), list:nil())
};

(:~
 : Enqueues the given value into the given queue.
 :
 : @param $x the value to enqueue
 : @param $queue the queue
 : @return the queue with <code>$x</code> added at the back
 :)
declare %public function queue:enqueue(
  $x as item()*,
  $queue
) as function(*) {
  pair:deconstruct(
    $queue,
    function($hd, $tl) {
      list:match(
        $hd,
        function() { pair:new(list:cons($x, list:nil()), list:nil()) },
        function($_, $__) {
          pair:new($hd, list:cons($x, $tl))
        }
      )
    }
  )
};

(:~
 : Matches the given queue and calls the corresponding callback for the empty
 : or non-empty queue.
 : @param $queue queue to match on
 : @param $empty no-argument callback for the empty queue
 : @param $nonEmpty callback for the non-empty queue that takes the first element
                    and the tai of the queue
 :)
declare %public function queue:match(
  $queue as function(*),
  $empty as function() as item()*,
  $nonEmpty as function(item()*, function(*)) as item()*
) as item()* {
  pair:deconstruct(
    $queue,
    function($xs, $ys) {
      list:match(
        $xs,
        $empty,
        function($x, $xss) {
          $nonEmpty(
            $x,
            list:match(
              $xss,
              function() { pair:new(list:reverse($ys), list:nil()) },
              function($_, $__) { pair:new($xss, $ys) }
            )
          )
        }
      )
    }
  )
};

(:~
 : Returns the tail of the queue.
 :
 : @return tail of the queue
 : @throws queue:EMPTYQUE when the queue is empty
 :)
declare %public function queue:tail(
  $queue as function(*)
) as item()* {
  queue:match(
    $queue,
    function() { error(xs:QName('queue:EMPTYQUE'), 'empty queue') },
    function($_, $tail) { $tail }
  )
};

(:~
 : Returns the head of the queue.
 :
 : @return value at the head of the queue
 : @throws queue:EMPTYQUE when the queue is empty
 :)
declare %public function queue:peek(
  $queue as function(*)
) as item()* {
  queue:match(
    $queue,
    function() { error(xs:QName('queue:EMPTYQUE'), 'empty queue') },
    function($x, $_) { $x }
  )
};
