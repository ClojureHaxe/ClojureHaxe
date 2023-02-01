# ClojureHaxe

Clojure port written in [Haxe](https://haxe.org/) targeting C++, HashLink,  Python, Lua, JavaScript, JVM/Java, C#.

## Targets priority
1. C++, HashLink, Python, Lua
2. JavaScript, Java, C# (because these implemetations already exist)
3. PHP, Flash (not tested)

*[HashLink](https://hashlink.haxe.org/) is a virtual machine for Haxe [oriented towards real time games](https://haxe.org/blog/shirogames-stack/).

## Status
Work in progress. Near all major classes from `clojure.lang.*` have been ported, ignoring all concurrent primitives and thread-safety (see 'Concurrent primitives' table at the bottom). On the way to work on Compiler and load/compile `clojure.core`.

## Current status per platform

| Platform | Build size | Tests | Tests time | Comment |
|---| ---| ---|  ---|  ---|
| C++ | 5.5 MB |  157/157 (ALL) | 0,009s |
| HashLink | 302 KB  | 157/157 (ALL) | 0,040s |
| Python | 708 KB  | 157/157 (ALL) | 0,458s |
| Lua | 788 KB | 156/157 |  0,117s | Due to [#10909](https://github.com/HaxeFoundation/haxe/issues/10909) |
| JavaScript | 512 KB | 157/157  (ALL) | 0,196s | Not optimized `.js` file
| Java | 516 KB | 149/153 | 0,426s | Due to [#10906](https://github.com/HaxeFoundation/haxe/issues/10906) |
| C# | | | | Not compiled because of double methods generation  |
| PHP |  || | Not tested
| Flash | | | | Not tested

Tests time are measured with `time <command>` (example `time python3 main.py`)

Pay attention that now only `clojure.lang.*` classes are implemented (and not even all). So after compiling clojure namespaces build sizes will be much bigger.

Build sizes are for builds that run tests.

In Java and Lua there are some bugs in `haxe.Rest` for now, but I think it is possible to avoid them or they will be fixed in feature Haxe realeases.

C# target is not built probably because of complex hierarchy and methods with same names in base class/interface and sublclasses/subinterfaces. Needs more investigating.

## Near future goals

* Be able to run base, general, single-threaded version of Clojure REPL as interpreter (without full support for concurrency and parallelism for now) on various platforms
* Discover all posibilities that this will bring (and continue to work on parallelism and concurrency, dive in target specific features and iterop)
* Have fun



## Concurrent primitives (for future)

| Java primitives  | Haxe alternatives
|---| --- |
| ConcurentHashMap | |
| synchronized (method) | |
| AtomicReference | [Atomic operations](https://github.com/HaxeFoundation/haxe/pull/10610) |
| ThreadLocal | |
| Thread | `lang.misc.Thread` wrapper|

For concurrency and parallelism it will probably need a special library, where for each primitive there would be a wrapper calling appropriate platform-specific realization.
For example, in Atomic wrapper, for Java - using AtomicReference inside, for JS - just var, on other platforms - maybe other [CAS](https://en.wikipedia.org/wiki/Compare-and-swap) implementations. Also [haxe-concurrent](https://github.com/vegardit/haxe-concurrent) library may be helpfull.

## Additional lang.* classes

* `U.hx` - utils for reflection and types

* `Character.hx` - there are not Characters in Haxe

* `Comparable.hx`, `Comparator.hx` - for sorting

* `Collection.hx` - for compatibility
