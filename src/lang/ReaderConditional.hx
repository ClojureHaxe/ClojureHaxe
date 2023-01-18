package lang;

class ReaderConditional implements ILookup {
	public static final FORM_KW:Keyword = Keyword.intern1("form");
	public static final SPLICING_KW:Keyword = Keyword.intern1("splicing?");

	public var form:Any;
	public var splicing:Bool;

	public static function create(form:Any, splicing:Bool):ReaderConditional {
		return new ReaderConditional(form, splicing);
	}

	private function new(form:Any, splicing:Bool) {
		this.form = form;
		this.splicing = splicing;
	}

	public function valAt(key:Any, notFound:Any = null):Any {
		if (FORM_KW.equals(key)) {
			return this.form;
		} else if (SPLICING_KW.equals(key)) {
			return this.splicing;
		} else {
			return notFound;
		}
	}

	// @Override
	public function equals(o:Any):Bool {
		if (this == o)
			return true;
		if (o == null || !U.instanceof(o, ReaderConditional))
			return false;
		var that:ReaderConditional = cast o;
		if (form != null ? !Util.equals(form, that.form) : that.form != null)
			return false;
		if (splicing != null ? !Util.equals(splicing, that.splicing) : that.splicing != null)
			return false;
		return true;
	}

	// @Override

	public function hashCode():Int {
		var result:Int = Util.hash(form);
		result = 31 * result + Util.hash(splicing);
		return result;
	}
}
