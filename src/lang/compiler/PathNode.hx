package lang.compiler;

import lang.Compiler.PATHTYPE;

class PathNode {
	public var type:PATHTYPE;
	public var parent:PathNode;

	public function new(type:PATHTYPE, parent:PathNode) {
		this.type = type;
		this.parent = parent;
	}
}
