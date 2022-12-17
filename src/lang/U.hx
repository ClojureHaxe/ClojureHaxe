package lang;

import Type.ValueType;
import haxe.ds.Vector;

// Becuase Haxe doesn't allow to overload functions with different args count,
// it needs to declare a function with maximum possible arguments.
// And to distinguish the absense of arg from nil we need special default value.
enum EMPTY_ARG {
	NO_ARG;
}

class U {
	// public static final NoArg:Any = new EmptyArg();
	public static function instanceof(value:Any, c:Any):Bool {
		// return Std.downcast(value, c) != null;
		return Std.isOfType(value, c);
	}

	public inline static function getClassName(v:Any):String {
		return Type.getClassName(Type.getClass(v));
	}

	public inline static function isIterable(v:Any):Bool {
		return (try {
			(cast v).iterator();
		} catch (e) {
			null;
		}) != null;
	}

	public inline static function getIterator(v:Any):Iterator<Any> {
		var iter:Iterator<Any> = try {
			(cast v).iterator();
		} catch (e) {
			null;
		}
		return iter;
	}

	public static function typeName(v:Any):String {
		switch (Type.typeof(v)) {
			case ValueType.TNull:
				return 'nil';
			// case ValueType.TClass:
			//	return Type.getClassName(Type.getClass(v));
			case ValueType.TInt:
				return "Int";
			case ValueType.TFloat:
				return "Float";
			case ValueType.TBool:
				return "Bool";
			case ValueType.TObject:
				return "Object";
			case ValueType.TFunction:
				return "Function";
			/*case ValueType.TEnum(Any):
				return "TEnum"; */
			case ValueType.TUnknown:
				return "Unknown";
			default:
				var cl = Type.getClass(v);
				if (cl != null) {
					return Type.getClassName(cl);
				} else {
					return "Unknown";
				}
		}
	}

	// public inline function instanceof2(v Any, c ):Bool {
	// }

	static public inline function vectorCopy(src:Vector<Any>, srcPos:Int, dst:Vector<Any>, dstPos:Int, l:Int) {
		Vector.blit(src, srcPos, dst, dstPos, l);
	}
}

// class EmptyArg {
// 	public function new() {}
// }
