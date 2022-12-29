package lang;

class LineNumberingPushbackReader {
	static private final NEW_LINE = "\n".code;

	var s:String;
	var index:Int = 0;
	var lineNumber = 1;
	var columnNumber = 1;

	public function new(s:String) {
		this.s = s;
	}

	public function read():Int {
		if (index < s.length) {
			var c:Int = s.charCodeAt(index);
			if (c == NEW_LINE) {
				lineNumber++;
				columnNumber = 1;
			} else {
				columnNumber++;
			}
			index++;
			return c;
		}
		return -1;
	}

	public function unread() {
		index--;
		if (s.charCodeAt(index) == NEW_LINE) {
			columnNumber = 0;
			lineNumber--;
		}
	}

	public function getLineNumber():Int {
		return lineNumber;
	}

	public function getColumnNumber():Int {
		return columnNumber;
	}
}
