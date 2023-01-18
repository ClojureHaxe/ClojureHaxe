package lang;

import haxe.ds.Vector;

class Reflector {
	public static function invokeConstructor(c:Class<Dynamic>, args:Vector<Any>):Any {
		return Type.createInstance(c, args.toArray());
	}

	public static function invokeStaticMethod(className:String, methodName:String, args:Vector<Any>):Any {
		var c:Class<Dynamic> = RT.classForName(className);
		return invokeStaticMethodClass(c, methodName, args);
	}

	public static function invokeStaticMethodClass(c:Class<Dynamic>, methodName:String, args:Vector<Any>):Any {
		if (methodName == "new")
			return invokeConstructor(c, args);
		// List methods = getMethods(c, args.length, methodName, true);
		// return invokeMatchingMethod(methodName, methods, null, args);
		var fn = Reflect.field(c, methodName);
		return Reflect.callMethod(c, fn, args.toArray());
	}
}
