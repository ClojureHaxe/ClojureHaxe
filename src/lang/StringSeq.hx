package lang;

class StringSeq extends ASeq implements IndexedSeq implements IDrop implements IReduceInit {
	public final s:String;
	public final i:Int;

	static public function create(s:String):StringSeq {
		if (s.length == 0)
			return null;
		return new StringSeq(null, s, 0);
	}

	function new(meta:IPersistentMap, s:String, i:Int) {
		super(meta);
		this.s = s;
		this.i = i;
	}

	override public function withMeta(meta:IPersistentMap):Obj {
		if (meta == super.meta())
			return this;
		return new StringSeq(meta, s, i);
	}

	public function first():Any {
		return s.charAt(i);
	}

	public function next():ISeq {
		if (i + 1 < s.length)
			return new StringSeq(_meta, s, i + 1);
		return null;
	}

	public function index():Int {
		return i;
	}

	override public function count():Int {
		return s.length - i;
	}

	public function drop(n:Int):Sequential {
		var ii:Int = i + n;
		if (ii < s.length) {
			return new StringSeq(_meta, s, ii);
		} else {
			return null;
		}
	}

	public function reduce2(f:IFn, start:Any):Any {
		var acc:Any = start;
		var ii:Int = i;
		while (ii < s.length) {
			acc = f.invoke(acc, s.charAt(ii));
			ii++;
		}

		return acc;
	}
}
