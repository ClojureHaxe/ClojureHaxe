package lang.compiler;

class StaticFieldExpr extends FieldExpr implements AssignableExpr {
	public var fieldName:String;
	public var c:Class<Dynamic>;
	// public var java.lang.reflect.Field field;
	public var tag:Symbol;

	var line:Int;
	var column:Int;

	// Class jc;

	public function new(line:Int, column:Int, c:Class<Dynamic>, fieldName:String, tag:Symbol) {
		// this.className = className;
		this.fieldName = fieldName;
		this.line = line;
		this.column = column;
		// c = Class.forName(className);
		this.c = c;
		/*try {
				field = c.getField(fieldName);
			} catch (e:NoSuchFieldException ) {
				for (java.lang.reflect.Method m : c.getMethods())
					if (fieldName.equals(m.getName()) && (Modifier.isStatic(m.getModifiers())))
						throw new IllegalArgumentException("No matching method " +
								fieldName +
								" found taking 0 args for " +
								c);
				throw Util.sneakyThrow(e);
		}*/
		this.tag = tag;
	}

	public function eval():Any {
		return Reflector.getField(c, fieldName);
	}

	/*
		public boolean canEmitPrimitive() {
			return Util.isPrimitive(field.getType());
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			gen.visitLineNumber(line, gen.mark());
			gen.getStatic(Type.getType(c), fieldName, Type.getType(field.getType()));
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			gen.visitLineNumber(line, gen.mark());

			gen.getStatic(Type.getType(c), fieldName, Type.getType(field.getType()));

			HostExpr.emitBoxReturn(objx, gen, field.getType());
			if (context == C.STATEMENT) {
				gen.pop();
			}
			taticFieldMethod);
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {

			if (jc == null)
				jc = tag != null ? HostExpr.tagToClass(tag) : field.getType();
			return jc;
		}
	 */
	public function evalAssign(val:Expr):Any {
		return Reflector.setField(c, fieldName, val.eval());
	}
	/*
		public void emitAssign(C context, ObjExpr objx, GeneratorAdapter gen,
							   Expr val) {
			val.emit(C.EXPRESSION, objx, gen);
			gen.visitLineNumber(line, gen.mark());
			gen.dup();
			HostExpr.emitUnboxArg(objx, gen, field.getType());
			gen.putStatic(Type.getType(c), fieldName, Type.getType(field.getType()));
			if (context == C.STATEMENT)
				gen.pop();
		}
	 */
}
