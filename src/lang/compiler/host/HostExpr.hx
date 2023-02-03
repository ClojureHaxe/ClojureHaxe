package lang.compiler.host;

import lang.Compiler.C;
import lang.exceptions.IllegalArgumentException;
import haxe.Exception;

abstract class HostExpr implements Expr implements MaybePrimitiveExpr {
	/*
		final static Type BOOLEAN_TYPE = Type.getType(Boolean.class);
		final static Type CHAR_TYPE = Type.getType(Character.class);
		final static Type INTEGER_TYPE = Type.getType(Integer.class);
		final static Type LONG_TYPE = Type.getType(Long.class);
		final static Type FLOAT_TYPE = Type.getType(Float.class);
		final static Type DOUBLE_TYPE = Type.getType(Double.class);
		final static Type SHORT_TYPE = Type.getType(Short.class);
		final static Type BYTE_TYPE = Type.getType(Byte.class);
		final static Type NUMBER_TYPE = Type.getType(Number.class);

		final static Method charValueMethod = Method.getMethod("char charValue()");
		final static Method booleanValueMethod = Method.getMethod("boolean booleanValue()");

		final static Method charValueOfMethod = Method.getMethod("Character valueOf(char)");
		final static Method intValueOfMethod = Method.getMethod("Integer valueOf(int)");
		final static Method longValueOfMethod = Method.getMethod("Long valueOf(long)");
		final static Method floatValueOfMethod = Method.getMethod("Float valueOf(float)");
		final static Method doubleValueOfMethod = Method.getMethod("Double valueOf(double)");
		final static Method shortValueOfMethod = Method.getMethod("Short valueOf(short)");
		final static Method byteValueOfMethod = Method.getMethod("Byte valueOf(byte)");

		final static Method intValueMethod = Method.getMethod("int intValue()");
		final static Method longValueMethod = Method.getMethod("long longValue()");
		final static Method floatValueMethod = Method.getMethod("float floatValue()");
		final static Method doubleValueMethod = Method.getMethod("double doubleValue()");
		final static Method byteValueMethod = Method.getMethod("byte byteValue()");
		final static Method shortValueMethod = Method.getMethod("short shortValue()");

		final static Method fromIntMethod = Method.getMethod("clojure.lang.Num from(int)");
		final static Method fromLongMethod = Method.getMethod("clojure.lang.Num from(long)");
		final static Method fromDoubleMethod = Method.getMethod("clojure.lang.Num from(double)");
	 */
	/*


		public static void emitBoxReturn(ObjExpr objx, GeneratorAdapter gen, Class returnType) {
			if (returnType.isPrimitive()) {
				if (returnType == boolean.class) {
					Label falseLabel = gen.newLabel();
					Label endLabel = gen.newLabel();
					gen.ifZCmp(GeneratorAdapter.EQ, falseLabel);
					gen.getStatic(BOOLEAN_OBJECT_TYPE, "TRUE", BOOLEAN_OBJECT_TYPE);
					gen.goTo(endLabel);
					gen.mark(falseLabel);
					gen.getStatic(BOOLEAN_OBJECT_TYPE, "FALSE", BOOLEAN_OBJECT_TYPE);
					gen.mark(endLabel);
				} else if (returnType == void.class) {
					NIL_EXPR.emit(C.EXPRESSION, objx, gen);
				} else if (returnType == char.class) {
					gen.invokeStatic(CHAR_TYPE, charValueOfMethod);
				} else {
					if (returnType == int.class) {
						gen.invokeStatic(INTEGER_TYPE, intValueOfMethod);
					} else if (returnType == float.class) {
						gen.invokeStatic(FLOAT_TYPE, floatValueOfMethod);
					} else if (returnType == double.class)
						gen.invokeStatic(DOUBLE_TYPE, doubleValueOfMethod);
					else if (returnType == long.class)
						gen.invokeStatic(NUMBERS_TYPE, Method.getMethod("Number num(long)"));
					else if (returnType == byte.class)
						gen.invokeStatic(BYTE_TYPE, byteValueOfMethod);
					else if (returnType == short.class)
						gen.invokeStatic(SHORT_TYPE, shortValueOfMethod);
				}
			}
		}


		public static void emitUnboxArg(ObjExpr objx, GeneratorAdapter gen, Class paramType) {
			if (paramType.isPrimitive()) {
				if (paramType == boolean.class) {
					gen.checkCast(BOOLEAN_TYPE);
					gen.invokeVirtual(BOOLEAN_TYPE, booleanValueMethod);
				} else if (paramType == char.class) {
					gen.checkCast(CHAR_TYPE);
					gen.invokeVirtual(CHAR_TYPE, charValueMethod);
				} else {
					Method m = null;
					gen.checkCast(NUMBER_TYPE);
					if (RT.booleanCast(RT.UNCHECKED_MATH.deref())) {
						if (paramType == int.class)
							m = Method.getMethod("int uncheckedIntCast(Object)");
						else if (paramType == float.class)
							m = Method.getMethod("float uncheckedFloatCast(Object)");
						else if (paramType == double.class)
							m = Method.getMethod("double uncheckedDoubleCast(Object)");
						else if (paramType == long.class)
							m = Method.getMethod("long uncheckedLongCast(Object)");
						else if (paramType == byte.class)
							m = Method.getMethod("byte uncheckedByteCast(Object)");
						else if (paramType == short.class)
							m = Method.getMethod("short uncheckedShortCast(Object)");
					} else {
						if (paramType == int.class)
							m = Method.getMethod("int intCast(Object)");
						else if (paramType == float.class)
							m = Method.getMethod("float floatCast(Object)");
						else if (paramType == double.class)
							m = Method.getMethod("double doubleCast(Object)");
						else if (paramType == long.class)
							m = Method.getMethod("long longCast(Object)");
						else if (paramType == byte.class)
							m = Method.getMethod("byte byteCast(Object)");
						else if (paramType == short.class)
							m = Method.getMethod("short shortCast(Object)");
					}
					gen.invokeStatic(RT_TYPE, m);
				}
			} else {
				gen.checkCast(Type.getType(paramType));
			}
		}

	 */
	public static function maybeClass(form:Any, stringOk:Bool):Class<Dynamic> {
		if (U.instanceof(form, Class))
			return form;
		var c:Class<Dynamic> = null;
		if (U.instanceof(form, Symbol)) {
			var sym:Symbol = form;
			if (sym.ns == null) // if ns-qualified can't be classname
			{
				if (Util.equals(sym, Compiler.COMPILE_STUB_SYM.get()))
					return Compiler.COMPILE_STUB_CLASS.get();
				trace(">>>>>> HostExpr/maybeClass " + form);
				if (sym.name.indexOf('.') > 0 || sym.name.charAt(0) == '[')
					c = RT.classForNameNonLoading(sym.name);
				else {
					var o:Any = Compiler.currentNS().getMapping(sym);
					if (U.instanceof(o, Class))
						c = o;
					// TODO: (cast Compiler.LOCAL_ENV.deref()) to MAP interface
					else if (Compiler.LOCAL_ENV.deref() != null && (cast Compiler.LOCAL_ENV.deref()).containsKey(form))
						return null;
					else {
						try {
							c = RT.classForNameNonLoading(sym.name);
						} catch (e:Exception) {
							// aargh
							// leave c set to null -> return null
						}
					}
				}
			}
		} else if (stringOk && U.instanceof(form, String))
			c = RT.classForNameNonLoading(form);
		return c;
	}
	/*

		public static Class maybeSpecialTag(Symbol sym) {
			Class c = primClass(sym);
			if (c != null)
				return c;
			else if (sym.name.equals("objects"))
				c = Object[].class;
			else if (sym.name.equals("ints"))
				c = int[].class;
			else if (sym.name.equals("longs"))
				c = long[].class;
			else if (sym.name.equals("floats"))
				c = float[].class;
			else if (sym.name.equals("doubles"))
				c = double[].class;
			else if (sym.name.equals("chars"))
				c = char[].class;
			else if (sym.name.equals("shorts"))
				c = short[].class;
			else if (sym.name.equals("bytes"))
				c = byte[].class;
			else if (sym.name.equals("booleans"))
				c = boolean[].class;
			return c;
		}


		static Class tagToClass(Object tag) {
			Class c = null;
			if (tag instanceof Symbol) {
				Symbol sym = (Symbol) tag;
				if (sym.ns == null) //if ns-qualified can't be classname
				{
					c = maybeSpecialTag(sym);
				}
			}
			if (c == null)
				c = maybeClass(tag, true);
			if (c != null)
				return c;
			throw new IllegalArgumentException("Unable to resolve classname: " + tag);
		}
	 */
}

class HostExprParser implements IParser {
	public function new() {}

	public function parse(context:C, frm:Any):Expr {
		var form:ISeq = frm;
		if (RT.length(form) < 3)
			throw new IllegalArgumentException("Malformed member expression, expecting (. target member ...)");
		// determine static or instance
		// static target must be symbol, either fully.qualified.Classname or Classname that has been imported
		var line:Int = Compiler.lineDeref();
		var column:Int = Compiler.columnDeref();
		var source:String = Compiler.SOURCE.deref();
		var c:Class<Dynamic> = HostExpr.maybeClass(RT.second(form), false);
		// at this point c will be non-null if static
		var instance:Expr = null;
		if (c == null)
			instance = Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, RT.second(form));

		var maybeField:Bool = RT.length(form) == 3
			&& U.instanceof(RT.third(form), Symbol)
			&& (RT.third(form) : Symbol).name.charAt(0) == '-';
		/*
			if (maybeField && !((RT.third(form) : Symbol).name.charAt(0) == '-')) {
				var sym:Symbol = RT.third(form);
				// TODO:?
					if (c != null)
						maybeField = Reflector.getMethods(c, 0, munge(sym.name), true).size() == 0;
					else if (instance != null && instance.hasJavaClass() && instance.getJavaClass() != null)
						maybeField = Reflector.getMethods(instance.getJavaClass(), 0, munge(sym.name), false).size() == 0;

				maybeField = true;
			}
		 */

		// trace(">>>>>>>>>>>>>> HOST EXRP: " + c + " " + maybeField);
		if (maybeField) // field
		{
			var sym:Symbol = ((RT.third(form) : Symbol).name.charAt(0) == '-') ? Symbol.intern1((RT.third(form) : Symbol).name.substring(1)) : RT.third(form);
			var tag:Symbol = Compiler.tagOf(form);
			if (c != null) {
				return new StaticFieldExpr(line, column, c, Compiler.munge(sym.name), tag);
			} else
				return new InstanceFieldExpr(line, column, instance, Compiler.munge(sym.name), tag, ((RT.third(form) : Symbol).name.charAt(0) == '-'));
		} else {
			var call:ISeq = ((U.instanceof(RT.third(form), ISeq)) ? RT.third(form) : RT.next(RT.next(form)));
			if (!U.instanceof(RT.first(call), Symbol))
				throw new IllegalArgumentException("Malformed member expression");
			var sym:Symbol = RT.first(call);
			var tag:Symbol = Compiler.tagOf(form);
			var args:PersistentVector = PersistentVector.EMPTY;
			var tailPosition:Bool = Compiler.inTailCall(context);
			var s:ISeq = RT.next(call);
			while (s != null) {
				args = args.cons(Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, s.first()));
				s = s.next();
			}
			// trace(">>>>>>>>>>>>>> HOST EXRP: " + c);
			if (c != null)
				return new StaticMethodExpr(source, line, column, tag, c, Compiler.munge(sym.name), args, tailPosition);
			else
				return new InstanceMethodExpr(source, line, column, tag, instance, Compiler.munge(sym.name), args, tailPosition);
		}
	}
}
