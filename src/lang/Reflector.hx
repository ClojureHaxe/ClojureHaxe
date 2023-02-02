package lang;

import haxe.ds.Vector;

class Reflector {
	public static function invokeConstructor(c:Class<Dynamic>, args:Vector<Any>):Any {
		return Type.createInstance(c, args.toArray());
	}

	public static function invokeStaticMethod(className:String, methodName:String, args:Vector<Any>):Any {
		var c:Class<Dynamic> = RT.classForName(className);
		return invokeMethod(c, methodName, args);
	}

	// class or instance
	public static function invokeMethod(c:Any, /* c:Class<Dynamic>, */ methodName:String, args:Vector<Any>):Any {
		if (methodName == "new")
			return invokeConstructor(c, args);
		// List methods = getMethods(c, args.length, methodName, true);
		// return invokeMatchingMethod(methodName, methods, null, args);
		var fn = Reflect.field(c, methodName);
		return Reflect.callMethod(c, fn, args.toArray());
	}

	public static function getStaticField(className:String, fieldName:String):Any {
		var c:Class<Dynamic> = RT.classForName(className);
		return getField(c, fieldName);
	}

	// class or instance
	public static function getField(c:Any, /* c:Class<Dynamic>, */ fieldName:String):Any {
		/*
			Field f = getField(c, fieldName, true);
			if (f != null) {
				try {
					return prepRet(f.getType(), f.get(null));
				} catch (IllegalAccessException e) {
					throw Util.sneakyThrow(e);
				}
			}
			throw new IllegalArgumentException("No matching field found: " + fieldName
					+ " for " + c);
		 */
		return Reflect.field(c, fieldName);
	}

	public static function setStaticField(className:String, fieldName:String, val:Any):Any {
		var c:Class<Dynamic> = RT.classForName(className);
		return setField(c, fieldName, val);
	}

	// class or instance
	public static function setField(c:Any /*c:Class<Dynamic> */, fieldName:String, val:Any):Any {
		/*
			Field f = getField(c, fieldName, true);
			if (f != null) {
				try {
					f.set(null, boxArg(f.getType(), val));
				} catch (IllegalAccessException e) {
					throw Util.sneakyThrow(e);
				}
				return val;
			}
			throw new IllegalArgumentException("No matching field found: " + fieldName
					+ " for " + c);
		 */
		Reflect.setField(c, fieldName, val);
		return val;
	}
}
