package lang;

class ArraySeq extends ASeq implements IndexedSeq implements IReduce {
	public var array:Array<Any>;
	public var i:Int;

	public static function create(...array:Any):ArraySeq {
		if (array == null || array.length == 0) {
			return null;
		}
		return new ArraySeq(array.toArray(), 0);
	}

	static function createFromObject(array:Any):ISeq {
		var ar:Array<Any> = cast array;
		if (array == null || ar.length == 0)
			return null;
		return new ArraySeq(array, 0);
	}

	public function new(array:Any, i:Int, ?meta:IPersistentMap = null) {
		super(meta);
		this.i = i;
		this.array = cast array;
	}

	public function first():Any {
		if (array != null) {
			return array[i];
		}
		return null;
	}

	public function next():ISeq {
		if (array != null && i + 1 < array.length)
			return new ArraySeq(array, i + 1);
		return null;
	}

	override public function count():Int {
		if (array != null)
			return array.length - i;
		return 0;
	}

	public function index():Int {
		return i;
	}

	override public function withMeta(meta:IPersistentMap):ArraySeq {
		if (super.meta() == meta)
			return this;
		return new ArraySeq(array, i, meta);
	}

	public function reduce1(f:IFn):Any {
		if (array != null) {
			var ret:Any = array[i];
			var x:Int = i + 1;
			while (x < array.length) {
				ret = f.invoke(ret, array[x]);
				if (RT.isReduced(ret))
					return cast(ret, IDeref).deref();
				i++;
			}
			return ret;
		}
		return null;
	}

	public function reduce2(f:IFn, start:Any):Any {
		if (array != null) {
			var ret:Any = f.invoke(start, array[i]);
			var x:Int = i + 1;
			while (x < array.length) {
				if (RT.isReduced(ret))
					return cast(ret, IDeref).deref();
				ret = f.invoke(ret, array[x]);
				i++;
			}
			return ret;
		}
		return null;
	}

	/*public function reduce(...args):Any {
		return null;
	}*/
	public function indexOf(o:Any):Int {
		if (array != null) {
			var j:Int = i;
			while (j < array.length) {
				if (Util.equals(o, array[j]))
					return j - i;
				j++;
			}
		}
		return -1;
	}

	public function lastIndexOf(o:Any):Int {
		if (array != null) {
			if (o == null) {
				var j:Int = array.length - 1;
				while (j >= i) {
					if (array[j] == null)
						return j - i;
					j--;
				}
			} else {
				var j:Int = array.length - 1;
				while (j >= i) {
					if (Util.equals(o, array[j]))
						return j - i;
					j--;
				}
			}
		}
		return -1;
	}

	public function toArray():Array<Any> {
		var sz:Int = this.array.length - this.i;
		// var ret:Array<Any> = new Array<Any>();
		return this.array.slice(i, sz);
	}
}
