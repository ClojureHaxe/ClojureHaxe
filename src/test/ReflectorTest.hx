package test;

import lang.U;
import lang.Reflector;
import utest.Test;
import utest.Assert;
import haxe.ds.Vector;

class ReflectorTest extends Test {
	function test() {
		// trace("============================================== ReflectorTest ==============================================");
		// create user
		var v:Vector<Any> = new Vector(2);
		v[0] = "John";
		v[1] = 30;

		// Static fields tests
		Assert.equals(0, Reflector.getField(User, "count"));
		Assert.equals(0, Reflector.getStaticField("test.User", "count"));

		var user:User = Reflector.invokeConstructor(User, v);
		Assert.isTrue(U.instanceof(user, User));

		Assert.equals(1, Reflector.getField(User, "count"));
		Assert.equals(1, Reflector.getStaticField("test.User", "count"));

		Reflector.setField(User, "count", 2);
		Assert.equals(2, Reflector.getField(User, "count"));

		Reflector.setStaticField("test.User", "count", 3);
		Assert.equals(3, Reflector.getStaticField("test.User", "count"));

		// Static methods
		var ev:Vector<Any> = new Vector(0);
		Assert.equals(3, Reflector.invokeMethod(User, "getCount", ev));

		// Instance fields tests
		Reflector.setField(user, "age", 31);
		Assert.equals(31, user.age);
		Assert.equals(31, Reflector.getField(user, "age"));
		Assert.equals(user.say(), Reflector.invokeMethod(user, "say", ev));

		// Reflector.set
		// trace(user, Reflector.getStaticField("test.User", "count"), Reflector.getField(User, "count"));
	}
}

// Be aware that there is static field in Class, so don't use it in anoter tests
// Because they can modify count field and this 'bug' will be hard to catch
class User {
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
		return 'User{name=$name, age=$age}';
	}
}
