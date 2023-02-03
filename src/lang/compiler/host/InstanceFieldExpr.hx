package lang.compiler.host;

class InstanceFieldExpr extends FieldExpr implements AssignableExpr {
	public var target:Expr;
	// public var  targetClass:Class<Dynamic>;
	// public final java.lang.reflect.Field field;
	public var fieldName:String;
	public var line:Int;
	public var column:Int;
	public var tag:Symbol;
	public var requireField:Bool;

	// final static Method invokeNoArgInstanceMember = Method.getMethod("Object invokeNoArgInstanceMember(Object,String,boolean)");
	// final static Method setInstanceFieldMethod = Method.getMethod("Object setInstanceField(Object,String,Object)");
	//  Class jc;

	public function new(line:Int, column:Int, target:Expr, fieldName:String, tag:Symbol, requireField:Bool) {
		this.target = target;
		// this.targetClass = target.hasJavaClass() ? target.getJavaClass() : null;
		// this.field = targetClass != null ? Reflector.getField(targetClass, fieldName, false) : null;
		this.fieldName = fieldName;
		this.line = line;
		this.column = column;
		this.tag = tag;
		this.requireField = requireField;
		/*
			if (field == null && RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
				if (targetClass == null) {
					RT.errPrintWriter()
							.format("Reflection warning, %s:%d:%d - reference to field %s can't be resolved.\n",
									SOURCE_PATH.deref(), line, column, fieldName);
				} else {
					RT.errPrintWriter()
							.format("Reflection warning, %s:%d:%d - reference to field %s on %s can't be resolved.\n",
									SOURCE_PATH.deref(), line, column, fieldName, targetClass.getName());
				}
			}
		 */
	}

	public function eval():Any {
		// return Reflector.invokeNoArgInstanceMember(target.eval(), fieldName, requireField);
		return Reflector.getField(target.eval(), fieldName);
	}

	/*
		public function canEmitPrimitive():Bool {
			return targetClass != null && field != null &&
					Util.isPrimitive(field.getType());
		}

		/*
		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (targetClass != null && field != null) {
				target.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.checkCast(getType(targetClass));
				gen.getField(getType(targetClass), fieldName, Type.getType(field.getType()));
			} else
				throw new UnsupportedOperationException("Unboxed emit of unknown member");
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (targetClass != null && field != null) {
				target.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.checkCast(getType(targetClass));
				gen.getField(getType(targetClass), fieldName, Type.getType(field.getType()));
				//if(context != C.STATEMENT)
				HostExpr.emitBoxReturn(objx, gen, field.getType());
				if (context == C.STATEMENT) {
					gen.pop();
				}
			} else {
				target.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.push(fieldName);
				gen.push(requireField);
				gen.invokeStatic(REFLECTOR_TYPE, invokeNoArgInstanceMember);
				if (context == C.STATEMENT)
					gen.pop();
			}
		}


		public boolean hasJavaClass() {
			return field != null || tag != null;
		}

		public Class getJavaClass() {
			if (jc == null)
				jc = tag != null ? HostExpr.tagToClass(tag) : field.getType();
			return jc;
		}

	 */
	public function evalAssign(val:Expr):Any {
		return Reflector.setField(target.eval(), fieldName, val.eval());
	}
	/*
		public void emitAssign(C context, ObjExpr objx, GeneratorAdapter gen,
							   Expr val) {
			if (targetClass != null && field != null) {
				target.emit(C.EXPRESSION, objx, gen);
				gen.checkCast(getType(targetClass));
				val.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.dupX1();
				HostExpr.emitUnboxArg(objx, gen, field.getType());
				gen.putField(getType(targetClass), fieldName, Type.getType(field.getType()));
			} else {
				target.emit(C.EXPRESSION, objx, gen);
				gen.push(fieldName);
				val.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.invokeStatic(REFLECTOR_TYPE, setInstanceFieldMethod);
			}
			if (context == C.STATEMENT)
				gen.pop();
		}
	 */
}
