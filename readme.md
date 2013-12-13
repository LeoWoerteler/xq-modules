Higher-Order XQuery Modules
===========================

This repository contains various algorithms and data structures implemented in pure [XQuery 3.0](http://www.w3.org/TR/xquery-30/). They all are purely functional and mostly inspired by Chris Okasaki's excellent [Purely Functional Data Structures](http://www.amazon.com/Purely-Functional-Structures-Chris-Okasaki/dp/0521663504) and similar modules written in [Haskell](http://en.wikipedia.org/wiki/Haskell_%28programming_language%29).

Some examples are:
 * a [priority queue](http://www.woerteler.de/xquery/modules/heap.html) implemented as a [Skew Heap](https://github.com/LeoWoerteler/xq-modules/blob/master/src/main/xquery/modules/heap.xqm)
 * a [map](http://www.woerteler.de/xquery/modules/ordered-map.html) implemented as a [Red-Black Tree](https://github.com/LeoWoerteler/xq-modules/blob/master/src/main/xquery/modules/ordered_map/rbtree.xqm) (or alternatively as an [AVL Tree](https://github.com/LeoWoerteler/xq-modules/blob/master/src/main/xquery/modules/ordered_map/avltree.xqm))
 * a [FIFO queue](http://www.woerteler.de/xquery/modules/queue.html) implemented as a [pair of linked lists](https://github.com/LeoWoerteler/xq-modules/blob/master/src/main/xquery/modules/queue.xqm)

An example application that uses all of the above under the hood is Dijkstra's [single-source shortest path algorithm](https://github.com/LeoWoerteler/xq-modules/blob/master/src/test/xquery/dijkstra.xq).

Data Types
----------

Data types are mostly encoded as [inline functions](http://www.w3.org/TR/xquery-30/#id-inline-func) using the [Scott Encoding](http://en.wikipedia.org/wiki/Scott_encoding). This means that arbitrary sequences can be stored and retrieved without the need for serialization.

Documentation
-------------

Functions and variables are annotated with [xqDoc](http://xqdoc.org/) comments. Generated documentation is available [here](http://www.woerteler.de/xquery/modules/) and under each module's namespace URI.

License
-------

All code is made available under the [BSD 2-Clause License](http://opensource.org/licenses/BSD-2-Clause) except where explicitly marked otherwise.
