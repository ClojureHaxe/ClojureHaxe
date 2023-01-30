package test;

import lang.IPersistentMap;
import lang.Symbol;
import lang.Namespace;
import lang.Var;
import lang.RT;
import utest.Test;
import utest.Assert;

class VarTest extends Test {
	function test() {
		//	trace("============================= VarTest =============================");
		var ns:Namespace = Namespace.findOrCreate(Symbol.intern1("my-project.core"));
		var v:Var = Var.new3(ns, Symbol.intern1("my-const"), 10).setDynamic();
		var v2:Var = Var.new3(ns, Symbol.intern1("my-const2"), "hello").setDynamic();
		Assert.equals(v.deref(), 10);
		Assert.equals(v2.deref(), "hello");

		var mp:IPersistentMap = RT.mapUniqueKeys(v, v.deref());
		var mp2:IPersistentMap = RT.mapUniqueKeys(v2, v2.deref());

		// First push
		Var.pushThreadBindings(mp);
		Assert.isTrue(Var.getThreadBindings().containsKey(v));
		// Second push
		Var.pushThreadBindings(mp2);
		Assert.isTrue(Var.getThreadBindings().containsKey(v));
		Assert.isTrue(Var.getThreadBindings().containsKey(v2));
		// First pop
		Var.popThreadBindings();
		Assert.isTrue(Var.getThreadBindings().containsKey(v));
		Assert.isFalse(Var.getThreadBindings().containsKey(v2));
		// Second pop
		Var.popThreadBindings();
		Assert.isFalse(Var.getThreadBindings().containsKey(v));
		Assert.isFalse(Var.getThreadBindings().containsKey(v2));
	}
}
