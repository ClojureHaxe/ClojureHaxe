package lang;

final class Murmur3 {
	private static final seed = 0;
	private static final C1 = 0xcc9e2d51;
	private static final C2 = 0x1b873593;

	public static function hashInt(input:Int):Int {
		if (input == 0)
			return 0;
		var k1:Int = mixK1(input);
		var h1:Int = mixH1(seed, k1);

		return fmix(h1, 4);
	}

	/*
		public static function hashLong(input:Int64):Int {
			if (input == 0) return 0;
			int low = (int) input;
			int high = (int) (input >>> 32);

			int k1 = mixK1(low);
			int h1 = mixH1(seed, k1);

			k1 = mixK1(high);
			h1 = mixH1(h1, k1);

			return fmix(h1, 8);
		}
	 */
	public static function hashUnencodedChars(input:String):Int {
		if (input == null){
			return 0;
		}
		var h1:Int = seed;

		// step through the CharSequence 2 chars at a time
		var i = 1;
		while (i < input.length) {
			var k1:Int = input.charCodeAt(i - 1) | (input.charCodeAt(i) << 16);
			k1 = mixK1(k1);
			h1 = mixH1(h1, k1);
			i++;
		}

		// deal with any remaining characters
		if ((input.length & 1) == 1) {
			var k1:Int = input.charCodeAt(input.length - 1);
			k1 = mixK1(k1);
			h1 ^= k1;
		}

		return fmix(h1, 2 * input.length);
	}

	public static function mixCollHash(hash:Int, count:Int):Int {
		var h1:Int = seed;
		var k1:Int = mixK1(hash);
		h1 = mixH1(h1, k1);
		return fmix(h1, count);
	}

	public static function hashOrdered<T>(xs:Iterable<T>):Int {
		var n = 0;
		var hash = 1;

		for (x in xs.iterator()) {
			hash = 31 * hash + Util.hasheq(x);
			++n;
		}

		return mixCollHash(hash, n);
	}

	public static function hashUnordered(xs:Iterable<Any>):Int {
		var hash:Int = 0;
		var n:Int = 0;
		for (x in xs.iterator()) {
			hash += Util.hasheq(x);
			++n;
		}

		return mixCollHash(hash, n);
	}

	private static function mixK1(k1:Int):Int {
		k1 *= C1;
		// k1 = Integer.rotateLeft(k1, 15);
		k1 = (k1 << 15) | (k1 >>> 17);
		k1 *= C2;
		return k1;
	}

	private static function mixH1(h1:Int, k1:Int):Int {
		h1 ^= k1;
		// h1 = Integer.rotateLeft(h1, 13);
		h1 = (h1 << 13) | (h1 >>> 19);
		h1 = h1 * 5 + 0xe6546b64;
		return h1;
	}

	// Finalization mix - force all bits of a hash block to avalanche
	private static function fmix(h1:Int, length:Int):Int {
		h1 ^= length;
		h1 ^= h1 >>> 16;
		h1 *= 0x85ebca6b;
		h1 ^= h1 >>> 13;
		h1 *= 0xc2b2ae35;
		h1 ^= h1 >>> 16;
		return h1;
	}
}
