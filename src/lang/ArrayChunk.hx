package lang;

import lang.exceptions.ArityException;
import haxe.ds.Vector;
import lang.exceptions.IllegalStateException;

class ArrayChunk implements IChunk {
	final array:Vector<Any>;
	final off:Int;
	final end:Int;

	public function new(array:Vector<Any>, ?off:Int = null, ?end:Int = null) {
		this.array = array;
		this.off = (off == null ? 0 : off);
		this.end = (end == null ? array.length : end);
	}

	public function nth1(i:Int) {
		return array[off + i];
	}

	public function nth2(i:Int, notFound:Any) {
		if (i >= 0 && i < count())
			return nth1(i);
		return notFound;
	}

	public function nth(...args:Any):Any {
		switch (args.length) {
			case 1:
				return nth1(args[0]);
			case 2:
				return nth2(args[0], args[1]);
			default:
				return new ArityException(args.length, U.getClassName(this));
		}
	}

	public function count():Int {
		return end - off;
	}

	public function dropFirst():IChunk {
		if (off == end)
			throw new IllegalStateException("dropFirst of empty chunk");
		return new ArrayChunk(array, off + 1, end);
	}

	public function reduce2(f:IFn, start:Any) {
		var ret:Any = f.invoke2(start, array[off]);
		if (RT.isReduced(ret))
			return ret;
		var x:Int = off + 1;
		while (x < end) {
			ret = f.invoke(ret, array[x]);
			if (RT.isReduced(ret))
				return ret;
			x++;
		}
		return ret;
	}
}
