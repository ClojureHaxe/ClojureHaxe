package lang.compiler;

class FnExpr extends ObjExpr {
/*
    //if there is a variadic overload (there can only be one) it is stored here
    FnMethod variadicMethod = null;
    IPersistentCollection methods;
    private boolean hasPrimSigs;
    private boolean hasMeta;
    private boolean hasEnclosingMethod;
    //	String superName = null;
    Class jc;

    public FnExpr(Object tag) {
        super(tag);
    }

    public boolean hasJavaClass() {
        return true;
    }

    boolean supportsMeta() {
        return hasMeta;
    }

    public Class getJavaClass() {
        if (jc == null)
            jc = tag != null ? HostExpr.tagToClass(tag) : AFunction.class;
        return jc;
    }

    protected void emitMethods(ClassVisitor cv) {
        //override of invoke/doInvoke for each method
        for (ISeq s = RT.seq(methods); s != null; s = s.next()) {
            ObjMethod method = (ObjMethod) s.first();
            method.emit(this, cv);
        }

        if (isVariadic()) {
            GeneratorAdapter gen = new GeneratorAdapter(ACC_PUBLIC,
                    Method.getMethod("int getRequiredArity()"),
                    null,
                    null,
                    cv);
            gen.visitCode();
            gen.push(variadicMethod.reqParms.count());
            gen.returnValue();
            gen.endMethod();
        }
    }

    static Expr parse(C context, ISeq form, String name) {
        ISeq origForm = form;
        FnExpr fn = new FnExpr(tagOf(form));
        Keyword retkey = Keyword.intern(null, "rettag");
        Object rettag = RT.get(RT.meta(form), retkey);
        fn.src = form;
        ObjMethod enclosingMethod = (ObjMethod) METHOD.deref();
        fn.hasEnclosingMethod = enclosingMethod != null;
        if (((IMeta) form.first()).meta() != null) {
            fn.onceOnly = RT.booleanCast(RT.get(RT.meta(form.first()), Keyword.intern(null, "once")));
//			fn.superName = (String) RT.get(RT.meta(form.first()), Keyword.intern(null, "super-name"));
        }
        //fn.thisName = name;

        String basename = (enclosingMethod != null ?
                enclosingMethod.objx.name
                : (munge(currentNS().name.name))) + "$";

        Symbol nm = null;

        if (RT.second(form) instanceof Symbol) {
            nm = (Symbol) RT.second(form);
            name = nm.name + "__" + RT.nextID();
        } else {
            if (name == null)
                name = "fn__" + RT.nextID();
            else if (enclosingMethod != null)
                name += "__" + RT.nextID();
        }

        String simpleName = munge(name).replace(".", "_DOT_");

        fn.name = basename + simpleName;
        fn.internalName = fn.name.replace('.', '/');
        fn.objtype = Type.getObjectType(fn.internalName);
        ArrayList<String> prims = new ArrayList();
        try {
            Var.pushThreadBindings(
                    RT.mapUniqueKeys(CONSTANTS, PersistentVector.EMPTY,
                            CONSTANT_IDS, new IdentityHashMap(),
                            KEYWORDS, PersistentHashMap.EMPTY,
                            VARS, PersistentHashMap.EMPTY,
                            KEYWORD_CALLSITES, PersistentVector.EMPTY,
                            PROTOCOL_CALLSITES, PersistentVector.EMPTY,
                            VAR_CALLSITES, emptyVarCallSites(),
                            NO_RECUR, null
                    ));

            //arglist might be preceded by symbol naming this fn
            if (nm != null) {
                fn.thisName = nm.name;
                form = RT.cons(FN, RT.next(RT.next(form)));
            }

            //now (fn [args] body...) or (fn ([args] body...) ([args2] body2...) ...)
            //turn former into latter
            if (RT.second(form) instanceof IPersistentVector)
                form = RT.list(FN, RT.next(form));
            fn.line = lineDeref();
            fn.column = columnDeref();
            FnMethod[] methodArray = new FnMethod[MAX_POSITIONAL_ARITY + 1];
            FnMethod variadicMethod = null;
            boolean usesThis = false;
            for (ISeq s = RT.next(form); s != null; s = RT.next(s)) {
                FnMethod f = FnMethod.parse(fn, (ISeq) RT.first(s), rettag);
                if (f.usesThis) {
//					System.out.println(fn.name + " use this");
                    usesThis = true;
                }
                if (f.isVariadic()) {
                    if (variadicMethod == null)
                        variadicMethod = f;
                    else
                        throw Util.runtimeException("Can't have more than 1 variadic overload");
                } else if (methodArray[f.reqParms.count()] == null)
                    methodArray[f.reqParms.count()] = f;
                else
                    throw Util.runtimeException("Can't have 2 overloads with same arity");
                if (f.prim != null)
                    prims.add(f.prim);
            }
            if (variadicMethod != null) {
                for (int i = variadicMethod.reqParms.count() + 1; i <= MAX_POSITIONAL_ARITY; i++)
                    if (methodArray[i] != null)
                        throw Util.runtimeException(
                                "Can't have fixed arity function with more params than variadic function");
            }

            fn.canBeDirect = !fn.hasEnclosingMethod && fn.closes.count() == 0 && !usesThis;

            IPersistentCollection methods = null;
            for (int i = 0; i < methodArray.length; i++)
                if (methodArray[i] != null)
                    methods = RT.conj(methods, methodArray[i]);
            if (variadicMethod != null)
                methods = RT.conj(methods, variadicMethod);

            if (fn.canBeDirect) {
                for (FnMethod fm : (Collection<FnMethod>) methods) {
                    if (fm.locals != null) {
                        for (LocalBinding lb : (Collection<LocalBinding>) RT.keys(fm.locals)) {
                            if (lb.isArg)
                                lb.idx -= 1;
                        }
                    }
                }
            }

            fn.methods = methods;
            fn.variadicMethod = variadicMethod;
            fn.keywords = (IPersistentMap) KEYWORDS.deref();
            fn.vars = (IPersistentMap) VARS.deref();
            fn.constants = (PersistentVector) CONSTANTS.deref();
            fn.keywordCallsites = (IPersistentVector) KEYWORD_CALLSITES.deref();
            fn.protocolCallsites = (IPersistentVector) PROTOCOL_CALLSITES.deref();
            fn.varCallsites = (IPersistentSet) VAR_CALLSITES.deref();

            fn.constantsID = RT.nextID();
//			DynamicClassLoader loader = (DynamicClassLoader) LOADER.get();
//			loader.registerConstants(fn.constantsID, fn.constants.toArray());
        } finally {
            Var.popThreadBindings();
        }
        fn.hasPrimSigs = prims.size() > 0;
        IPersistentMap fmeta = RT.meta(origForm);
        if (fmeta != null)
            fmeta = fmeta.without(RT.LINE_KEY).without(RT.COLUMN_KEY).without(RT.FILE_KEY).without(retkey);

        fn.hasMeta = RT.count(fmeta) > 0;

        try {
            fn.compile(fn.isVariadic() ? "clojure/lang/RestFn" : "clojure/lang/AFunction",
                    (prims.size() == 0) ?
                            null
                            : prims.toArray(new String[prims.size()]),
                    fn.onceOnly);
        } catch (IOException e) {
            throw Util.sneakyThrow(e);
        }
        fn.getCompiledClass();

        if (fn.supportsMeta()) {
            //System.err.println(name + " supports meta");
            return new MetaExpr(fn, MapExpr
                    .parse(context == C.EVAL ? context : C.EXPRESSION, fmeta));
        } else
            return fn;
    }

    public final ObjMethod variadicMethod() {
        return variadicMethod;
    }

    boolean isVariadic() {
        return variadicMethod != null;
    }

    public final IPersistentCollection methods() {
        return methods;
    }

    public void emitForDefn(ObjExpr objx, GeneratorAdapter gen) {
//		if(!hasPrimSigs && closes.count() == 0)
//			{
//			Type thunkType = Type.getType(FnLoaderThunk.class);
////			presumes var on stack
//			gen.dup();
//			gen.newInstance(thunkType);
//			gen.dupX1();
//			gen.swap();
//			gen.push(internalName.replace('/','.'));
//			gen.invokeConstructor(thunkType,Method.getMethod("void <init>(clojure.lang.Var,String)"));
//			}
//		else
        emit(C.EXPRESSION, objx, gen);
    }

    */
}