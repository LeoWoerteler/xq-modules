import module namespace queue = 'http://www.basex.org/modules/queue'
    at '../../main/xquery/modules/queue.xqm';

queue:match( (: [1, 2] :)
  queue:enqueue(2, queue:enqueue(1, queue:empty())),
  error#0,
  function($x1, $q1) {
    if($x1 eq 1) then (
      queue:match( (: [2, 3, 4] :)
        queue:enqueue(4, queue:enqueue(3, $q1)),
        error#0,
        function($x2, $q2) {
          if($x2 eq 2) then (
            queue:match( (: [3, 4] :)
              $q2,
              error#0,
              function($x3, $q3) {
                if($x3 eq 3) then (
                  queue:match( (: [4] :)
                    $q3,
                    error#0,
                    function($x4, $q4) {
                      if($x4 eq 4) then (
                        queue:match( (: [] :)
                          $q4,
                          function() { true() },
                          function($_, $__) {
                            error(xs:QName('local:NOTEMPTY'), xs:string($_))
                          }
                        )
                      ) else error()
                    }
                  )
                ) else error()
              }
            )
          ) else error()
        }
      )
    ) else error()
  }
)
