package test;

import lang.Symbol;
import lang.Var;
import lang.IPersistentMap;
import lang.RT;
import utest.Test;
import utest.Assert;
import lang.Namespace;
import lang.ISeq;

class NamespaceTest extends Test {
	function test() {
		var sym:Symbol = Symbol.intern1("clojure.core");

		var all:ISeq = RT.seq(Namespace.all());
		Assert.equals(1, all.count());

		var clojureNS:Namespace = RT.first(all);
		Assert.isTrue(sym.equals(clojureNS.name));

		clojureNS = Namespace.find(sym);
		Assert.isTrue(sym.equals(clojureNS.name));

		var m:IPersistentMap = clojureNS.getMappings();
		Assert.isTrue(m.containsKey(Symbol.intern1("*ns*")));

		// var all:ISeq = Namespace.all();

		// DEV
		// trace(">>>>>>>>>>> NamespaceTest");
		// trace(m);
		/*
			var ns:ISeq = Namespace.all();
			trace("ALL: " + ns + " " + ns.count());
			while (ns != null) {
				var v = ns.first();
				trace("::: " + v);
				ns = ns.next();
			}
		 */
	}

	function testOtherNS() {
		var sym:Symbol = Symbol.intern1("project.my-ns");
		var nsCount:Int = RT.count(Namespace.all());
		var ns:Namespace = Namespace.findOrCreate(sym);

		var vsym:Symbol = Symbol.intern1("var1");
		var v:Var = ns.intern(vsym);
		v = ns.intern(vsym);

		Namespace.remove(sym);
		Assert.equals(nsCount, RT.count(Namespace.all()));
	}
}
