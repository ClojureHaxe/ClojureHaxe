package lang;

import haxe.ds.Vector;

class ChunkBuffer implements Counted {
	var buffer:Vector<Any>;
	var end:Int;

	public function new(capacity:Int) {
		buffer = new Vector<Any>(capacity);
		end = 0;
	}

	public function add(o:Any) {
		buffer[end++] = o;
	}

	public function chunk():IChunk {
		var ret:ArrayChunk = new ArrayChunk(buffer, 0, end);
		buffer = null;
		return ret;
	}

	public function count():Int {
		return end;
	}
}
