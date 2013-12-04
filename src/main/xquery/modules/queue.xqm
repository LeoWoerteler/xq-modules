(:~
 : A simple queue implementation.
 :
 : @author Leo Woerteler &lt;lw@basex.org&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace queue = 'http://www.basex.org/modules/queue';

import module namespace pair = 'http://www.basex.org/modules/pair'
    at 'pair.xqm';

import module namespace list = 'http://www.basex.org/modules/list'
    at 'list.xqm';

declare %public function queue:empty() {
  pair:new(list:nil(), list:nil())
};

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

declare %public function queue:dequeue(
  $queue as function(*)
) as item()* {
  queue:match(
    $queue,
    function() { error(xs:QName('queue:EMPTYQUE'), 'empty queue') },
    function($x, $queue2) { $x, $queue2 }
  )
};

declare %public function queue:peek(
  $queue as function(*)
) as item()* {
  queue:match(
    $queue,
    function() { error(xs:QName('queue:EMPTYQUE'), 'empty queue') },
    function($x, $_) { $x }
  )
};
