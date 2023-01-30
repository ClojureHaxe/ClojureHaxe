package lang.compiler;

class ObjExpr 
//implements Expr 
{
    /*
    static final  CONST_PREFIX:String = "const__";
    var name:String;
    var internalName:String;
    var thisName:String;
    var objtype:Type;
    public var tag:Any;
    //localbinding->itself
    var closes:IPersistentMap = PersistentHashMap.EMPTY;
    //localbndingexprs
    var closesExprs:IPersistentVector = PersistentVector.EMPTY;
    //symbols
    var volatiles:IPersistentSet = PersistentHashSet.EMPTY;

    //symbol->lb
    var fields:IPersistentMap = null;

    //hinted fields
    var hintedFields:IPersistentVector = PersistentVector.EMPTY;

    //Keyword->KeywordExpr
    var keywords:IPersistentMap = PersistentHashMap.EMPTY;
    var vars:IPersistentMap = PersistentHashMap.EMPTY;
   // Class compiledClass;
    var line:Int;
    var column:Int;
    var constants:PersistentVector;
    var usedConstants:IPersistentSet = PersistentHashSet.EMPTY;

    var constantsID:Int;
    var altCtorDrops:Int = 0;

    var keywordCallsites:IPersistentVector;
    var protocolCallsites:IPersistentVector;
    var varCallsites:IPersistentSet;
    var onceOnly:Bool = false;

    var src:Any;

    var opts:IPersistentMap = PersistentHashMap.EMPTY;

    //final static Method voidctor = Method.getMethod("void <init>()");
    var  classMeta:IPersistentMap;
    var  canBeDirect:Bool;

    public function  name():String {
        return name;
    }


    public final function internalName():String {
        return internalName;
    }

    public final function thisName():String {
        return thisName;
    }

    public final function objtype():Type {
        return objtype;
    }

    public final function closes():IPersistentMap {
        return closes;
    }

    public final function keywords():IPersistentMap {
        return keywords;
    }

    public final function vars():IPersistentMap {
        return vars;
    }

    // public final Class compiledClass() {
    //     return compiledClass;
    // }

    public final function line():Int {
        return line;
    }

    public final function column():Int {
        return column;
    }

    public final function constants():PersistentVector {
        return constants;
    }

    public final function constantsID():Int {
        return constantsID;
    }

    // final static Method kwintern = Method.getMethod("clojure.lang.Keyword intern(String, String)");
    // final static Method symintern = Method.getMethod("clojure.lang.Symbol intern(String)");
    // final static Method varintern =
    //         Method.getMethod("clojure.lang.Var intern(clojure.lang.Symbol, clojure.lang.Symbol)");

    // final static Type DYNAMIC_CLASSLOADER_TYPE = Type.getType(DynamicClassLoader.class);
    // final static Method getClassMethod = Method.getMethod("Class getClass()");
    // final static Method getClassLoaderMethod = Method.getMethod("ClassLoader getClassLoader()");
    // final static Method getConstantsMethod = Method.getMethod("Object[] getConstants(int)");
    // final static Method readStringMethod = Method.getMethod("Object readString(String)");

    // final static Type ILOOKUP_SITE_TYPE = Type.getType(ILookupSite.class);
    // final static Type ILOOKUP_THUNK_TYPE = Type.getType(ILookupThunk.class);
    // final static Type KEYWORD_LOOKUPSITE_TYPE = Type.getType(KeywordLookupSite.class);

    private DynamicClassLoader loader;
    private byte[] bytecode;

    public function new(tag:Any) {
        this.tag = tag;
    }

    static function trimGenID( name:String):String {
        var i:Int = name.lastIndexOf("__");
        return i == -1 ? name : name.substring(0, i);
    }


    Type[] ctorTypes() {
        IPersistentVector tv = !supportsMeta() ? PersistentVector.EMPTY : RT.vector(IPERSISTENTMAP_TYPE);
        for (ISeq s = RT.keys(closes); s != null; s = s.next()) {
            LocalBinding lb = (LocalBinding) s.first();
            if (lb.getPrimitiveType() != null)
                tv = tv.cons(Type.getType(lb.getPrimitiveType()));
            else
                tv = tv.cons(OBJECT_TYPE);
        }
        Type[] ret = new Type[tv.count()];
        for (int i = 0; i < tv.count(); i++)
            ret[i] = (Type) tv.nth(i);
        return ret;
    }

    void compile(String superName, String[] interfaceNames, boolean oneTimeUse) throws IOException {
        ClassWriter cw = classWriter();
        ClassVisitor cv = cw;
        cv.visit(V1_8, ACC_PUBLIC + ACC_SUPER + ACC_FINAL, internalName, null, superName, interfaceNames);
        String source = (String) SOURCE.deref();
        int lineBefore = (Integer) LINE_BEFORE.deref();
        int lineAfter = (Integer) LINE_AFTER.deref() + 1;
        int columnBefore = (Integer) COLUMN_BEFORE.deref();
        int columnAfter = (Integer) COLUMN_AFTER.deref() + 1;

        if (source != null && SOURCE_PATH.deref() != null) {

            String smap = "SMAP\n" +
                    ((source.lastIndexOf('.') > 0) ?
                            source.substring(0, source.lastIndexOf('.'))
                            : source)
                    + ".java\n" +
                    "Clojure\n" +
                    "*S Clojure\n" +
                    "*F\n" +
                    "+ 1 " + source + "\n" +
                    (String) SOURCE_PATH.deref() + "\n" +
                    "*L\n" +
                    String.format("%d#1,%d:%d\n", lineBefore, lineAfter - lineBefore, lineBefore) +
                    "*E";
            cv.visitSource(source, smap);
        }
        addAnnotation(cv, classMeta);



        if (supportsMeta()) {
            cv.visitField(ACC_FINAL, "__meta", IPERSISTENTMAP_TYPE.getDescriptor(), null, null);
        }
        //instance fields for closed-overs
        for (ISeq s = RT.keys(closes); s != null; s = s.next()) {
            LocalBinding lb = (LocalBinding) s.first();
            if (isDeftype()) {
                int access = isVolatile(lb) ? ACC_VOLATILE :
                        isMutable(lb) ? 0 :
                                (ACC_PUBLIC + ACC_FINAL);
                FieldVisitor fv;
                if (lb.getPrimitiveType() != null)
                    fv = cv.visitField(access
                            , lb.name, Type.getType(lb.getPrimitiveType()).getDescriptor(),
                            null, null);
                else
                    //todo - when closed-overs are fields, use more specific types here and in ctor and emitLocal?
                    fv = cv.visitField(access
                            , lb.name, OBJECT_TYPE.getDescriptor(), null, null);
                addAnnotation(fv, RT.meta(lb.sym));
            } else {
                //todo - only enable this non-private+writability for letfns where we need it
                if (lb.getPrimitiveType() != null)
                    cv.visitField(0 + (isVolatile(lb) ? ACC_VOLATILE : 0)
                            , lb.name, Type.getType(lb.getPrimitiveType()).getDescriptor(),
                            null, null);
                else
                    cv.visitField(0 //+ (oneTimeUse ? 0 : ACC_FINAL)
                            , lb.name, OBJECT_TYPE.getDescriptor(), null, null);
            }
        }

        //static fields for callsites and thunks
        for (int i = 0; i < protocolCallsites.count(); i++) {
            cv.visitField(ACC_PRIVATE + ACC_STATIC, cachedClassName(i), CLASS_TYPE.getDescriptor(), null, null);
        }

        //ctor that takes closed-overs and inits base + fields
        Method m = new Method("<init>", Type.VOID_TYPE, ctorTypes());
        GeneratorAdapter ctorgen = new GeneratorAdapter(ACC_PUBLIC,
                m,
                null,
                null,
                cv);
        Label start = ctorgen.newLabel();
        Label end = ctorgen.newLabel();
        ctorgen.visitCode();
        ctorgen.visitLineNumber(line, ctorgen.mark());
        ctorgen.visitLabel(start);
        ctorgen.loadThis();
//		if(superName != null)
        ctorgen.invokeConstructor(Type.getObjectType(superName), voidctor);
//		else if(isVariadic()) //RestFn ctor takes reqArity arg
//			{
//			ctorgen.push(variadicMethod.reqParms.count());
//			ctorgen.invokeConstructor(restFnType, restfnctor);
//			}
//		else
//			ctorgen.invokeConstructor(aFnType, voidctor);

//		if(vars.count() > 0)
//			{
//			ctorgen.loadThis();
//			ctorgen.getStatic(VAR_TYPE,"rev",Type.INT_TYPE);
//			ctorgen.push(-1);
//			ctorgen.visitInsn(Opcodes.IADD);
//			ctorgen.putField(objtype, "__varrev__", Type.INT_TYPE);
//			}

        if (supportsMeta()) {
            ctorgen.loadThis();
            ctorgen.visitVarInsn(IPERSISTENTMAP_TYPE.getOpcode(Opcodes.ILOAD), 1);
            ctorgen.putField(objtype, "__meta", IPERSISTENTMAP_TYPE);
        }

        int a = supportsMeta() ? 2 : 1;
        for (ISeq s = RT.keys(closes); s != null; s = s.next(), ++a) {
            LocalBinding lb = (LocalBinding) s.first();
            ctorgen.loadThis();
            Class primc = lb.getPrimitiveType();
            if (primc != null) {
                ctorgen.visitVarInsn(Type.getType(primc).getOpcode(Opcodes.ILOAD), a);
                ctorgen.putField(objtype, lb.name, Type.getType(primc));
                if (primc == Long.TYPE || primc == Double.TYPE)
                    ++a;
            } else {
                ctorgen.visitVarInsn(OBJECT_TYPE.getOpcode(Opcodes.ILOAD), a);
                ctorgen.putField(objtype, lb.name, OBJECT_TYPE);
            }
            closesExprs = closesExprs.cons(new LocalBindingExpr(lb, null));
        }


        ctorgen.visitLabel(end);

        ctorgen.returnValue();

        ctorgen.endMethod();

        if (altCtorDrops > 0) {
            //ctor that takes closed-overs and inits base + fields
            Type[] ctorTypes = ctorTypes();
            Type[] altCtorTypes = new Type[ctorTypes.length - altCtorDrops];
            for (int i = 0; i < altCtorTypes.length; i++)
                altCtorTypes[i] = ctorTypes[i];
            Method alt = new Method("<init>", Type.VOID_TYPE, altCtorTypes);
            ctorgen = new GeneratorAdapter(ACC_PUBLIC,
                    alt,
                    null,
                    null,
                    cv);
            ctorgen.visitCode();
            ctorgen.loadThis();
            ctorgen.loadArgs();

            ctorgen.visitInsn(Opcodes.ACONST_NULL); //__meta
            ctorgen.visitInsn(Opcodes.ACONST_NULL); //__extmap
            ctorgen.visitInsn(Opcodes.ICONST_0); //__hash
            ctorgen.visitInsn(Opcodes.ICONST_0); //__hasheq

            ctorgen.invokeConstructor(objtype, new Method("<init>", Type.VOID_TYPE, ctorTypes));

            ctorgen.returnValue();
            ctorgen.endMethod();

            // alt ctor no __hash, __hasheq
            altCtorTypes = new Type[ctorTypes.length - 2];
            for (int i = 0; i < altCtorTypes.length; i++)
                altCtorTypes[i] = ctorTypes[i];

            alt = new Method("<init>", Type.VOID_TYPE, altCtorTypes);
            ctorgen = new GeneratorAdapter(ACC_PUBLIC,
                    alt,
                    null,
                    null,
                    cv);
            ctorgen.visitCode();
            ctorgen.loadThis();
            ctorgen.loadArgs();

            ctorgen.visitInsn(Opcodes.ICONST_0); //__hash
            ctorgen.visitInsn(Opcodes.ICONST_0); //__hasheq

            ctorgen.invokeConstructor(objtype, new Method("<init>", Type.VOID_TYPE, ctorTypes));

            ctorgen.returnValue();
            ctorgen.endMethod();
        }

        if (supportsMeta()) {
            //ctor that takes closed-overs but not meta
            Type[] ctorTypes = ctorTypes();
            Type[] noMetaCtorTypes = new Type[ctorTypes.length - 1];
            for (int i = 1; i < ctorTypes.length; i++)
                noMetaCtorTypes[i - 1] = ctorTypes[i];
            Method alt = new Method("<init>", Type.VOID_TYPE, noMetaCtorTypes);
            ctorgen = new GeneratorAdapter(ACC_PUBLIC,
                    alt,
                    null,
                    null,
                    cv);
            ctorgen.visitCode();
            ctorgen.loadThis();
            ctorgen.visitInsn(Opcodes.ACONST_NULL);    //null meta
            ctorgen.loadArgs();
            ctorgen.invokeConstructor(objtype, new Method("<init>", Type.VOID_TYPE, ctorTypes));

            ctorgen.returnValue();
            ctorgen.endMethod();

            //meta()
            Method meth = Method.getMethod("clojure.lang.IPersistentMap meta()");

            GeneratorAdapter gen = new GeneratorAdapter(ACC_PUBLIC,
                    meth,
                    null,
                    null,
                    cv);
            gen.visitCode();
            gen.loadThis();
            gen.getField(objtype, "__meta", IPERSISTENTMAP_TYPE);

            gen.returnValue();
            gen.endMethod();

            //withMeta()
            meth = Method.getMethod("clojure.lang.IObj withMeta(clojure.lang.IPersistentMap)");

            gen = new GeneratorAdapter(ACC_PUBLIC,
                    meth,
                    null,
                    null,
                    cv);
            gen.visitCode();
            gen.newInstance(objtype);
            gen.dup();
            gen.loadArg(0);

            for (ISeq s = RT.keys(closes); s != null; s = s.next(), ++a) {
                LocalBinding lb = (LocalBinding) s.first();
                gen.loadThis();
                Class primc = lb.getPrimitiveType();
                if (primc != null) {
                    gen.getField(objtype, lb.name, Type.getType(primc));
                } else {
                    gen.getField(objtype, lb.name, OBJECT_TYPE);
                }
            }

            gen.invokeConstructor(objtype, new Method("<init>", Type.VOID_TYPE, ctorTypes));
            gen.returnValue();
            gen.endMethod();
        }

        emitStatics(cv);
        emitMethods(cv);

        //static fields for constants
        for (int i = 0; i < constants.count(); i++) {
            if (usedConstants.contains(i))
                cv.visitField(ACC_PUBLIC + ACC_FINAL
                                + ACC_STATIC, constantName(i), constantType(i).getDescriptor(),
                        null, null);
        }

        //static fields for lookup sites
        for (int i = 0; i < keywordCallsites.count(); i++) {
            cv.visitField(ACC_FINAL
                            + ACC_STATIC, siteNameStatic(i), KEYWORD_LOOKUPSITE_TYPE.getDescriptor(),
                    null, null);
            cv.visitField(ACC_STATIC, thunkNameStatic(i), ILOOKUP_THUNK_TYPE.getDescriptor(),
                    null, null);
        }

        //static init for constants, keywords and vars
        GeneratorAdapter clinitgen = new GeneratorAdapter(ACC_PUBLIC + ACC_STATIC,
                Method.getMethod("void <clinit> ()"),
                null,
                null,
                cv);
        clinitgen.visitCode();
        clinitgen.visitLineNumber(line, clinitgen.mark());

        if (constants.count() > 0) {
            emitConstants(clinitgen);
        }

        if (keywordCallsites.count() > 0)
            emitKeywordCallsites(clinitgen);



        if (isDeftype() && RT.booleanCast(RT.get(opts, loadNs))) {
            String nsname = ((Symbol) RT.second(src)).getNamespace();
            if (!nsname.equals("clojure.core")) {
                clinitgen.push("clojure.core");
                clinitgen.push("require");
                clinitgen.invokeStatic(RT_TYPE, Method.getMethod("clojure.lang.Var var(String,String)"));
                clinitgen.invokeVirtual(VAR_TYPE, Method.getMethod("Object getRawRoot()"));
                clinitgen.checkCast(IFN_TYPE);
                clinitgen.push(nsname);
                clinitgen.invokeStatic(SYMBOL_TYPE, Method.getMethod("clojure.lang.Symbol create(String)"));
                clinitgen.invokeInterface(IFN_TYPE, Method.getMethod("Object invoke(Object)"));
                clinitgen.pop();
            }
        }

        clinitgen.returnValue();

        clinitgen.endMethod();

        //end of class
        cv.visitEnd();

        bytecode = cw.toByteArray();
        if (RT.booleanCast(COMPILE_FILES.deref()))
            writeClassFile(internalName, bytecode);
//		else
//			getCompiledClass();
    }

    private void emitKeywordCallsites(GeneratorAdapter clinitgen) {
        for (int i = 0; i < keywordCallsites.count(); i++) {
            Keyword k = (Keyword) keywordCallsites.nth(i);
            clinitgen.newInstance(KEYWORD_LOOKUPSITE_TYPE);
            clinitgen.dup();
            emitValue(k, clinitgen);
            clinitgen.invokeConstructor(KEYWORD_LOOKUPSITE_TYPE,
                    Method.getMethod("void <init>(clojure.lang.Keyword)"));
            clinitgen.dup();
            clinitgen.putStatic(objtype, siteNameStatic(i), KEYWORD_LOOKUPSITE_TYPE);
            clinitgen.putStatic(objtype, thunkNameStatic(i), ILOOKUP_THUNK_TYPE);
        }
    }

    protected void emitStatics(ClassVisitor gen) {
    }

    protected void emitMethods(ClassVisitor gen) {
    }

    void emitListAsObjectArray(Object value, GeneratorAdapter gen) {
        gen.push(((List) value).size());
        gen.newArray(OBJECT_TYPE);
        int i = 0;
        for (Iterator it = ((List) value).iterator(); it.hasNext(); i++) {
            gen.dup();
            gen.push(i);
            emitValue(it.next(), gen);
            gen.arrayStore(OBJECT_TYPE);
        }
    }

    void emitValue(Object value, GeneratorAdapter gen) {
        boolean partial = true;
        //System.out.println(value.getClass().toString());

        if (value == null)
            gen.visitInsn(Opcodes.ACONST_NULL);
        else if (value instanceof String) {
            gen.push((String) value);
        } else if (value instanceof Boolean) {
            if (((Boolean) value).booleanValue())
                gen.getStatic(BOOLEAN_OBJECT_TYPE, "TRUE", BOOLEAN_OBJECT_TYPE);
            else
                gen.getStatic(BOOLEAN_OBJECT_TYPE, "FALSE", BOOLEAN_OBJECT_TYPE);
        } else if (value instanceof Integer) {
            gen.push(((Integer) value).intValue());
            gen.invokeStatic(Type.getType(Integer.class), Method.getMethod("Integer valueOf(int)"));
        } else if (value instanceof Long) {
            gen.push(((Long) value).longValue());
            gen.invokeStatic(Type.getType(Long.class), Method.getMethod("Long valueOf(long)"));
        } else if (value instanceof Double) {
            gen.push(((Double) value).doubleValue());
            gen.invokeStatic(Type.getType(Double.class), Method.getMethod("Double valueOf(double)"));
        } else if (value instanceof Character) {
            gen.push(((Character) value).charValue());
            gen.invokeStatic(Type.getType(Character.class), Method.getMethod("Character valueOf(char)"));
        } else if (value instanceof Class) {
            Class cc = (Class) value;
            if (cc.isPrimitive()) {
                Type bt;
                if (cc == boolean.class) bt = Type.getType(Boolean.class);
                else if (cc == byte.class) bt = Type.getType(Byte.class);
                else if (cc == char.class) bt = Type.getType(Character.class);
                else if (cc == double.class) bt = Type.getType(Double.class);
                else if (cc == float.class) bt = Type.getType(Float.class);
                else if (cc == int.class) bt = Type.getType(Integer.class);
                else if (cc == long.class) bt = Type.getType(Long.class);
                else if (cc == short.class) bt = Type.getType(Short.class);
                else throw Util.runtimeException(
                            "Can't embed unknown primitive in code: " + value);
                gen.getStatic(bt, "TYPE", Type.getType(Class.class));
            } else {
                gen.push(destubClassName(cc.getName()));
                gen.invokeStatic(RT_TYPE, Method.getMethod("Class classForName(String)"));
            }
        } else if (value instanceof Symbol) {
            gen.push(((Symbol) value).ns);
            gen.push(((Symbol) value).name);
            gen.invokeStatic(Type.getType(Symbol.class),
                    Method.getMethod("clojure.lang.Symbol intern(String,String)"));
        } else if (value instanceof Keyword) {
            gen.push(((Keyword) value).sym.ns);
            gen.push(((Keyword) value).sym.name);
            gen.invokeStatic(RT_TYPE,
                    Method.getMethod("clojure.lang.Keyword keyword(String,String)"));
        }
//						else if(value instanceof KeywordCallSite)
//								{
//								emitValue(((KeywordCallSite) value).k.sym, gen);
//								gen.invokeStatic(Type.getType(KeywordCallSite.class),
//								                 Method.getMethod("clojure.lang.KeywordCallSite create(clojure.lang.Symbol)"));
//								}
        else if (value instanceof Var) {
            Var var = (Var) value;
            gen.push(var.ns.name.toString());
            gen.push(var.sym.toString());
            gen.invokeStatic(RT_TYPE, Method.getMethod("clojure.lang.Var var(String,String)"));
        } else if (value instanceof IType) {
            Method ctor = new Method("<init>", Type.getConstructorDescriptor(value.getClass().getConstructors()[0]));
            gen.newInstance(Type.getType(value.getClass()));
            gen.dup();
            IPersistentVector fields = (IPersistentVector) Reflector.invokeStaticMethod(value.getClass(), "getBasis", new Object[]{});
            for (ISeq s = RT.seq(fields); s != null; s = s.next()) {
                Symbol field = (Symbol) s.first();
                Class k = tagClass(tagOf(field));
                Object val = Reflector.getInstanceField(value, munge(field.name));
                emitValue(val, gen);

                if (k.isPrimitive()) {
                    Type b = Type.getType(boxClass(k));
                    String p = Type.getType(k).getDescriptor();
                    String n = k.getName();

                    gen.invokeVirtual(b, new Method(n + "Value", "()" + p));
                }
            }
            gen.invokeConstructor(Type.getType(value.getClass()), ctor);
        } else if (value instanceof IRecord) {
            Method createMethod = Method.getMethod(value.getClass().getName() + " create(clojure.lang.IPersistentMap)");
            emitValue(PersistentArrayMap.create((java.util.Map) value), gen);
            gen.invokeStatic(getType(value.getClass()), createMethod);
        } else if (value instanceof IPersistentMap) {
            List entries = new ArrayList();
            for (Map.Entry entry : (Set<Map.Entry>) ((Map) value).entrySet()) {
                entries.add(entry.getKey());
                entries.add(entry.getValue());
            }
            emitListAsObjectArray(entries, gen);
            gen.invokeStatic(RT_TYPE,
                    Method.getMethod("clojure.lang.IPersistentMap map(Object[])"));
        } else if (value instanceof IPersistentVector) {
            IPersistentVector args = (IPersistentVector) value;
            if (args.count() <= Tuple.MAX_SIZE) {
                for (int i = 0; i < args.count(); i++) {
                    emitValue(args.nth(i), gen);
                }
                gen.invokeStatic(TUPLE_TYPE, createTupleMethods[args.count()]);
            } else {
                emitListAsObjectArray(value, gen);
                gen.invokeStatic(RT_TYPE, Method.getMethod(
                        "clojure.lang.IPersistentVector vector(Object[])"));
            }
        } else if (value instanceof PersistentHashSet) {
            ISeq vs = RT.seq(value);
            if (vs == null)
                gen.getStatic(Type.getType(PersistentHashSet.class), "EMPTY", Type.getType(PersistentHashSet.class));
            else {
                emitListAsObjectArray(vs, gen);
                gen.invokeStatic(Type.getType(PersistentHashSet.class), Method.getMethod(
                        "clojure.lang.PersistentHashSet create(Object[])"));
            }
        } else if (value instanceof ISeq || value instanceof IPersistentList) {
            emitListAsObjectArray(value, gen);
            gen.invokeStatic(Type.getType(java.util.Arrays.class),
                    Method.getMethod("java.util.List asList(Object[])"));
            gen.invokeStatic(Type.getType(PersistentList.class),
                    Method.getMethod(
                            "clojure.lang.IPersistentList create(java.util.List)"));
        } else if (value instanceof Pattern) {
            emitValue(value.toString(), gen);
            gen.invokeStatic(Type.getType(Pattern.class),
                    Method.getMethod("java.util.regex.Pattern compile(String)"));
        } else {
            String cs = null;
            try {
                cs = RT.printString(value);
//				System.out.println("WARNING SLOW CODE: " + Util.classOf(value) + " -> " + cs);
            } catch (Exception e) {
                throw Util.runtimeException(
                        "Can't embed object in code, maybe print-dup not defined: " +
                                value);
            }
            if (cs.length() == 0)
                throw Util.runtimeException(
                        "Can't embed unreadable object in code: " + value);

            if (cs.startsWith("#<"))
                throw Util.runtimeException(
                        "Can't embed unreadable object in code: " + cs);

            gen.push(cs);
            gen.invokeStatic(RT_TYPE, readStringMethod);
            partial = false;
        }

        if (partial) {
            if (value instanceof IObj && RT.count(((IObj) value).meta()) > 0) {
                gen.checkCast(IOBJ_TYPE);
                Object m = ((IObj) value).meta();
                emitValue(elideMeta(m), gen);
                gen.checkCast(IPERSISTENTMAP_TYPE);
                gen.invokeInterface(IOBJ_TYPE,
                        Method.getMethod("clojure.lang.IObj withMeta(clojure.lang.IPersistentMap)"));
            }
        }
    }


    void emitConstants(GeneratorAdapter clinitgen) {
        try {
            Var.pushThreadBindings(RT.map(RT.PRINT_DUP, RT.T));

            for (int i = 0; i < constants.count(); i++) {
                if (usedConstants.contains(i)) {
                    emitValue(constants.nth(i), clinitgen);
                    clinitgen.checkCast(constantType(i));
                    clinitgen.putStatic(objtype, constantName(i), constantType(i));
                }
            }
        } finally {
            Var.popThreadBindings();
        }
    }

    boolean isMutable(LocalBinding lb) {
        return isVolatile(lb) ||
                RT.booleanCast(RT.contains(fields, lb.sym)) &&
                        RT.booleanCast(RT.get(lb.sym.meta(), Keyword.intern("unsynchronized-mutable")));
    }

    boolean isVolatile(LocalBinding lb) {
        return RT.booleanCast(RT.contains(fields, lb.sym)) &&
                RT.booleanCast(RT.get(lb.sym.meta(), Keyword.intern("volatile-mutable")));
    }

    boolean isDeftype() {
        return fields != null;
    }

    boolean supportsMeta() {
        return !isDeftype();
    }

    void emitClearCloses(GeneratorAdapter gen) {
//		int a = 1;
//		for(ISeq s = RT.keys(closes); s != null; s = s.next(), ++a)
//			{
//			LocalBinding lb = (LocalBinding) s.first();
//			Class primc = lb.getPrimitiveType();
//			if(primc == null)
//				{
//				gen.loadThis();
//				gen.visitInsn(Opcodes.ACONST_NULL);
//				gen.putField(objtype, lb.name, OBJECT_TYPE);
//				}
//			}
    }

    synchronized Class getCompiledClass() {
        if (compiledClass == null)
//			if(RT.booleanCast(COMPILE_FILES.deref()))
//				compiledClass = RT.classForName(name);//loader.defineClass(name, bytecode);
//			else
        {
            loader = (DynamicClassLoader) LOADER.deref();
            compiledClass = loader.defineClass(name, bytecode, src);
        }
        return compiledClass;
    }

    public Object eval() {
        if (isDeftype())
            return null;
        try {
            return getCompiledClass().getDeclaredConstructor().newInstance();
        } catch (Exception e) {
            throw Util.sneakyThrow(e);
        }
    }

    public void emitLetFnInits(GeneratorAdapter gen, ObjExpr objx, IPersistentSet letFnLocals) {
        //objx arg is enclosing objx, not this
        gen.checkCast(objtype);

        for (ISeq s = RT.keys(closes); s != null; s = s.next()) {
            LocalBinding lb = (LocalBinding) s.first();
            if (letFnLocals.contains(lb)) {
                Class primc = lb.getPrimitiveType();
                gen.dup();
                if (primc != null) {
                    objx.emitUnboxedLocal(gen, lb);
                    gen.putField(objtype, lb.name, Type.getType(primc));
                } else {
                    objx.emitLocal(gen, lb, false);
                    gen.putField(objtype, lb.name, OBJECT_TYPE);
                }
            }
        }
        gen.pop();

    }

    public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
        //emitting a Fn means constructing an instance, feeding closed-overs from enclosing scope, if any
        //objx arg is enclosing objx, not this
//		getCompiledClass();
        if (isDeftype()) {
            gen.visitInsn(Opcodes.ACONST_NULL);
        } else {
            gen.newInstance(objtype);
            gen.dup();
            if (supportsMeta())
                gen.visitInsn(Opcodes.ACONST_NULL);
            for (ISeq s = RT.seq(closesExprs); s != null; s = s.next()) {
                LocalBindingExpr lbe = (LocalBindingExpr) s.first();
                LocalBinding lb = lbe.b;
                if (lb.getPrimitiveType() != null)
                    objx.emitUnboxedLocal(gen, lb);
                else
                    objx.emitLocal(gen, lb, lbe.shouldClear);
            }
            gen.invokeConstructor(objtype, new Method("<init>", Type.VOID_TYPE, ctorTypes()));
        }
        if (context == C.STATEMENT)
            gen.pop();
    }

    public boolean hasJavaClass() {
        return true;
    }

    Class jc;

    public Class getJavaClass() {
        if (jc == null)
            jc = (compiledClass != null) ? compiledClass
                    : (tag != null) ? HostExpr.tagToClass(tag)
                    : IFn.class;
        return jc;
    }

    public void emitAssignLocal(GeneratorAdapter gen, LocalBinding lb, Expr val) {
        if (!isMutable(lb))
            throw new IllegalArgumentException("Cannot assign to non-mutable: " + lb.name);
        Class primc = lb.getPrimitiveType();
        gen.loadThis();
        if (primc != null) {
            if (!(val instanceof MaybePrimitiveExpr && ((MaybePrimitiveExpr) val).canEmitPrimitive()))
                throw new IllegalArgumentException("Must assign primitive to primitive mutable: " + lb.name);
            MaybePrimitiveExpr me = (MaybePrimitiveExpr) val;
            me.emitUnboxed(C.EXPRESSION, this, gen);
            gen.putField(objtype, lb.name, Type.getType(primc));
        } else {
            val.emit(C.EXPRESSION, this, gen);
            gen.putField(objtype, lb.name, OBJECT_TYPE);
        }
    }

    private void emitLocal(GeneratorAdapter gen, LocalBinding lb, boolean clear) {
        if (closes.containsKey(lb)) {
            Class primc = lb.getPrimitiveType();
            gen.loadThis();
            if (primc != null) {
                gen.getField(objtype, lb.name, Type.getType(primc));
                HostExpr.emitBoxReturn(this, gen, primc);
            } else {
                gen.getField(objtype, lb.name, OBJECT_TYPE);
                if (onceOnly && clear && lb.canBeCleared) {
                    gen.loadThis();
                    gen.visitInsn(Opcodes.ACONST_NULL);
                    gen.putField(objtype, lb.name, OBJECT_TYPE);
                }
            }
        } else {
            int argoff = canBeDirect ? 0 : 1;
            Class primc = lb.getPrimitiveType();
//            String rep = lb.sym.name + " " + lb.toString().substring(lb.toString().lastIndexOf('@'));
            if (lb.isArg) {
                gen.loadArg(lb.idx - argoff);
                if (primc != null)
                    HostExpr.emitBoxReturn(this, gen, primc);
                else {
                    if (clear && lb.canBeCleared) {
//                        System.out.println("clear: " + rep);
                        gen.visitInsn(Opcodes.ACONST_NULL);
                        gen.storeArg(lb.idx - argoff);
                    } else {
//                        System.out.println("use: " + rep);
                    }
                }
            } else {
                if (primc != null) {
                    gen.visitVarInsn(Type.getType(primc).getOpcode(Opcodes.ILOAD), lb.idx);
                    HostExpr.emitBoxReturn(this, gen, primc);
                } else {
                    gen.visitVarInsn(OBJECT_TYPE.getOpcode(Opcodes.ILOAD), lb.idx);
                    if (clear && lb.canBeCleared) {
//                        System.out.println("clear: " + rep);
                        gen.visitInsn(Opcodes.ACONST_NULL);
                        gen.visitVarInsn(OBJECT_TYPE.getOpcode(Opcodes.ISTORE), lb.idx);
                    } else {
//                        System.out.println("use: " + rep);
                    }
                }
            }
        }
    }

    private void emitUnboxedLocal(GeneratorAdapter gen, LocalBinding lb) {
        int argoff = canBeDirect ? 0 : 1;
        Class primc = lb.getPrimitiveType();
        if (closes.containsKey(lb)) {
            gen.loadThis();
            gen.getField(objtype, lb.name, Type.getType(primc));
        } else if (lb.isArg)
            gen.loadArg(lb.idx - argoff);
        else
            gen.visitVarInsn(Type.getType(primc).getOpcode(Opcodes.ILOAD), lb.idx);
    }

    public void emitVar(GeneratorAdapter gen, Var var) {
        Integer i = (Integer) vars.valAt(var);
        emitConstant(gen, i);
        //gen.getStatic(fntype, munge(var.sym.toString()), VAR_TYPE);
    }

    final static Method varGetMethod = Method.getMethod("Object get()");
    final static Method varGetRawMethod = Method.getMethod("Object getRawRoot()");

    public void emitVarValue(GeneratorAdapter gen, Var v) {
        Integer i = (Integer) vars.valAt(v);
        if (!v.isDynamic()) {
            emitConstant(gen, i);
            gen.invokeVirtual(VAR_TYPE, varGetRawMethod);
        } else {
            emitConstant(gen, i);
            gen.invokeVirtual(VAR_TYPE, varGetMethod);
        }
    }

    public void emitKeyword(GeneratorAdapter gen, Keyword k) {
        Integer i = (Integer) keywords.valAt(k);
        emitConstant(gen, i);
//		gen.getStatic(fntype, munge(k.sym.toString()), KEYWORD_TYPE);
    }

    public void emitConstant(GeneratorAdapter gen, int id) {
        usedConstants = (IPersistentSet) usedConstants.cons(id);
        gen.getStatic(objtype, constantName(id), constantType(id));
    }


    String constantName(int id) {
        return CONST_PREFIX + id;
    }

    String siteName(int n) {
        return "__site__" + n;
    }

    String siteNameStatic(int n) {
        return siteName(n) + "__";
    }

    String thunkName(int n) {
        return "__thunk__" + n;
    }

    String cachedClassName(int n) {
        return "__cached_class__" + n;
    }

    String cachedVarName(int n) {
        return "__cached_var__" + n;
    }

    String varCallsiteName(int n) {
        return "__var__callsite__" + n;
    }

    String thunkNameStatic(int n) {
        return thunkName(n) + "__";
    }

    Type constantType(int id) {
        Object o = constants.nth(id);
        Class c = clojure.lang.Util.classOf(o);
        if (c != null && Modifier.isPublic(c.getModifiers())) {
            //can't emit derived fn types due to visibility
            if (LazySeq.class.isAssignableFrom(c))
                return Type.getType(ISeq.class);
            else if (c == Keyword.class)
                return Type.getType(Keyword.class);
//			else if(c == KeywordCallSite.class)
//				return Type.getType(KeywordCallSite.class);
            else if (RestFn.class.isAssignableFrom(c))
                return Type.getType(RestFn.class);
            else if (AFn.class.isAssignableFrom(c))
                return Type.getType(AFn.class);
            else if (c == Var.class)
                return Type.getType(Var.class);
            else if (c == String.class)
                return Type.getType(String.class);

//			return Type.getType(c);
        }
        return OBJECT_TYPE;
    }

*/

}
