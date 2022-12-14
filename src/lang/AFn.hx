package lang;

import lang.exceptions.ArityException;

abstract class AFn implements IFn {
	public function call():Any {
		return invoke();
	}

	public function run():Void {
		invoke();
	}

	public function invoke0():Any {
		return throwArity(0);
	}

	public function invoke1(arg1:Any):Any {
		return throwArity(1);
	}

	public function invoke2(arg1:Any, arg2:Any):Any {
		return throwArity(2);
	}

	public function invoke3(arg1:Any, arg2:Any, arg3:Any):Any {
		return throwArity(3);
	}

	public function invoke4(arg1:Any, arg2:Any, arg3:Any, arg4:Any):Any {
		return throwArity(4);
	}

	public function invoke5(arg1:Any, arg2:Any, arg3:Any, arg4:Any, arg5:Any):Any {
		return throwArity(5);
	}

	public function invoke(...args:Any):Any {
		return throwArity(args.length);
	}

	public function applyTo(arglist:ISeq):Any {
		return applyToHelper(this, Util.ret1(arglist, arglist = null));
	}

	public static function applyToHelper(ifn:IFn, arglist:ISeq):Any {
		// TODO: maybe optimize
		switch (arglist.count()) {
			case 0:
				arglist = null;
				return ifn.invoke0();
			case 1:
				return ifn.invoke1(Util.ret1(arglist.first(), arglist = null));
			case 2:
				return ifn.invoke2(arglist.first(), Util.ret1((arglist = arglist.next()).first(), arglist = null));
			case 3:
				return ifn.invoke3(arglist.first(), (arglist = arglist.next()).first(), Util.ret1((arglist = arglist.next()).first(), arglist = null));
			case 4:
				return ifn.invoke4(arglist.first(), (arglist = arglist.next()).first(), (arglist = arglist.next()).first(),
					Util.ret1((arglist = arglist.next()).first(), arglist = null));
			case 5:
				return ifn.invoke5(arglist.first(), (arglist = arglist.next()).first(), (arglist = arglist.next()).first(),
					(arglist = arglist.next()).first(), Util.ret1((arglist = arglist.next()).first(), arglist = null));
			default:
				// TODO: fix
				return ifn.invoke(arglist);
		}
	}

	public function throwArity(n:Int):Any {
		var className:String = U.getClassName(this);
		throw new ArityException(n, className);
	}
}
