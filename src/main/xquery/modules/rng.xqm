(:~
 : A simple random number generator implemented as a Linear Congruential Generator.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license BSD 2-Clause License
 :)
module namespace rng = 'http://www.woerteler.de/xquery/modules/rng';

(:~ The number 2<sup>32</sup>. :)
declare %private variable $rng:e32 := 4294967296;

(:~
 : Generates <code>$n</code> random <code>xs:int</code>s, starting with the given seed.
 :
 : @param $seed the seed to start from
 : @param $n number of random ints to produce
 : @return sequence 
 :)
declare %public function rng:random-ints(
  $seed as xs:integer,
  $n as xs:integer
) as xs:int* {
  rng:with-random-ints($seed, $n, (), function($seq, $i) { ($seq, $i) })
};

(:~
 : Folds over a sequence of <code>$n</code> randomly generated <code>xs:int</code>s,
 : starting with the value <code>$start</code> and successively adding random ints
 : by calling <code>$f</code> with the current value and the next int.
 :
 : @param $seed seed for the random number generator
 : @param $n number of random numbers to generate
 : @param $start initial value for the fold
 : @param $f combining function
 : @return result of the fold
 :)
declare %public function rng:with-random-ints(
  $seed as xs:integer,
  $n as xs:integer,
  $start as item()*,
  $f as function(item()*, item()*) as item()*
) as item()* {
  let $go :=
    (: keep the outer function non-recursive so $f can be inlined :)
    function($go, $s, $k, $acc) {
      if($k ge $n) then $acc
      else $go(
        $go,
        rng:next($s),
        $k + 1,
        $f($acc, xs:int($s - $rng:e32 idiv 2))
      )
    }
  return $go($go, rng:next(abs($seed) mod $rng:e32), 0, $start)
};


declare %private function rng:next($seed) {
  ($seed * 1664525 + 1013904223) mod $rng:e32
};
