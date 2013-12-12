Higher-Order XQuery Modules
===========================

This repository contains various algorithms and data structures implemented in pure [XQuery 3.0](http://www.w3.org/TR/xquery-30/). They all are purely functional and mostly inspired by similar modules written in [Haskell](http://en.wikipedia.org/wiki/Haskell_%28programming_language%29).

Data Types
----------

All data types are encoded as [inline functions](http://www.w3.org/TR/xquery-30/#id-inline-func) using the [Scott Encoding](http://en.wikipedia.org/wiki/Scott_encoding). This means that arbitrary sequences can be stored and retrieved without the need for serialization.

Documentation
-------------

All functions and variables are annotated with [xqDoc](http://xqdoc.org/) comments. Generated documentation is available [here](http://www.woerteler.de/xquery/modules/) under each module's namespace URI.
