package lang.compiler.host;

import haxe.ds.Vector;
import lang.Compiler.C;
import lang.exceptions.IllegalArgumentException;

class NewExpr implements Expr {
	public var args:IPersistentVector;
	// public final Constructor ctor;
	public var c:Class<Dynamic>;

	//  final static Method invokeConstructorMethod =            Method.getMethod("Object invokeConstructor(Class,Object[])");
	//  final static Method forNameMethod = Method.getMethod("Class classForName(String)");

	public function new(c:Class<Dynamic>, args:IPersistentVector, line:Int, column:Int) {
		this.args = args;
		this.c = c;
		/* Constructor[] allctors = c.getConstructors();
			ArrayList ctors = new ArrayList();
			ArrayList<Class[]> params = new ArrayList();
			ArrayList<Class> rets = new ArrayList();
			for (int i = 0; i < allctors.length; i++) {
				Constructor ctor = allctors[i];
				if (ctor.getParameterTypes().length == args.count()) {
					ctors.add(ctor);
					params.add(ctor.getParameterTypes());
					rets.add(c);
				}
			}
			if (ctors.isEmpty())
				throw new IllegalArgumentException("No matching ctor found for " + c);

			int ctoridx = 0;
			if (ctors.size() > 1) {
				ctoridx = getMatchingParams(c.getName(), params, args, rets);
			}

			this.ctor = ctoridx >= 0 ? (Constructor) ctors.get(ctoridx) : null;
			if (ctor == null && RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
				RT.errPrintWriter()
						.format("Reflection warning, %s:%d:%d - call to %s ctor can't be resolved.\n",
								SOURCE_PATH.deref(), line, column, c.getName());
		}*/
	}

	public function eval():Any {
		/* Object[] argvals = new Object[args.count()];
			for (int i = 0; i < args.count(); i++)
				argvals[i] = ((Expr) args.nth(i)).eval();
			if (this.ctor != null) {
				try {
					return ctor.newInstance(Reflector.boxArgs(ctor.getParameterTypes(), argvals));
				} catch (Exception e) {
					throw Util.sneakyThrow(e);
				}
		}*/
		var argvals:Vector<Any> = new Vector<Any>(args.count());
		var i:Int = 0;
		while (i < args.count()) {
			argvals[i] = (args.nth(i) : Expr).eval();
			i++;
		}
		return Reflector.invokeConstructor(c, argvals);
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (this.ctor != null) {
				Type type = getType(c);
				gen.newInstance(type);
				gen.dup();
				MethodExpr.emitTypedArgs(objx, gen, ctor.getParameterTypes(), args);
				gen.invokeConstructor(type, new Method("<init>", Type.getConstructorDescriptor(ctor)));
			} else {
				gen.push(destubClassName(c.getName()));
				gen.invokeStatic(RT_TYPE, forNameMethod);
				MethodExpr.emitArgsAsArray(args, objx, gen);
				gen.invokeStatic(REFLECTOR_TYPE, invokeConstructorMethod);
			}
			if (context == C.STATEMENT)
				gen.pop();
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return c;
		}
	 */
}

class NewExprParser implements IParser {
	public function new() {}

	public function parse(context:C, frm:Any):Expr {
		var line:Int = Compiler.lineDeref();
		var column:Int = Compiler.columnDeref();
		var form:ISeq = frm;
		// (new Classname args...)
		if (form.count() < 2)
			throw Util.runtimeException("wrong number of arguments, expecting: (new Classname args...)");
		var c:Class<Dynamic> = HostExpr.maybeClass(RT.second(form), false);
        trace(",,,,,,,,,,,,,,,,,,,,,,,,,,, NewExprParser " + c);
		if (c == null)
			throw new IllegalArgumentException("Unable to resolve classname: " + RT.second(form));
		var args:PersistentVector = PersistentVector.EMPTY;
		var s:ISeq = RT.next(RT.next(form));
		while (s != null) {
			args = args.cons(Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, s.first()));
			s = s.next();
		}
		return new NewExpr(c, args, line, column);
	}
}
