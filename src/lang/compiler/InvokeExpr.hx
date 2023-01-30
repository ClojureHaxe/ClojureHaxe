package lang.compiler;

import haxe.Exception;
import lang.Compiler.C;

class InvokeExpr implements Expr {
	public var fexpr:Expr;
	public var tag:Any;
	public var args:IPersistentVector;
	public var line:Int;
	public var column:Int;
	public var tailPosition:Bool;
	public var source:String;
	public var isProtocol:Bool = false;
	public var isDirect:Bool = false;
	public var siteIndex:Int = -1;

	// public var Class protocolOn;
	// public var java.lang.reflect.Method onMethod;
	static var onKey:Keyword = Keyword.intern1("on");
	static var methodMapKey:Keyword = Keyword.intern1("method-map");

	// Class jc;

	static function sigTag(argcount:Int, v:Var):Any {
		var arglists:Any = RT.get(RT.meta(v), Compiler.arglistsKey);
		var sigTag:Any = null;
		var s:ISeq = RT.seq(arglists);
		while (s != null) {
			var sig:APersistentVector = s.first();
			var restOffset:Int = sig.indexOf(Compiler._AMP_);
			if (argcount == sig.count() || (restOffset > -1 && argcount >= restOffset))
				return Compiler.tagOf(sig);
			s = s.next();
		}
		return null;
	}

	public function new(source:String, line:Int, column:Int, tag:Symbol, fexpr:Expr, args:IPersistentVector, tailPosition:Bool) {
		this.source = source;
		this.fexpr = fexpr;
		this.args = args;
		this.line = line;
		this.column = column;
		this.tailPosition = tailPosition;

		/*
			if (fexpr instanceof VarExpr) {
				Var fvar = ((VarExpr) fexpr).var;
				Var pvar = (Var) RT.get(fvar.meta(), protocolKey);
				if (pvar != null && PROTOCOL_CALLSITES.isBound()) {
					this.isProtocol = true;
					this.siteIndex = registerProtocolCallsite(((VarExpr) fexpr).var);
					Object pon = RT.get(pvar.get(), onKey);
					this.protocolOn = HostExpr.maybeClass(pon, false);
					if (this.protocolOn != null) {
						IPersistentMap mmap = (IPersistentMap) RT.get(pvar.get(), methodMapKey);
						Keyword mmapVal = (Keyword) mmap.valAt(Keyword.intern(fvar.sym));
						if (mmapVal == null) {
							throw new IllegalArgumentException(
									"No method of interface: " + protocolOn.getName() +
											" found for function: " + fvar.sym + " of protocol: " + pvar.sym +
											" (The protocol method may have been defined before and removed.)");
						}
						String mname = munge(mmapVal.sym.toString());
						List methods = Reflector.getMethods(protocolOn, args.count() - 1, mname, false);
						if (methods.size() != 1)
							throw new IllegalArgumentException(
									"No single method: " + mname + " of interface: " + protocolOn.getName() +
											" found for function: " + fvar.sym + " of protocol: " + pvar.sym);
						this.onMethod = (java.lang.reflect.Method) methods.get(0);
					}
				}
			}
		 */
		if (tag != null) {
			this.tag = tag;
		} else if (U.instanceof(fexpr, VarExpr)) {
			var v:Var = cast(fexpr, VarExpr).varr;
			var arglists:Any = RT.get(RT.meta(v), Compiler.arglistsKey);
			var sigTag:Any = sigTag(args.count(), v);
			this.tag = sigTag == null ? cast(fexpr, VarExpr).tag : sigTag;
		} else {
			this.tag = null;
		}
	}

	public function eval():Any {
		try {
			var fn:IFn = fexpr.eval();
			var argvs:PersistentVector = PersistentVector.EMPTY;
			var i:Int = 0;
			while (i < args.count()) {
				argvs = argvs.cons((args.nth(i) : Expr).eval());
				i++;
			}
			return fn.applyTo(RT.seq(Util.ret1(argvs, argvs = null)));
		} catch (e:Exception) {
			if (!(U.instanceof(e, CompilerException)))
				throw new CompilerException(source, line, column, null, CompilerException.PHASE_EXECUTION, e);
			else
				throw e;
		}
	}
	/*

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (isProtocol) {
				gen.visitLineNumber(line, gen.mark());
				emitProto(context, objx, gen);
			} else {
				fexpr.emit(C.EXPRESSION, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				gen.checkCast(IFN_TYPE);
				emitArgsAndCall(0, context, objx, gen);
			}
			if (context == C.STATEMENT)
				gen.pop();
		}

		public void emitProto(C context, ObjExpr objx, GeneratorAdapter gen) {
			Label onLabel = gen.newLabel();
			Label callLabel = gen.newLabel();
			Label endLabel = gen.newLabel();

			Var v = ((VarExpr) fexpr).var;

			Expr e = (Expr) args.nth(0);
			e.emit(C.EXPRESSION, objx, gen);
			gen.dup(); //target, target
			gen.invokeStatic(UTIL_TYPE, Method.getMethod("Class classOf(Object)")); //target,class
			gen.getStatic(objx.objtype, objx.cachedClassName(siteIndex), CLASS_TYPE); //target,class,cached-class
			gen.visitJumpInsn(IF_ACMPEQ, callLabel); //target
			if (protocolOn != null) {
				gen.dup(); //target, target
				gen.instanceOf(Type.getType(protocolOn));
				gen.ifZCmp(GeneratorAdapter.NE, onLabel);
			}

			gen.dup(); //target, target
			gen.invokeStatic(UTIL_TYPE, Method.getMethod("Class classOf(Object)")); //target,class
			gen.putStatic(objx.objtype, objx.cachedClassName(siteIndex), CLASS_TYPE); //target

			gen.mark(callLabel); //target
			objx.emitVar(gen, v);
			gen.invokeVirtual(VAR_TYPE, Method.getMethod("Object getRawRoot()")); //target, proto-fn
			gen.swap();
			emitArgsAndCall(1, context, objx, gen);
			gen.goTo(endLabel);

			gen.mark(onLabel); //target
			if (protocolOn != null) {
				gen.checkCast(Type.getType(protocolOn));
				MethodExpr.emitTypedArgs(objx, gen, onMethod.getParameterTypes(), RT.subvec(args, 1, args.count()));
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				Method m = new Method(onMethod.getName(), Type.getReturnType(onMethod), Type.getArgumentTypes(onMethod));
				gen.invokeInterface(Type.getType(protocolOn), m);
				HostExpr.emitBoxReturn(objx, gen, onMethod.getReturnType());
			}
			gen.mark(endLabel);
		}

		void emitArgsAndCall(int firstArgToEmit, C context, ObjExpr objx, GeneratorAdapter gen) {
			for (int i = firstArgToEmit; i < Math.min(MAX_POSITIONAL_ARITY, args.count()); i++) {
				Expr e = (Expr) args.nth(i);
				e.emit(C.EXPRESSION, objx, gen);
			}
			if (args.count() > MAX_POSITIONAL_ARITY) {
				PersistentVector restArgs = PersistentVector.EMPTY;
				for (int i = MAX_POSITIONAL_ARITY; i < args.count(); i++) {
					restArgs = restArgs.cons(args.nth(i));
				}
				MethodExpr.emitArgsAsArray(restArgs, objx, gen);
			}
			gen.visitLineNumber(line, gen.mark());

			if (tailPosition && !objx.canBeDirect) {
				ObjMethod method = (ObjMethod) METHOD.deref();
				method.emitClearThis(gen);
			}

			gen.invokeInterface(IFN_TYPE, new Method("invoke", OBJECT_TYPE, ARG_TYPES[Math.min(MAX_POSITIONAL_ARITY + 1,
					args.count())]));
		}

		public boolean hasJavaClass() {
			return tag != null;
		}

		public Class getJavaClass() {
			if (jc == null)
				jc = HostExpr.tagToClass(tag);
			return jc;
		}
	 */
	/*
		static public function parse(context:C, form:ISeq):Expr {
			var tailPosition:Bool = Compiler.inTailCall(context);
			if (context != C.EVAL)
				context = C.EXPRESSION;
			var fexpr:Expr = Compiler.analyze(context, form.first());
			if (U.instanceof(fexpr, VarExpr) && (fexpr : VarExpr).varr.equals(Compiler.INSTANCE) && RT.count(form) == 3) {
				var sexpr:Expr = Compiler.analyze(C.EXPRESSION, RT.second(form));
				if (U.instanceof(sexpr, ConstantExpr)) {
					var val:Any = ((sexpr : ConstantExpr)).val();
					if (U.instanceof(val, Class<Any>)) {
						return new InstanceOfExpr(val, analyze(context, RT.third(form)));
					}
				}
			}

			if (RT.booleanCast(Compiler.getCompilerOption(Compiler.directLinkingKey)) && U.instanceof(fexpr, VarExpr) && context != C.EVAL) {
				var v:Var = ((fexpr : VarExpr)).varr;
				if (!v.isDynamic() && !RT.booleanCast(RT.get(v.meta(), Compiler.redefKey, false))) {
					var formtag:Symbol = Compiler.tagOf(form);
					var arglists:Any = RT.get(RT.meta(v), Compiler.arglistsKey);
					var arity:Int = RT.count(form.next());
					var sigtag:Any = sigTag(arity, v);
					var vtag:Any = RT.get(RT.meta(v), RT.TAG_KEY);
					var ret:Expr = StaticInvokeExpr.parse(v, RT.next(form), formtag != null ? formtag : (sigtag != null ? sigtag : vtag), tailPosition);
					if (ret != null) {
						return ret;
					}
				}
			}

			if (U.instanceof(fexpr, VarExpr) && context != C.EVAL) {
				var v:Var = ((fexpr : VarExpr)).varr;
				var arglists:Any = RT.get(RT.meta(v), Compiler.arglistsKey);
				var arity:Int = RT.count(form.next());
				var s:ISeq = RT.seq(arglists);
				while (s != null) {
					var args:IPersistentVector = s.first();
					if (args.count() == arity) {
						var primc:String = FnMethod.primInterface(args);
						if (primc != null)
							return Compiler.analyze(context,
								(RT.listStar(Symbol.intern1(".invokePrim"), ((form : Symbol).first()).withMeta(RT.map(RT.TAG_KEY, Symbol.intern1(primc))),
									form.next()) : IObj).withMeta((RT.conj(RT.meta(v), RT.meta(form)) : IPersistentMap)));
						break;
					}
					s = s.next();
				}
			}

			if (U.instanceof(fexpr, KeywordExpr) && RT.count(form) == 2 && Compiler.KEYWORD_CALLSITES.isBound()) {
				var target:Expr = Compiler.analyze(context, RT.second(form));
				return new KeywordInvokeExpr(SOURCE.deref(), lineDeref(), columnDeref(), tagOf(form), fexpr, target);
			}
			var args:PersistentVector = PersistentVector.EMPTY;
			var s:ISeq = RT.seq(form.next());
			while (s != null) {
				args = args.cons(Compiler.analyze(context, s.first()));
				s = s.next();
			}

			return new InvokeExpr(Compiler.SOURCE.deref(), Compiler.lineDeref(), Compiler.columnDeref(), Compiler.tagOf(form), fexpr, args, tailPosition);
		}
	 */
}
