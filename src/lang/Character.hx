package lang;

class Character {
	static public function isWhitespace(c:Int):Bool {
		return c == " ".code
			|| c == "\n".code
			|| c == "\t".code
			|| c == "\r".code //
			//|| c == 118 // \v
			//|| c == 102 // \f
			// from https://stackoverflow.com/a/11863532
			|| c == 9 // \tab
			|| c == 10 //
			|| c == 11 //
			|| c == 12 //
			|| c == 13 //
			|| c == 28 //
			|| c == 29 //
			|| c == 30 //
			|| c == 31 //
		;
	}

	static public function isDigit(c:Int):Bool {
		return c == '0'.code || c == '1'.code || c == '2'.code || c == '3'.code || c == '4'.code || c == '5'.code || c == '6'.code || c == '7'.code
			|| c == '8'.code || c == '9'.code;
	}

	static public function digit(code:Int, radix:Int):Int {
		if (radix == 10) {
			return Std.parseInt(String.fromCharCode(code));
		} else {
			// TODO:
			return 0;
		}
	}

	static public function isLetter(code:Int):Bool {
		return ((code >= "a".code && code <= "z".code) || (code >= "A".code && code <= "Z".code));
	}
}
