// Some functions that help interact with Haxe
package lang;

import lang.exceptions.IllegalArgumentException;
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

	public static function isNumber(x):Bool {
		return (Type.typeof(x) == ValueType.TInt || Type.typeof(x) == ValueType.TFloat || instanceof(x, Ratio));
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

	static public inline function vectorCopyOf(src:Vector<Any>, newLen:Int):Vector<Any> {
		var v:Vector<Any> = new Vector<Any>(newLen);
		var i:Int = 0;
		while (i < src.length || i < newLen) {
			v[i] = src[i];
			i++;
		}
		while (i < newLen) {
			v[i] = null;
		}
		return v;
	}

	static public function parseChar(s:String):Int {
		var c:Int = s.charCodeAt(0);
		// c >= '0' && c <=
		if (c >= '0'.code && c <= '9'.code) {
			return c - '0'.code;
		}
		if (c >= 'a'.code && c <= 'z'.code){
			return c - 'a'.code + 10;
		}
		if (c >= 'A'.code && c <= 'Z'.code){
			return c - 'A'.code + 10;
		}
		throw new IllegalArgumentException('Cannot parse char "$s" to Int');
	}

	static public function parseInt(s:String, radix:Int):Int {
		var i:Int = s.length - 1;
		var res:Int = 0;
		var mul:Int = 1;
		while (i >= 0) {
			res += parseChar(s.charAt(i)) * mul;
			mul *= radix;
			i--;
		}
		return res;
	}
	/*static public function intToString(i:Int, radix:Int):String {
		if (radix < 2 || radix > 36) {
			radix = 10;
		}
		if (radix == 10) {
			return  '$i';
		}  else {
			byte[] buf = new byte[33];
			boolean negative = i < 0;
			int charPos = 32;
			if (!negative) {
				i = -i;
			}

			while(i <= -radix) {
				buf[charPos--] = (byte)digits[-(i % radix)];
				i /= radix;
			}

			buf[charPos] = (byte)digits[-i];
			if (negative) {
				--charPos;
				buf[charPos] = 45;
			}

			return StringLatin1.newString(buf, charPos, 33 - charPos);
		}
	}*/
}

// class EmptyArg {
// 	public function new() {}
// }
