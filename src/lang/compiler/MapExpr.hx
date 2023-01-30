package lang.compiler;

import lang.Compiler.C;
import lang.exceptions.IllegalArgumentException;

class MapExpr implements Expr {
	public var keyvals:IPersistentVector;

	// final static Method mapMethod = Method.getMethod("clojure.lang.IPersistentMap map(Object[])");
	// final static Method mapUniqueKeysMethod = Method.getMethod("clojure.lang.IPersistentMap mapUniqueKeys(Object[])");

	public function new(keyvals:IPersistentVector) {
		this.keyvals = keyvals;
	}

	public function eval():Any {
		var ret:Array<Any> = new Array<Any>();
		var i:Int = 0;
		while (i < keyvals.count()) {
			ret[i] = cast(keyvals.nth(i), Expr).eval();
			i++;
		}
		return RT.map(...ret);
	}

	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			boolean allKeysConstant = true;
			boolean allConstantKeysUnique = true;
			IPersistentSet constantKeys = PersistentHashSet.EMPTY;
			for (int i = 0; i < keyvals.count(); i += 2) {
				Expr k = (Expr) keyvals.nth(i);
				if (k instanceof LiteralExpr) {
					Object kval = k.eval();
					if (constantKeys.contains(kval))
						allConstantKeysUnique = false;
					else
						constantKeys = (IPersistentSet) constantKeys.cons(kval);
				} else
					allKeysConstant = false;
			}
			MethodExpr.emitArgsAsArray(keyvals, objx, gen);
			if ((allKeysConstant && allConstantKeysUnique) || (keyvals.count() <= 2))
				gen.invokeStatic(RT_TYPE, mapUniqueKeysMethod);
			else
				gen.invokeStatic(RT_TYPE, mapMethod);
			if (context == C.STATEMENT)
				gen.pop();
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return IPersistentMap.class;
		}

	 */
	static public function parse(context:C, form:IPersistentMap):Expr {
		var keyvals:IPersistentVector = PersistentVector.EMPTY;
		var keysConstant:Bool = true;
		var valsConstant:Bool = true;
		var allConstantKeysUnique:Bool = true;
		var constantKeys:IPersistentSet = PersistentHashSet.EMPTY;
		var s:ISeq = RT.seq(form);
		while (s != null) {
			var e:IMapEntry = s.first();
			var k:Expr = Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, e.key());
			var v:Expr = Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, e.val());
			keyvals = cast keyvals.cons(k);
			keyvals = cast keyvals.cons(v);
			if (U.instanceof(k, LiteralExpr)) {
				var kval:Any = k.eval();
				if (constantKeys.contains(kval))
					allConstantKeysUnique = false;
				else
					constantKeys = cast constantKeys.cons(kval);
			} else
				keysConstant = false;
			if (!(U.instanceof(v, LiteralExpr)))
				valsConstant = false;
			s = s.next();
		}

		var ret:Expr = new MapExpr(keyvals);
		if (U.instanceof(form, IObj) && cast(form, IObj).meta() != null)
			return new MetaExpr(ret, MapExpr.parse(context == C.EVAL ? context : C.EXPRESSION, cast(form, IObj).meta()));
		else if (keysConstant) {
			// TBD: Add more detail to exception thrown below.
			if (!allConstantKeysUnique)
				throw new IllegalArgumentException("Duplicate constant keys in map");
			if (valsConstant) {
				var m:IPersistentMap = PersistentArrayMap.EMPTY;
				var i:Int = 0;
				while (i < keyvals.length()) {
					m = cast m.assoc((keyvals.nth(i) : LiteralExpr).val(), (keyvals.nth(i + 1) : LiteralExpr).val());
					i += 2;
				}
				return new ConstantExpr(m);
			} else
				return ret;
		} else
			return ret;
	}
}
