xquery version "3.0";

(:
 : Copyright (c) 2010-2011 John Snelson
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)

module namespace rbtree = "http://snelson.org.uk/functions/rbtree";
declare default function namespace "http://snelson.org.uk/functions/rbtree";

declare function create() as function() as item()*
{
  function() as empty-sequence() { () }
};

declare %private function create(
  $x as item(),
  $a as function() as item()*,
  $b as function() as item()*,
  $isred as xs:boolean
) as function() as item()+
{
  function() as item()+ { $x, $a, $b, $isred }
};

declare function empty($tree as function() as item()*) as xs:boolean
{
  fn:empty($tree())
};

declare %private function value($tree as function() as item()*) as item()
{
  $tree()[1]
};

declare %private function left($tree as function() as item()*) as function() as item()*
{
  $tree()[2]
};

declare %private function right($tree as function() as item()*) as function() as item()*
{
  $tree()[3]
};

declare %private function isred($tree as function() as item()*) as xs:boolean
{
  $tree()[4]
};

declare function contains(
  $lessthan as function(item(), item()) as xs:boolean,
  $tree as function() as item()*,
  $x as item()
) as xs:boolean
{
  fn:exists(get($lessthan, $tree, $x))
};

declare function get(
  $lessthan as function(item(), item()) as xs:boolean,
  $tree as function() as item()*,
  $x as item()
) as item()?
{
  find_gte($lessthan, $tree, $x)[fn:not($lessthan($x, .))]
};

declare function find_gte(
  $lessthan as function(item(), item()) as xs:boolean,
  $tree as function() as item()*,
  $x as item()
) as item()?
{
  if(empty($tree)) then () else

  let $y := value($tree)
  return

  if($lessthan($y, $x)) then find_gte($lessthan, right($tree), $x)
  else fn:head((find_gte($lessthan, left($tree), $x), $y))
};

declare function fold(
  $f as function(item()*, item()) as item()*,
  $z as item()*,
  $tree as function() as item()*
) as item()*
{
  if(empty($tree)) then $z else

  fold($f,
    $f(fold($f, $z, left($tree)), value($tree)),
    right($tree))
};

declare function insert(
  $lessthan as function(item(), item()) as xs:boolean,
  $tree as function() as item()*,
  $x as item()
) as function() as item()+
{
  let $result := insert_helper($lessthan, $tree, $x)
  return

  if(fn:empty(fn:tail($result))) then $result else

  let $rb := fn:head($result)
  return

  create(value($rb), left($rb), right($rb), fn:false())
};

declare %private function insert_helper(
  $lessthan as function(item(), item()) as xs:boolean,
  $tree as function() as item()*,
  $x as item()
) as item()+
{
  if(empty($tree)) then create($x, create(), create(), fn:true()) else

  let $y := value($tree)
  let $a := left($tree)
  let $b := right($tree)
  let $isred := isred($tree)
  return

  if($lessthan($x, $y)) then (
    let $ins := insert_helper($lessthan, $a, $x)
    let $a_ := fn:head($ins)
    return

    if(isred($a_)) then
      if(fn:empty(fn:tail($ins))) then
        (create($y, $a_, $b, $isred), "l")
      else if(fn:tail($ins) = "l") then
        let $gc := left($a_)
        return
        balance(value($gc), value($a_), $y,
          left($gc), right($gc), right($a_), $b)
      else
        let $gc := right($a_)
        return
        balance(value($a_), value($gc), $y,
          left($a_), left($gc), right($gc), $b)
    else
      create($y, $a_, $b, $isred)
  )
  else if($lessthan($y, $x)) then (
    let $ins := insert_helper($lessthan, $b, $x)
    let $b_ := fn:head($ins)
    return

    if(isred($b_)) then (
      if(fn:empty(fn:tail($ins))) then
        (create($y, $a, $b_, $isred), "r")
      else if(fn:tail($ins) = "l") then
        let $gc := left($b_)
        return
        balance($y, value($gc), value($b_),
          $a, left($gc), right($gc), right($b_))
      else
        let $gc := right($b_)
        return
        balance($y, value($b_), value($gc),
          $a, left($b_), left($gc), right($gc))
    ) else
      create($y, $a, $b_, $isred)
  )
  else create($x, $a, $b, $isred)
};

declare %private function balance(
  $x as item(),
  $y as item(),
  $z as item(),
  $a as function() as item()*,
  $b as function() as item()*,
  $c as function() as item()*,
  $d as function() as item()*
) as function() as item()+
{
  create(
    $y,
    create($x, $a, $b, fn:false()),
    create($z, $c, $d, fn:false()),
    fn:true()
  )
};
