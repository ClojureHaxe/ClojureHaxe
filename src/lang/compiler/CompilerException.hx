package lang.compiler;

import haxe.Exception;

class CompilerException extends Exception implements IExceptionInfo {
	public var source:String;

	public var line:Int;

	public var data:Any;

	// Error keys
	static public final ERR_NS:String = "clojure.error";
	static public final ERR_SOURCE:Keyword = Keyword.intern(ERR_NS, "source");
	static public final ERR_LINE:Keyword = Keyword.intern(ERR_NS, "line");
	static public final ERR_COLUMN:Keyword = Keyword.intern(ERR_NS, "column");
	static public final ERR_PHASE:Keyword = Keyword.intern(ERR_NS, "phase");
	static public final ERR_SYMBOL:Keyword = Keyword.intern(ERR_NS, "symbol");

	// Compile error phases
	static public final PHASE_READ:Keyword = Keyword.intern(null, "read-source");
	static public final PHASE_MACRO_SYNTAX_CHECK:Keyword = Keyword.intern(null, "macro-syntax-check");
	static public final PHASE_MACROEXPANSION:Keyword = Keyword.intern(null, "macroexpansion");
	static public final PHASE_COMPILE_SYNTAX_CHECK:Keyword = Keyword.intern(null, "compile-syntax-check");
	static public final PHASE_COMPILATION:Keyword = Keyword.intern(null, "compilation");
	static public final PHASE_EXECUTION:Keyword = Keyword.intern(null, "execution");

	static public final SPEC_PROBLEMS:Keyword = Keyword.intern("clojure.spec.alpha", "problems");

	// Class compile exception
	public static function create4(source:String, line:Int, column:Int, cause:Exception):CompilerException {
		return create5(source, line, column, null, cause);
	}

	public static function create5(source:String, line:Int, column:Int, sym:Symbol, cause:Exception):CompilerException {
		return new CompilerException(source, line, column, sym, PHASE_COMPILE_SYNTAX_CHECK, cause);
	}

	public function new(source:String, line:Int, column:Int, sym:Symbol, phase:Keyword, cause:Exception) {
		super(makeMsg(source, line, column, sym, phase, cause), cause);
		this.source = source;
		this.line = line;
		var m:Associative = RT.map(ERR_PHASE, phase, ERR_LINE, line, ERR_COLUMN, column);
		if (source != null)
			m = RT.assoc(m, ERR_SOURCE, source);
		if (sym != null)
			m = RT.assoc(m, ERR_SYMBOL, sym);
		this.data = m;
	}

	public function getData():IPersistentMap {
		return data;
	}

	private static function verb(phase:Keyword):String {
		if (PHASE_READ.equals(phase)) {
			return "reading source";
		} else if (PHASE_COMPILE_SYNTAX_CHECK.equals(phase) || PHASE_COMPILATION.equals(phase)) {
			return "compiling";
		} else {
			return "macroexpanding";
		}
	}

	public static function makeMsg(source:String, line:Int, column:Int, sym:Symbol, phase:Keyword, cause:Exception):String {
		return (PHASE_MACROEXPANSION.equals(phase) ? "Unexpected error " : "Syntax error ")
			+ verb(phase)
			+ " "
			+ (sym != null ? sym + " " : "")
			+ "at ("
			+ (source != null && source != "NO_SOURCE_PATH" ? (source + ":") : "")
			+ line
			+ ":"
			+ column
			+ ").";
	}

	override public function toString():String {
		var cause:Exception = this.previous;
		if (cause != null) {
			if (U.instanceof(cause, IExceptionInfo)) {
				var data:IPersistentMap = cast(cause, IExceptionInfo).getData();
				if (PHASE_MACRO_SYNTAX_CHECK.equals(data.valAt(ERR_PHASE)) && data.valAt(SPEC_PROBLEMS) != null) {
					return this.toString();
				} else {
					return this.toString() + "\n" + cause.toString();
				}
			}
		}
		return this.details();
	}
}
