package lang;

abstract class ATransientSet extends AFn implements ITransientSet {
	@:volatile var impl:ITransientMap;

	public function new(impl:ITransientMap) {
		this.impl = impl;
	}

	public function count():Int {
		return impl.count();
	}

	public function conj(val:Any):ITransientSet {
		var m:ITransientMap = impl.assoc(val, val);
		if (m != impl)
			this.impl = m;
		return this;
	}

	public function contains(key:Any):Bool {
		return this != impl.valAt(key, this);
	}

	public function disjoin(key:Any):ITransientSet {
		var m:ITransientMap = impl.without(key);
		if (m != impl)
			this.impl = m;
		return this;
	}

	public function get(key:Any) {
		return impl.valAt(key);
	}

	override public function invoke2(key:Any, notFound:Any):Any {
		return impl.valAt(key, notFound);
	}

	override public function invoke1(key:Any):Any {
		return impl.valAt(key);
	}
}
