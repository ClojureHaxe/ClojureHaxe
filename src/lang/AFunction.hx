package lang;

class AFunction extends AFn implements IObj // TODO: implements Comparator
implements Fn // implements Serializable
{
	// var  __methodImplCache:MethodImplCache;
	public function meta():IPersistentMap {
		return null;
	}

	public function withMeta(meta:IPersistentMap):IObj {
		if (meta == null)
			return this;
		return new RestFnAFunction(this, meta);
	}

	public function compare(o1:Any, o2:Any):Int {
		var o:Any = invoke(o1, o2);

		if (U.instanceof(o, Bool)) {
			if (RT.booleanCast(o))
				return -1;
			return RT.booleanCast(invoke(o2, o1)) ? 1 : 0;
		}

		var n:Int = cast(o, Int);
		return n;
	}
}

class RestFnAFunction extends RestFn {
	var afn:AFunction;
	var _meta:IPersistentMap;

	public function new(afn:AFunction, meta:IPersistentMap) {
		this.afn = afn;
		this._meta = meta;
	}

	public function doInvoke(args:Any):Any {
		return afn.applyTo(cast(args, ISeq));
	}

	override public function meta():IPersistentMap {
		return this._meta;
	}

	override public function withMeta(newMeta:IPersistentMap):IObj {
		if (_meta == newMeta)
			return this;
		return afn.withMeta(newMeta);
	}

	override public function getRequiredArity():Int {
		return 0;
	}
}
