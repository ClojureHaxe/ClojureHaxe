package test;

import lang.Reflector;
import lang.PersistentHashSet;
import lang.IPersistentMap;
import lang.Compiler;
import lang.Keyword;
import lang.Util;
import lang.PersistentVector;
import lang.U;
import lang.RT;
import lang.Var;
import haxe.ds.Vector;
import utest.Test;
import utest.Assert;

class CompilerTest extends Test {
	function readEval(s:String):Any {
		return Compiler.load(s, "sourcePath", "sourceName");
	}

	function test() {
		Assert.equals(null, readEval("nil"));
		Assert.equals(true, readEval("true"));
		Assert.equals(false, readEval("false"));
		Assert.equals("hello", readEval('"hello"'));
		Assert.equals(10, readEval("10"));
		Assert.equals(10.5, readEval("10.5"));
		Assert.isTrue(Keyword.create1("keyword").equals(readEval(":keyword")));

		Assert.equals(3, readEval("(do 1 2 3)"));

		// map
		var m:IPersistentMap = readEval("(do 1 2 {:a 1 :b 2})");
		Assert.equals(2, m.count());
		Assert.equals(1, m.valAt(Keyword.intern1("a")));
		Assert.equals(2, m.valAt(Keyword.intern1("b")));

		// vector
		Assert.isTrue(Util.equals(PersistentVector.createFromItems(1, 2, 3), readEval("[1,2,3]")));

		// set
		Assert.isTrue(Util.equals(PersistentHashSet.create(1, 2, 3), readEval("#{1,2,3}")));

		// Empty
		Assert.isTrue(Util.equals(PersistentVector.EMPTY, readEval("[]")));

		// trace("============================== CompilerTests ==========================");
		// trace(readEval("1,2,3"));
		// trace(readEval("(let* [a 1] a)"));
		// trace(readEval("(def a 10) a"));
		// trace(readEval("(. lang.RT -AGENT)"));

		// var s:String = "(do 1 2 {:a 1 :b 2 :c [1 2 3]})";
		// trace(readEval(s));
		// var k:Any = true;
		// var k1:Any = 1;
		// var k2:Any = 2;
		// trace("Equality:", (k1 == true), (true == k1), (k2 == true), (true == k2));
		// trace("Equality bool", Type.typeof(1), Type.typeof(2), Type.typeof(true), Type.typeof(false));
		// RT.errPrintWrite("HELLO ERROR");
	}

	public function testIfExpr() {
		Assert.equals(2, readEval("(if 1 2 3)"));
		Assert.equals(3, readEval("(if nil 2 3)"));
		Assert.equals(3, readEval("(if false 2 3)"));
		Assert.isTrue(Keyword.create1("key").equals(readEval("(if true :key 3)")));
	}

	public function testDefExpr() {
		Assert.equals(10, readEval("(def a 10) a"));
	}

	public function testStaticField() {
		Assert.equals(readEval("(. lang.RT -AGENT)"), RT.AGENT);
	}

	public function testNewExpr() {
		var user:Person = readEval("(new test.Person \"Nik\" 20)");
		Assert.isTrue(U.instanceof(user, Person) && user.age == 20 && user.name == "Nik");
	}

	public function testInstanceField() {
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> START testInstanceField >>>>>>>>>>>>>>>>>>>>>>>>");
		var code:String = '(def user
			                   (new test.Person "Nik" 20))
							   
						   (. user -age)';

		Assert.equals(20, readEval(code));
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END testInstanceField >>>>>>>>>>>>>>>>>>>>>>>>");
	}

	public function testInstanceMethod() {
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> START testStaticMethod >>>>>>>>>>>>>>>>>>>>>>>>");
		var code:String = '(def user
			                    (new test.Person "Nik" 20))
			
		                   (. user say)';

		Assert.equals(new Person("Nik", 20).say(), readEval(code));
		var res:Any = readEval(code);
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END testStaticMethod >>>>>>>>>>>>>>>>>>>>>>>>");
	}

	public function testStaticMethod() {
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> START testStaticMethod >>>>>>>>>>>>>>>>>>>>>>>>");
		Person.count = 15;
		var code:String = '(. test.Person getCount)';
		Assert.equals(15, readEval(code));
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> END testStaticMethod >>>>>>>>>>>>>>>>>>>>>>>>");
	}
	/*
		public function testPython {
			// trace("PYTHON TEST>>>>>>>>>>>>>>>>>>>>>>>>>");
			#if python
			// trace(readEval("(. str capitalize \"hello\")"));
			var v:Vector<Any> = new Vector(1);
			v[0] = "hello";
			trace(Reflector.invokeStaticMethod("str", "capitalize", v));

			// trace(python.Syntax.code("str.capitalize({0})", "hello"));
			#end
		}
	 */
}

class Person {
	public static var count:Int = 0;

	public var name:String;
	public var age:Int;

	public static function getCount():Int {
		return count;
	}

	public function new(name:String, age:Int) {
		count++;
		this.name = name;
		this.age = age;
	}

	public function say():String {
		return "Hello, my name is " + name + ",  I'm " + age + " age old!";
	}

	public function toString():String {
		return 'Person{name=$name, age=$age}';
	}
}
