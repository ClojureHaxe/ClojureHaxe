package lang.compiler.host;

import haxe.Exception;
import haxe.ds.Vector;

class InstanceMethodExpr extends MethodExpr {
	public var target:Expr;
	public var methodName:String;
	public var args:IPersistentVector;
	public var source:String;
	public var line:Int;
	public var column:Int;
	public var tag:Symbol;
	public var tailPosition:Bool;

	// public var java.lang.reflect.Method method;
	// Class jc;
	// final static Method invokeInstanceMethodMethod = Method.getMethod("Object invokeInstanceMethod(Object,String,Object[])");

	public function new(source:String, line:Int, column:Int, tag:Symbol, target:Expr, methodName:String, args:IPersistentVector, tailPosition:Bool) {
		this.source = source;
		this.line = line;
		this.column = column;
		this.args = args;
		this.methodName = methodName;
		this.target = target;
		this.tag = tag;
		this.tailPosition = tailPosition;
		/*
			if (target.hasJavaClass() && target.getJavaClass() != null) {
				List methods = Reflector.getMethods(target.getJavaClass(), args.count(), methodName, false);
				if (methods.isEmpty()) {
					method = null;
					if (RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
						RT.errPrintWriter()
								.format("Reflection warning, %s:%d:%d - call to method %s on %s can't be resolved (no such method).\n",
										SOURCE_PATH.deref(), line, column, methodName, target.getJavaClass().getName());
					}
				} else {
					int methodidx = 0;
					if (methods.size() > 1) {
						ArrayList<Class[]> params = new ArrayList();
						ArrayList<Class> rets = new ArrayList();
						for (int i = 0; i < methods.size(); i++) {
							java.lang.reflect.Method m = (java.lang.reflect.Method) methods.get(i);
							params.add(m.getParameterTypes());
							rets.add(m.getReturnType());
						}
						methodidx = getMatchingParams(methodName, params, args, rets);
					}
					java.lang.reflect.Method m =
							(java.lang.reflect.Method) (methodidx >= 0 ? methods.get(methodidx) : null);
					if (m != null && !Modifier.isPublic(m.getDeclaringClass().getModifiers())) {
						//public method of non-public class, try to find it in hierarchy
						m = Reflector.getAsMethodOfPublicBase(m.getDeclaringClass(), m);
					}
					method = m;
					if (method == null && RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
						RT.errPrintWriter()
								.format("Reflection warning, %s:%d:%d - call to method %s on %s can't be resolved (argument types: %s).\n",
										SOURCE_PATH.deref(), line, column, methodName, target.getJavaClass().getName(), getTypeStringForArgs(args));
					}
				}
			} else {
				method = null;
				if (RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
					RT.errPrintWriter()
							.format("Reflection warning, %s:%d:%d - call to method %s can't be resolved (target class is unknown).\n",
									SOURCE_PATH.deref(), line, column, methodName);
				}
			}

		 */
	}

	public function eval():Any {
		try {
			var targetval:Any = target.eval();
			var argvals:Vector<Any> = new Vector<Any>(args.count());
			var i:Int = 0;
			while (i < args.count()) {
				argvals[i] = (args.nth(i) : Expr).eval();
				i++;
			}
			/*	 
				if (method != null) {
					LinkedList ms = new LinkedList();
					ms.add(method);
					return Reflector.invokeMatchingMethod(methodName, ms, targetval, argvals);
				}
			 */
			return Reflector.invokeMethod(targetval, methodName, argvals);
		} catch (e:Exception) {
			if (!U.instanceof(e, CompilerException))
				throw new CompilerException(source, line, column, null, CompilerException.PHASE_EXECUTION, e);
			else
				throw e;
		}
	}
	/*
		public boolean canEmitPrimitive() {
			return method != null && Util.isPrimitive(method.getReturnType());
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (method != null) {
				Type type = Type.getType(method.getDeclaringClass());
				target.emit(C.EXPRESSION, objx, gen);
				//if(!method.getDeclaringClass().isInterface())
				gen.checkCast(type);
				MethodExpr.emitTypedArgs(objx, gen, method.getParameterTypes(), args);
				gen.visitLineNumber(line, gen.mark());
				if (tailPosition && !objx.canBeDirect) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearThis(gen);
				}
				Method m = new Method(methodName, Type.getReturnType(method), Type.getArgumentTypes(method));
				if (method.getDeclaringClass().isInterface())
					gen.invokeInterface(type, m);
				else
					gen.invokeVirtual(type, m);
			} else
				throw new UnsupportedOperationException("Unboxed emit of unknown member");
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (method != null) {
				Type type = Type.getType(method.getDeclaringClass());
				target.emit(C.EXPRESSION, objx, gen);
				//if(!method.getDeclaringClass().isInterface())
				gen.checkCast(type);
				MethodExpr.emitTypedArgs(objx, gen, method.getParameterTypes(), args);
				gen.visitLineNumber(line, gen.mark());
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				Method m = new Method(methodName, Type.getReturnType(method), Type.getArgumentTypes(method));
				if (method.getDeclaringClass().isInterface())
					gen.invokeInterface(type, m);
				else
					gen.invokeVirtual(type, m);
				Class retClass = method.getReturnType();
				if (context == C.STATEMENT) {
					if (retClass == long.class || retClass == double.class)
						gen.pop2();
					else if (retClass != void.class)
						gen.pop();
				} else
					HostExpr.emitBoxReturn(objx, gen, retClass);
			} else {
				target.emit(C.EXPRESSION, objx, gen);
				gen.push(methodName);
				emitArgsAsArray(args, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				gen.invokeStatic(REFLECTOR_TYPE, invokeInstanceMethodMethod);
				if (context == C.STATEMENT)
					gen.pop();
			}
		}

		public boolean hasJavaClass() {
			return method != null || tag != null;
		}

		public Class getJavaClass() {
			if (jc == null)
				jc = retType((tag != null) ? HostExpr.tagToClass(tag) : null, (method != null) ? method.getReturnType() : null);
			return jc;
		}

	 */
}
