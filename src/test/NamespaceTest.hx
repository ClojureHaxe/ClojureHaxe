package test;

import lang.Symbol;
import lang.IPersistentMap;
import utest.Test;
import utest.Assert;
import lang.Namespace;
import lang.ISeq;

class NamespaceTest extends Test {
	function test() {
		// Assert.isTrue(true);
		var cljn:Namespace = Namespace.find(Symbol.intern1("clojure.core"));
		Assert.isTrue(cljn != null);

		var m:IPersistentMap = cljn.getMappings();
		Assert.isTrue(m.containsKey(Symbol.intern1("*ns*")));

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
}
