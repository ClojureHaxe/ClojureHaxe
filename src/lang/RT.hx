package lang;

import lang.Map.EntrySet;
import haxe.Constraints.IMap;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.IndexOutOfBoundsException;
import lang.exceptions.NoSuchElementException;
import lang.exceptions.UnsupportedOperationException;
import haxe.ds.Vector;
import haxe.Exception;
#if (target.sys)
import sys.FileSystem;
import sys.io.File;
#end

class RT {
	static public final T:Bool = true;
	static public final F:Bool = false;
	static public final LOADER_SUFFIX:String = "__init";

	static public final DEFAULT_IMPORTS:IPersistentMap = map();

	static public final UTF8 = "UTF-8";

	static function readTrueFalseUnknown(s:String):Any {
		if (s == ("true"))
			return T;
		else if (s == ("false"))
			return F;
		return Keyword.intern(null, "unknown");
	}

	// TODO: fix object for that
	static public final REQUIRE_LOCK:Any = Symbol.intern1("REQUIRE_LOCK");
	static public final CLOJURE_NS:Namespace = Namespace.findOrCreate(Symbol.internNSname("clojure.core"));

	// TODO: reader/wirter instead of stdin, stderr, stdout
	// static public final OUT:Var = Var.intern(CLOJURE_NS, Symbol.intern("*out*"), new OutputStreamWriter(System.out)).setDynamic();
	// static public final IN:Var = Var.intern(CLOJURE_NS, Symbol.intern("*in*"), new LineNumberingPushbackReader(new InputStreamReader(System.in))).setDynamic();
	// static public final ERR:Var = Var.intern(CLOJURE_NS, Symbol.intern("*err*"), new PrintWriter(new OutputStreamWriter(System.err), true)).setDynamic();
	#if !js
	static public final OUT:Var = Var.intern3(CLOJURE_NS, Symbol.intern1("*out*"), Sys.stdout()).setDynamic();
	static public final IN:Var = Var.intern3(CLOJURE_NS, Symbol.intern1("*in*"), Sys.stdin()).setDynamic();
	static public final ERR:Var = Var.intern3(CLOJURE_NS, Symbol.intern1("*err*"), Sys.stderr()).setDynamic();
	#end
	static public final TAG_KEY:Keyword = Keyword.intern(null, "tag");
	static final CONST_KEY:Keyword = Keyword.intern(null, "const");
	static public final AGENT:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*agent*"), null).setDynamic();

	static var readeval:Any = T; // readTrueFalseUnknown(System.getProperty("clojure.read.eval", "true"));
	static public final READEVAL:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*read-eval*"), readeval).setDynamic();
	static public final DATA_READERS:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*data-readers*"), RT.map()).setDynamic();
	static public final DEFAULT_DATA_READER_FN:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*default-data-reader-fn*"), RT.map()).setDynamic();
	static public final DEFAULT_DATA_READERS:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("default-data-readers"), RT.map());
	static public final SUPPRESS_READ:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*suppress-read*"), null).setDynamic();
	static public final ASSERT:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*assert*"), T).setDynamic();
	static public final MATH_CONTEXT:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*math-context*"), null).setDynamic();

	static public final EVAL_FILE_KEY:Keyword = Keyword.intern("clojure.core", "eval-file");
	static public final LINE_KEY:Keyword = Keyword.intern(null, "line");
	static public final COLUMN_KEY:Keyword = Keyword.intern(null, "column");
	static public var FILE_KEY:Keyword = Keyword.intern(null, "file");
	static public var DECLARED_KEY:Keyword = Keyword.intern(null, "declared");
	static public var DOC_KEY:Keyword = Keyword.intern(null, "doc");

	static public final USE_CONTEXT_CLASSLOADER:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*use-context-classloader*"), T).setDynamic();

	static public final UNCHECKED_MATH:Var = Var.intern3(Namespace.findOrCreate(Symbol.internNSname("clojure.core")), Symbol.internNSname("*unchecked-math*"),
		false)
		.setDynamic();

	static final LOAD_FILE:Symbol = Symbol.internNSname("load-file");
	static final IN_NAMESPACE:Symbol = Symbol.internNSname("in-ns");
	static final NAMESPACE:Symbol = Symbol.internNSname("ns");
	static final IDENTICAL:Symbol = Symbol.internNSname("identical?");
	static final CMD_LINE_ARGS:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*command-line-args*"), null).setDynamic();
	// symbol
	public static final CURRENT_NS:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*ns*"), CLOJURE_NS).setDynamic();

	static final FLUSH_ON_NEWLINE:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*flush-on-newline*"), T).setDynamic();
	static final PRINT_META:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*print-meta*"), F).setDynamic();
	static final PRINT_READABLY:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*print-readably*"), T).setDynamic();
	static final PRINT_DUP:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*print-dup*"), F).setDynamic();
	static public final WARN_ON_REFLECTION:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*warn-on-reflection*"), F).setDynamic();
	static final ALLOW_UNRESOLVED_VARS:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*allow-unresolved-vars*"), F).setDynamic();
	static public final READER_RESOLVER:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*reader-resolver*"), null).setDynamic();

	static public final IN_NS_VAR:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("in-ns"), F);
	static public final NS_VAR:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("ns"), F);
	static public final FN_LOADER_VAR:Var = Var.intern3(CLOJURE_NS, Symbol.internNSname("*fn-loader*"), null).setDynamic();
	static public final PRINT_INITIALIZED:Var = Var.intern(CLOJURE_NS, Symbol.internNSname("print-initialized"));
	static public final PR_ON:Var = Var.intern(CLOJURE_NS, Symbol.internNSname("pr-on"));

	static final inNamespace:IFn = new InNamespaceFN();
	static final bootNamespace:IFn = new BootNamespaceFN();

	/*public static function processCommandLine(args:Array<String>): List<String> {
		var  arglist:List<String> = Arrays.asList(args);
		var split:Int = arglist.indexOf("--");
		if (split >= 0) {
			CMD_LINE_ARGS.bindRoot(RT.seq(arglist.subList(split + 1, args.length)));
			return arglist.subList(0, split);
		}
		return arglist;
	}*/
	/*public static PrintWriter errPrintWriter() {
		Writer w = (Writer) ERR.deref();
		if (w instanceof PrintWriter) {
			return (PrintWriter) w;
		} else {
			return new PrintWriter(w);
		}
	}*/
	static public final EMPTY_ARRAY:Vector<Any> = new Vector<Any>(0);
	// static public final EMPTY_ARRAY:Array<Any> = new Array<Any>();
	static public final DEFAULT_COMPARATOR:Comparator = new DefaultComparator();

	static var id:Int = 1; //     static AtomicInteger id = new AtomicInteger(1);

	static public function addURL() {
		// TODO:
	}

	public static var checkSpecAsserts:Bool = false; // Boolean.getBoolean("clojure.spec.check-asserts");
	public static var instrumentMacros:Bool = false; // !Boolean.getBoolean("clojure.spec.skip-macros");
	@:volatile static var CHECK_SPECS:Bool = false;

	public static function staticInit() {
		var arglistskw:Keyword = Keyword.intern(null, "arglists");
		var namesym:Symbol = Symbol.internNSname("name");
		#if !js
		OUT.setTag(Symbol.internNSname("java.io.Writer"));
		#end
		CURRENT_NS.setTag(Symbol.internNSname("clojure.lang.Namespace"));
		AGENT.setMeta(map(DOC_KEY, "The agent currently running an action on this thread, else nil"));
		AGENT.setTag(Symbol.internNSname("clojure.lang.Agent"));
		MATH_CONTEXT.setTag(Symbol.internNSname("java.math.MathContext"));
		var nv:Var = Var.intern3(CLOJURE_NS, NAMESPACE, bootNamespace);
		nv.setMacro();
		var v:Var;
		v = Var.intern3(CLOJURE_NS, IN_NAMESPACE, inNamespace);
		v.setMeta(map(DOC_KEY, "Sets *ns* to the namespace named by the symbol, creating it if needed.", arglistskw, list(vector(namesym))));
		v = Var.intern3(CLOJURE_NS, LOAD_FILE, new LoadFileFN());
		v.setMeta(map(DOC_KEY, "Sequentially read and evaluate the set of forms contained in the file.", arglistskw, list(vector(namesym))));
		try {
			// TODO:
			trace("Loading clojure/core");
			// load("clojure/core");
		} catch (e:Exception) {
			// trace("Error while loading clojure/core", e, e.stack);
			throw Util.sneakyThrow(e);
		}

		CHECK_SPECS = RT.instrumentMacros;
	}

	static public function keyword(ns:String, name:String):Keyword {
		return Keyword.internSymbol(Symbol.intern(ns, name));
	}

	static public function var2(ns:String, name:String):Var {
		return Var.intern(Namespace.findOrCreate(Symbol.intern(null, ns)), Symbol.intern(null, name));
	}

	static public function var3(ns:String, name:String, init:Any):Var {
		return Var.intern3(Namespace.findOrCreate(Symbol.intern(null, ns)), Symbol.intern(null, name), init);
	}

	public static function loadResourceScript(name:String) {
		loadResourceScript2(name, true);
	}

	public static function loadResourceScript2(name:String, failIfNotFound:Bool) {
		var r = new EReg("/", "");
		var file:String = r.split(name).pop();
		var data:String = File.getContent("src/" + name);
		trace("FILE NAME: " + file);
		trace("Content: " + data);
		// var slash:Int  = StringTools.i name.lastIndexOf('/');
		// String file = slash >= 0 ? name.substring(slash + 1) : name;
		// InputStream ins = resourceAsStream(baseLoader(), name);
		// TODO: inputStream vs string?
		if (data != null) {
			try {
				Compiler.load(data, name, file);
			}
		} else if (failIfNotFound) {
			throw new Exception("Could not locate Clojure resource on classpath: " + name);
		}
	}

	static public function load(scriptBase:String) {
		load2(scriptBase, true);
	}

	static public function load2(scriptbase:String, failIfNotFound:Bool) {
		// var classfile:String = scriptbase + LOADER_SUFFIX + ".class";
		var cljfile:String = scriptbase + ".clj";
		var cljcfile:String = scriptbase + ".cljc";
		var scriptfile:String = cljfile;
		// var	classURL = getResource(baseLoader(), classfile);

		var cljURL = getResource(scriptfile);
		trace("RES: " + cljURL);
		if (cljURL == null) {
			scriptfile = cljcfile;
			cljURL = getResource(scriptfile);
		}

		if (cljURL != null) {
			if (booleanCast(Compiler.COMPILE_FILES.deref())) {
				trace(">>>>>>>>>>>>>>>> COMPILE " + cljURL);
				// compile(scriptfile);
			} else {
				trace(">>>>>>>>>>>>>>>> LOAD " + cljURL);
				loadResourceScript(scriptfile);
			}
		} else if (failIfNotFound)
			throw new Exception("Could not locate "
				+ cljfile
				+ " or "
				+ cljcfile
				+ " on classpath.%s"
				+ (StringTools.contains(scriptbase, "_") ? " Please check that namespaces with dashes use underscores in the Clojure file name." : ""));
	}

	static public function init() {
		doInit();
	}

	private static var INIT:Bool = false;

	@:synchronized
	private static function doInit() {
		if (INIT) {
			return;
		} else {
			INIT = true;
		}

		Var.pushThreadBindings(RT.mapUniqueKeys(CURRENT_NS, CURRENT_NS.deref(), WARN_ON_REFLECTION, WARN_ON_REFLECTION.deref(), RT.UNCHECKED_MATH,
			RT.UNCHECKED_MATH.deref()));
		try {
			var USER:Symbol = Symbol.intern1("user");
			var CLOJURE:Symbol = Symbol.intern1("clojure.core");

			var in_ns:Var = var2("clojure.core", "in-ns");
			var refer:Var = var2("clojure.core", "refer");
			in_ns.invoke1(USER);
			refer.invoke1(CLOJURE);
			// TODO: skip for now?
			// maybeLoadResourceScript("user.clj");

			// start socket servers
			// var require:Var = var2("clojure.core", "require");
			// var SERVER:Symbol = Symbol.intern1("clojure.core.server");
			// require.invoke1(SERVER);
			// var start_servers:Var = var2("clojure.core.server", "start-servers");
			// start_servers.invoke(System.getProperties());
			Var.popThreadBindings();
		} catch (e) {
			Var.popThreadBindings();
			throw Util.sneakyThrow(e);
		}
	}

	static public function nextID():Int {
		return id++;
	}

	//////////////////////////////// Collections support /////////////////////////////////
	public static final CHUNK_SIZE = 32;

	public static function chunkIteratorSeq(iter:Iterator<Any>):ISeq {
		if (iter.hasNext()) {
			return LazySeq.createFromFn(new ChunkIteratorSeqLazySeqAFn(iter));
		}
		return null;
	}

	static public function seq(coll:Any):ISeq {
		if (U.instanceof(coll, ASeq))
			return cast(coll, ASeq);
		else if (U.instanceof(coll, LazySeq))
			return cast(coll, LazySeq).seq();
		else
			return seqFrom(coll);
	}

	static function seqFrom(coll:Any):ISeq {
		if (U.instanceof(coll, Seqable))
			return cast(coll, Seqable).seq();
		else if (coll == null)
			return null;
		else if (U.isIterator(coll))
			return chunkIteratorSeq(coll);
		else if (U.isIterable(coll))
			return chunkIteratorSeq((cast coll).iterator());
			// TODO:
			// else if (U.instanceof(Array))
		//     return ArraySeq.createFromObject(coll);
		else if (U.instanceof(coll, String))
			return StringSeq.create(coll);
			// else if (U.instanceof(coll, Map)){
			//		return seq(haxe.ds.Map.keyValueIterator(coll));
		//		}
		else if (U.instanceof(coll, EntrySet))
			return seq(cast(coll, EntrySet).entrySet());
		else {
			throw new IllegalArgumentException("Don't know how to create ISeq from: " + coll + " :  " + Type.getClassName(coll));
		}
		return null;
	}

	static public function canSeq(coll:Any):Bool {
		return U.instanceof(coll, ISeq)
			|| U.instanceof(coll, Seqable)
			|| coll == null
			|| U.isIterable(coll) // || coll.getClass().isArray()
			|| U.instanceof(coll, String);
		// || coll instanceof Map;
	}

	static public function iter(coll:Any):Iterator<Any> {
		// TODO:
		if (U.isIterable(coll))
			return U.getIterator(coll);
		else if (coll == null)
			return new NullIterator();
			// else if (U.instanceof(coll, APersistentMap)) {
			//		return cast(coll, APersistentMap).entrySet().iterator();
		// }
		else if (U.instanceof(coll, String)) {
			final s:String = cast coll;
			return new StringIterator(s);
			// } else if (coll.getClass().isArray()) {
			//	return ArrayIter.createFromObject(coll);
		} else
			return iter(seq(coll));
	}

	static public function seqOrElse(o:Any):Any {
		return seq(o) == null ? null : o;
	}

	static public function keys(coll:Any):ISeq {
		if (U.instanceof(coll, IPersistentMap))
			return APersistentMap.KeySeq.createFromMap(cast coll);
		else
			return APersistentMap.KeySeq.create(seq(coll));
	}

	static public function vals(coll:Any):ISeq {
		if (U.instanceof(coll, IPersistentMap))
			return APersistentMap.ValSeq.createFromMap(cast coll);
		else
			return APersistentMap.ValSeq.create(seq(coll));
	}

	static public function meta(x:Any):IPersistentMap {
		if (U.instanceof(x, IMeta))
			return cast(x, IMeta).meta();
		return null;
	}

	public static function count(o:Any):Int {
		if (U.instanceof(o, Counted))
			return cast(o, Counted).count();
		return countFrom(Util.ret1(o, o = null));
	}

	private static function countFrom(o:Any):Int {
		if (o == null)
			return 0;
		else if (U.instanceof(o, IPersistentCollection)) {
			var s:ISeq = seq(o);
			o = null;
			var i:Int = 0;
			while (s != null) {
				if (U.instanceof(s, Counted)) {
					return i + s.count();
				}
				i++;
			}
			return i;
		} else if (U.instanceof(o, String)) {
			return cast(o, String).length;
		}
		// TODO:
		/*
			} else if (o instanceof CharSequence)
				return ((CharSequence) o).length();
			else if (o instanceof Collection)
				return ((Collection) o).size();
			else if (o instanceof Map)
				return ((Map) o).size();
			else if (o instanceof Map.Entry)
				return 2;
			else if (o.getClass().isArray())
				return Array.getLength(o); */

		return 0;

		// throw new UnsupportedOperationException("count not supported on this type: " + o.getClass().getSimpleName());
	}

	static public function conj(coll:IPersistentCollection, x:Any):IPersistentCollection {
		if (coll == null)
			return new PersistentList(x);
		return coll.cons(x);
	}

	static public function cons(x:Any, coll:Any):ISeq {
		if (coll == null)
			return new PersistentList(x);
		else if (U.instanceof(coll, ISeq))
			return new Cons(x, cast coll);
		else
			return new Cons(x, seq(coll));
	}

	static public function first(x:Any):Any {
		if (U.instanceof(x, ISeq))
			return (cast x).first();
		var seq:ISeq = seq(x);
		if (seq == null)
			return null;
		return seq.first();
	}

	static public function second(x:Any):Any {
		return first(next(x));
	}

	static public function third(x:Any):Any {
		return first(next(next(x)));
	}

	static public function fourth(x:Any):Any {
		return first(next(next(next(x))));
	}

	static public function next(x:Any):ISeq {
		if (U.instanceof(x, ISeq))
			return (cast x).next();
		var seq:ISeq = seq(x);
		if (seq == null)
			return null;
		return seq.next();
	}

	static public function more(x:Any):ISeq {
		if (U.instanceof(x, ISeq))
			return cast(x, ISeq).more();
		var seq:ISeq = seq(x);
		if (seq == null)
			return PersistentList.EMPTY;
		return seq.more();
	}

	static public function peek(x:Any):Any {
		if (x == null)
			return null;
		return cast(x, IPersistentStack).peek();
	}

	static public function pop(x:Any):Any {
		if (x == null)
			return null;
		return cast(x, IPersistentStack).pop();
	}

	public static function get(coll:Any, key:Any, ?notFound = null):Any {
		if (U.instanceof(coll, ILookup))
			return cast(coll, ILookup).valAt(key, notFound);
		return getFrom(coll, key, notFound);
	}

	static function getFrom(coll:Any, key:Any, ?notFound = null):Any {
		if (coll == null)
			return notFound;
		else if (U.instanceof(coll, IMap)) {
			var m:IMap<Any, Any> = cast coll;
			if (m.exists(key))
				return m.get(key);
			return notFound;
		} else if (U.instanceof(coll, IPersistentSet)) {
			var set:IPersistentSet = cast coll;
			if (set.contains(key))
				return set.get(key);
			return notFound;
			// TODO: array
		} else if (U.isNumber(key) && (U.instanceof(coll, String))) {
			var n:Int = cast key;
			if (n >= 0 && n < count(coll))
				return nth(coll, n);
			return notFound;
		} else if (U.instanceof(coll, ITransientSet)) {
			var set:ITransientSet = cast coll;
			if (set.contains(key))
				return set.get(key);
			return notFound;
		}

		return notFound;
	}

	static public function assoc(coll:Any, key:Any, val:Any):Associative {
		if (coll == null) {
			return PersistentArrayMap.create(key, val);
		}
		return cast(coll, Associative).assoc(key, val);
	}

	static public function contains(coll:Any, key:Any):Any {
		if (coll == null)
			return F;
		else if (U.instanceof(coll, Associative))
			return cast(coll, Associative).containsKey(key) ? T : F;
		else if (U.instanceof(coll, IPersistentSet))
			return cast(coll, IPersistentSet).contains(key) ? T : F;
		else if (U.instanceof(coll, IMap)) {
			var m:IMap<Any, Any> = coll;
			return m.exists(key) ? T : F;
		} else if (U.instanceof(coll, IPersistentSet)) {
			var s:IPersistentSet = cast coll;
			return s.contains(key) ? T : F;
		} else if (U.isNumber(key) && (U.instanceof(coll, String))) {
			var n:Int = Std.int(key);
			return n >= 0 && n < count(coll);
		} else if (U.instanceof(coll, ITransientSet))
			return cast(coll, ITransientSet).contains(key) ? T : F;
		else if (U.instanceof(coll, ITransientAssociative2))
			return cast(coll, ITransientAssociative2).containsKey(key) ? T : F;
		throw new IllegalArgumentException("contains? not supported on type: " + U.getClassName(coll));
	}

	static public function find(coll:Any, key:Any) {
		if (coll == null)
			return null;
		else if (U.instanceof(coll, Associative))
			return cast(coll, Associative).entryAt(key);
		else if (U.instanceof(coll, IMap)) {
			var m:IMap<Any, Any> = coll;
			if (m.exists(key))
				return MapEntry.create(key, m.get(key));
			return null;
		} else if (U.instanceof(coll, ITransientAssociative2)) {
			return cast(coll, ITransientAssociative2).entryAt(key);
		}
		throw new IllegalArgumentException("find not supported on type: " + U.getClassName(coll));
	}

	static public function findKey(key:Keyword, keyvals:ISeq):ISeq {
		while (keyvals != null) {
			var r:ISeq = keyvals.next();
			if (r == null)
				throw Util.runtimeException("Malformed keyword argslist");
			if (keyvals.first() == key)
				return r;
			keyvals = r.next();
		}
		return null;
	}

	static public function dissoc(coll:Any, key:Any):Any {
		if (coll == null)
			return null;
		return cast(coll, IPersistentMap).without(key);
	}

	static public function nth(coll:Any, n:Int):Any {
		if (U.instanceof(coll, Indexed))
			return cast(coll, Indexed).nth(n);
		return nthFrom(Util.ret1(coll, coll = null), n);
	}

	static function nthFrom(coll:Any, n:Int):Any {
		if (coll == null)
			return null;
		else if (U.instanceof(coll, String))
			return cast(coll, String).charAt(n);
			// else if (coll.getClass().isArray())
			//    return Reflector.prepRet(coll.getClass().getComponentType(), Array.get(coll, n));
			// else if (U.instanceof(coll, RandomAccess) )
			//     return ((List) coll).get(n);
			// else if (coll instanceof Matcher)
		//    return ((Matcher) coll).group(n);
		else if (U.instanceof(coll, Map.Entry)) {
			var e:Map.Entry = cast coll;
			if (n == 0)
				return e.getKey();
			else if (n == 1)
				return e.getValue();
			throw new IndexOutOfBoundsException();
		} else if (U.instanceof(coll, Sequential)) {
			var seq:ISeq = RT.seq(coll);
			coll = null;
			var i:Int = 0;
			while (i <= n && seq != null) {
				if (i == n)
					return seq.first();
				++i;
				seq = seq.next();
			}
			throw new IndexOutOfBoundsException();
		} else
			throw new UnsupportedOperationException("nth not supported on this type: " + U.getClassName(coll));
	}

	static public function nth3(coll:Any, n:Int, notFound:Any):Any {
		if (U.instanceof(coll, Indexed)) {
			var v:Indexed = cast coll;
			return v.nth(n, notFound);
		}
		return nthFrom3(coll, n, notFound);
	}

	static public function nthFrom3(coll:Any, n:Int, notFound:Any):Any {
		if (coll == null)
			return notFound;
		else if (n < 0)
			return notFound;
		else if (U.instanceof(coll, String)) {
			var s:String = coll;
			if (n < s.length)
				return s.charAt(n);
			return notFound;
			/*} else if (coll.getClass().isArray()) {
					if (n < Array.getLength(coll))
						return Reflector.prepRet(coll.getClass().getComponentType(), Array.get(coll, n));
				   return notFound;
				} else if (coll instanceof RandomAccess) {
					List list = (List) coll;
					if (n < list.size())
						return list.get(n);
					return notFound;
				} else if (coll instanceof Matcher) {
					Matcher m = (Matcher) coll;
					int groups = m.groupCount();
					if (groups > 0 && n <= m.groupCount())
						return m.group(n);
					return notFound;
			 */
		} else if (U.instanceof(coll, Map.Entry)) {
			var e:Map.Entry = coll;
			if (n == 0)
				return e.getKey();
			else if (n == 1)
				return e.getValue();
			return notFound;
		} else if (U.instanceof(coll, Sequential)) {
			var seq:ISeq = RT.seq(coll);
			coll = null;
			var i:Int = 0;
			while (i <= n && seq != null) {
				if (i == n)
					return seq.first();
				++i;
				seq = seq.next();
			}
			return notFound;
		} else
			throw new UnsupportedOperationException("nth not supported on this type: " + U.getClassName(coll));
	}

	static public function assocN(n:Int, val:Any, coll:Any):Any {
		if (coll == null)
			return null;
		else if (U.instanceof(coll, IPersistentVector))
			return cast(coll, IPersistentVector).assocN(n, val);
		/*else if (U.instanceof(coll, Vector)) {
			// hmm... this is not persistent
			var array:Vector<Any> = cast coll;
			array[n] = val;
			return array;
		}*/
		else
			return null;
	}

	static function hasTag(o:Any, tag:Any):Bool {
		return Util.equals(tag, RT.get(RT.meta(o), TAG_KEY));
	}

	/* ********************************************** Boxing/casts ****************************************************  */
	static public function errPrint(s:String) {
		// TODO;
		// trace(s);
	}

	static public function map(...init:Any):IPersistentMap {
		if (init == null || init.length == 0)
			return PersistentArrayMap.EMPTY;
		else if (init.length <= PersistentArrayMap.HASHTABLE_THRESHOLD)
			return PersistentArrayMap.createWithCheck(...init);
		return PersistentHashMap.createWithCheck(...init);
	}

	static public function mapFromArray(init:Array<Any>):IPersistentMap {
		if (init == null || init.length == 0)
			return PersistentArrayMap.EMPTY;
		else if (init.length <= PersistentArrayMap.HASHTABLE_THRESHOLD)
			return PersistentArrayMap.createWithCheck(...init);
		return PersistentHashMap.createWithCheck(...init);
	}

	static public function mapUniqueKeys(...init:Any):IPersistentMap {
		if (init == null)
			return PersistentArrayMap.EMPTY;
		else if (init.length <= PersistentArrayMap.HASHTABLE_THRESHOLD)
			return PersistentArrayMap.create(...init);
		return PersistentHashMap.create(...init);
	}

	static public function set(...init:Any):IPersistentSet {
		return PersistentHashSet.createWithCheck(...init);
	}

	static public function vector(...init:Any):IPersistentVector {
		return LazilyPersistentVector.createOwning(...init);
	}

	static public function subvec(v:IPersistentVector, start:Int, end:Int):IPersistentVector {
		if (end < start || start < 0 || end > v.count())
			throw new IndexOutOfBoundsException();
		if (start == end)
			return PersistentVector.EMPTY;
		return new APersistentVector.SubVector(null, v, start, end);
	}

	/**
	 * ********************* Boxing/casts ******************************
	 */
	static public function booleanCast(x:Any):Bool {
		if (U.instanceof(x, Bool))
			return cast(x, Bool);
		return x != null;
	}

	// ========================== List support ==========================================================================
	static public function list(...init:Any):ISeq
		return PersistentList.create(...init).seq();

	static public function list0():ISeq
		return null;

	static public function list1(arg1:Any):ISeq
		return new PersistentList(arg1);

	static public function list2(arg1:Any, arg2:Any):ISeq
		return listStar3(arg1, arg2, null);

	static public function list3(arg1:Any, arg2:Any, arg3:Any):ISeq
		return listStar4(arg1, arg2, arg3, null);

	static public function list4(arg1:Any, arg2:Any, arg3:Any, arg4:Any):ISeq
		return listStar5(arg1, arg2, arg3, arg4, null);

	static public function list5(arg1:Any, arg2:Any, arg3:Any, arg4:Any, arg5:Any):ISeq
		return listStar6(arg1, arg2, arg3, arg4, arg5, null);

	static public function listStar2(arg1:Any, rest:ISeq):ISeq
		return cons(arg1, rest);

	static public function listStar3(arg1:Any, arg2:Any, rest:ISeq):ISeq
		return cons(arg1, cons(arg2, rest));

	static public function listStar4(arg1:Any, arg2:Any, arg3:Any, rest:ISeq):ISeq
		return cons(arg1, cons(arg2, cons(arg3, rest)));

	static public function listStar5(arg1:Any, arg2:Any, arg3:Any, arg4:Any, rest:ISeq):ISeq
		return cons(arg1, cons(arg2, cons(arg3, cons(arg4, rest))));

	static public function listStar6(arg1:Any, arg2:Any, arg3:Any, arg4:Any, arg5:Any, rest:ISeq):ISeq
		return cons(arg1, cons(arg2, cons(arg3, cons(arg4, cons(arg5, rest)))));

	static public function toArray(coll:Any):Vector<Any> {
		if (coll == null)
			return EMPTY_ARRAY;
		else if (U.instanceof(coll, Array))
			return cast coll;
		else if (U.instanceof(coll, Collection))
			return cast(coll, Collection).toArray();
		else if (U.isIterable(coll)) {
			var ret:Array<Any> = new Array<Any>();
			var iter:Iterator<Any> = U.getIterator(coll);
			for (o in coll)
				ret.push(o);
			// return ret.toArray();
			return Vector.fromArrayCopy(ret);
		} else if (U.instanceof(coll, EntrySet))
			return Vector.fromArrayCopy(cast(coll, EntrySet).entrySet());
		else if (U.instanceof(coll, String)) {
			var s:String = cast coll;
			var array:Vector<Any> = new Vector<Any>(s.length);
			var i:Int = 0;
			while (i < s.length) {
				array[i] = s.charCodeAt(i);
				i++;
			}
			return array;
		}
			// TODO:
		/*else if (coll.getClass().isArray()) {
			var s:ISeq = seq(coll);
			var ret:Array<Any> = new Array<Any>();
			var i:Int = 0;
			while (i < ret.length) {
				ret[i] = s.first();
				i++;
				s = s.next();
			}

			return ret;
		}*/
		else
			throw Util.runtimeException("Unable to convert: " + U.getClassName(coll) + " to Object[]");
	}

	static public function seqToArray(seq:ISeq):Vector<Any> {
		var len:Int = length(seq);
		var ret:Vector<Any> = new Vector<Any>(len);
		var i:Int = 0;
		while (seq != null) {
			ret[i] = seq.first();
			++i;
			seq = seq.next();
		}
		return ret;
	}

	static public function length(list:ISeq):Int {
		var i:Int = 0;
		var c:ISeq = list;
		while (c != null) {
			i++;
			c = c.next();
		}
		return i;
	}

	///////////////////////////////// reader support ////////////////////////////////

	static public function isReduced(r:Any):Bool {
		return U.instanceof(r, Reduced);
	}

	static public function suppressRead():Bool {
		return booleanCast(SUPPRESS_READ.deref());
	}

	static public function printString(x:Any):String {
		var sb:StringBuf = new StringBuf();
		print(x, sb);
		return sb.toString();
	}

	static public function print(x:Any, sb:StringBuf) {
		// trace("IN PRINT");
		// if (U.instanceof(x, ArraySeq)) {
		// 	trace("In print: ", cast(x, ArraySeq).array, U.instanceof(x, ISeq) /*, sb.toString()*/);
		// }

		if (x == null) {
			sb.add("nil");
		} else if (U.instanceof(x, String)) {
			var s:String = cast(x, String);
			var i:Int = 0;
			sb.add('"');
			while (i < s.length) {
				var c:String = s.charAt(i);
				switch (c) {
					case '\n':
						sb.add("\\n");
					case '\t':
						sb.add("\\t");
					case '\r':
						sb.add("\\r");
					case '"':
						sb.add("\\\"");
					case '\\':
						sb.add("\\\\");

					// case '\f':
					// 	w.write("\\f");
					// 	break;
					// case '\b':
					// 	w.write("\\b");
					// 	break;

					default:
						sb.add(c);
				}
				i++;
			}
			sb.add('"');
		} else if (U.instanceof(x, ISeq) || U.instanceof(x, IPersistentList)) {
			sb.add('(');
			printInnerSeq(seq(x), sb);
			sb.add(')');
		} else if (U.instanceof(x, IPersistentMap) || (U.instanceof(x, PersistentHashMap))) {
			sb.add("{");
			var s:ISeq = seq(x);
			while (s != null) {
				var e:IMapEntry = s.first();
				print(e.key(), sb);
				sb.add(" ");
				print(e.val(), sb);
				if (s.next() != null) {
					sb.add(", ");
				}
				s = s.next();
			}
			sb.add("}");
		} else if (U.instanceof(x, IPersistentVector)) {
			// trace("print cast to vector yes!");
			var a:IPersistentVector = cast(x, IPersistentVector);
			var i:Int = 0;
			sb.add("[");
			while (i < a.count()) {
				print(a.nth(i), sb);
				if (i < a.count() - 1) {
					sb.add(' ');
				}
				i++;
			}
			sb.add("]");
		} else if (U.instanceof(x, IPersistentSet)) {
			sb.add("#{");
			var s:ISeq = seq(x);
			while (s != null) {
				print(s.first(), sb);
				if (s.next() != null)
					sb.add(" ");
				s = s.next();
			}
			sb.add('}');
		} else {
			// sb.add('$x');
			sb.add(Std.string(x));
		}
	}

	private static function printInnerSeq(x:ISeq, sb:StringBuf) {
		var s:ISeq = x;
		while (s != null) {
			var fr:Any = s.first();
			// trace("next()", fr, U.instanceof(x, Int), U.instanceof(x, String), U.instanceof(Std.downcast(fr, String), String));
			print(fr, sb);
			if (s.next() != null)
				sb.add(' ');
			s = s.next();
		}
	}

	///////////////////////////////// values //////////////////////////
	static public function getResource(name:String):String {
		/*if (loader == null) {
				return ClassLoader.getSystemResource(name);
			} else {
				return loader.getResource(name);
		}*/
		var fullPath:String = "src/" + name;
		if (FileSystem.exists(fullPath)) {
			return fullPath;
		} else
			return null;
	}

	static public function classForName(name:String):Class<Dynamic> {
		// return classForName(name, true, baseLoader());
		return Type.resolveClass(name);
	}

	static public function classForNameNonLoading(name:String) {
		return classForName(name);
	}
}

// ============================================================= Classes ========================================================
class ChunkIteratorSeqLazySeqAFn extends AFn {
	var iter:Iterator<Any>;

	public function new(iter:Iterator<Any>) {
		this.iter = iter;
	}

	override public function invoke0():Any {
		var arr:Vector<Any> = new Vector<Any>(RT.CHUNK_SIZE);
		var n:Int = 0;
		while (iter.hasNext() && n < RT.CHUNK_SIZE)
			arr[n++] = iter.next();
		return new ChunkedCons(new ArrayChunk(arr, 0, n), RT.chunkIteratorSeq(iter));
	}
}

class DefaultComparator implements Comparator {
	public function new() {}

	public function compare(o1:Any, o2:Any):Int {
		return Util.compare(o1, o2);
	}

	private function readResolve():Any {
		// ensures that we aren't hanging onto a new default comparator for every
		// sorted set, etc., we deserialize
		return RT.DEFAULT_COMPARATOR;
	}
}

// AFn classes
class InNamespaceFN extends AFn {
	public function new() {}

	override public function invoke1(arg1:Any):Any {
		var nsname:Symbol = cast arg1;
		var ns:Namespace = Namespace.findOrCreate(nsname);
		RT.CURRENT_NS.set(ns);
		return ns;
	}
}

class BootNamespaceFN extends AFn {
	public function new() {}

	override public function invoke3(__form:Any, __env:Any, arg1:Any):Any {
		var nsname:Symbol = cast arg1;
		var ns:Namespace = Namespace.findOrCreate(nsname);
		RT.CURRENT_NS.set(ns);
		return ns;
	}
}

class LoadFileFN extends AFn {
	public function new() {}

	override public function invoke1(arg1:Any):Any {
		/*try {
				// TODO: Noe implemented
				//return Compiler.loadFile(cast( arg1, String));
			} catch (e) {
				//throw Util.sneakyThrow(e);
		}*/
		return null;
	}
}

class NullIterator {
	public function new() {}

	public function hasNext():Bool {
		return false;
	}

	public function next():Any {
		throw new NoSuchElementException();
	}
}

class StringIterator {
	var i:Int = 0;
	var s:String;

	public function new(s) {
		this.s = s;
	}

	public function hasNext():Bool {
		return i < s.length;
	}

	public function next():Any {
		return s.charAt(i++);
	}
}
