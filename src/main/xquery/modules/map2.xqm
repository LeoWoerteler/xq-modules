(:~
 : Additional functions for XQuery 3.0 maps.
 :
 : @author Leo Woerteler &lt;leo@woerteler.de&gt;
 : @version 0.1
 : @license MIT License
 :)
module namespace map2='http://www.basex.org/modules/map-extras';

(:~
 : Insert with a combining function. <code>insert-with($f, $key, $value, $map)</code>
 : will insert <code>map:entry($key, $value)</code> into <code>$map</code> if
 : <code>$key</code> does not exist in the map. If the key does exist, the function
 : will insert <code>$f($new-value, $old-value)</code>.
 :
 : @param $f combining function
 : @param $key key to insert
 : @param $value value to insert
 : @param $map map to insert into
 : @return new map where the entry is inserted
 :)
declare function map2:insert-with(
  $f as function(item()*, item()*) as item()*,
  $key as item(),
  $value as item()*,
  $map as map(*)
) as map(*) {
  map:new(($map, map:entry($key,
    if(map:contains($map, $key))
    then $f($value, $map($key))
    else $value
  )))
};

(:~
 : Inserts a key-value pair into a map. If an entry with the key <code>$key</code>
 : already exists in the map, it is replaced by the new one.
 :
 : @param $key key to insert
 : @param $value value to insert
 : @param $map map to insert into
 : @return map where the key-value pair was inserted
 :)
declare %public function map2:insert(
  $key as item(),
  $value as item()*,
  $map as map(*)
) as map(*) {
  map:new(($map, map:entry($key, $value)))
};

(:~
 : Fold the keys and values in the map using the given with the given
 : combining function <code>$f($)</code>.
 : Let <code>(($k1,$v1), ..., ($kn, $vn))</code> be the key-value pairs in the
 : given map <code>$map</code>, then the result is calculated by:
 : <code>$f(... $f($f($start, $k1, $v1), $k2, $v2), ...), $kn, $vn)</code>
 :
 : @param $f left-associative combining function
 : @param $start start value
 : @param $map map to be folded
 : @return resulting value
 :)
declare %public function map2:fold(
  $f as function(item()*, item(), item()*) as item()*,
  $start as item()*,
  $map as map(*)
) as item()* {
  fold-left(
    function($val, $key) { $f($val, $key, $map($key)) },
    $start,
    map:keys($map)
  )
};

(:~
 : Extracts all values from the map <code>$map</code>, returning
 : them in a sequence in arbitrary order.
 :
 : @param $map map to extract the values from
 : @return sequence of values
 :)
declare %public function map2:values(
  $map as map(*)
) as item()* {
  for-each(map:keys($map), $map)
};

(:~
 : Applies the function <code>$f</code> to all values in the map.
 : The keys are not touched.
 :
 : @param $f function to be applies to all values
 : @param $map input map
 : @return copy of <code>$map</code> where all values <code>$value</code>
 :         are replaced by <code>$f($value)</code>
 :)
declare %public function map2:map(
  $f as function(item()*) as item()*,
  $map as map(*)
) as map(*) {
  map:new(
    for $key in map:keys($map)
    return map:entry($key, $f($map($key)))
  )
};

(:~
 : Maps a function over all entries of the map <code>$map</code>.
 : Each entry <code>($key, $value)</code> in the map is replaced by a new
 : entry <code>($key, $f($key, $value))</code>, the keys are not touched.
 :
 : @param $f function to be applies to all entries
 : @param $map input map
 : @return copy of <code>$map</code> where all values <code>$value</code>
 :         are replaced by <code>$f($key, $value)</code>
 :)
declare %public function map2:map-with-key(
  $f as function(item(), item()*) as item()*,
  $map as map(*)
) as map(*) {
  map:new(
    for $key in map:keys($map)
    return map:entry($key, $f($key, $map($key)))
  )
};
