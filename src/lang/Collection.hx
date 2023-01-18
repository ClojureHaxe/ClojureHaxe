package lang;

import haxe.ds.Vector;

interface Collection {
	// some functions from java.util.Collection
	public function size():Int;

	public function isEmpty():Bool;

	public function contains(o:Any):Bool;

	public function toArray():Vector<Any>;

	public function add(e:Any):Bool;

	public function remove(o:Any):Bool;

	public function clear():Void;
}
