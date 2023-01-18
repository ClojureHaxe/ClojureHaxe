package lang;

class TaggedLiteral implements ILookup {
	public static final TAG_KW:Keyword = Keyword.internNSname("tag");
	public static final FORM_KW:Keyword = Keyword.internNSname("form");

	public var tag:Symbol;
	public var form:Any;

	public static function create(tag:Symbol, form:Any):TaggedLiteral {
		return new TaggedLiteral(tag, form);
	}

	public function new(tag:Symbol, form:Any) {
		this.tag = tag;
		this.form = form;
	}

	public function valAt(key:Any, notFound:Any = null):Any {
		if (FORM_KW.equals(key)) {
			return this.form;
		} else if (TAG_KW.equals(key)) {
			return this.tag;
		} else {
			return notFound;
		}
	}

	// @Override
	public function equals(o:Any):Bool {
		if (this == o)
			return true;
		if (o == null || !U.instanceof(o, TaggedLiteral))
			return false;

		var that:TaggedLiteral = cast o;

		if (form != null ? !Util.equals(form, that.form) : that.form != null)
			return false;
		if (tag != null ? !Util.equals(tag, that.tag) : that.tag != null)
			return false;

		return true;
	}

	// @Override
	public function hashCode():Int {
		var result:Int = Util.hash(tag);
		result = 31 * result + Util.hash(form);
		return result;
	}
}
