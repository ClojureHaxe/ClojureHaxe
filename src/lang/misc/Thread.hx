package lang.misc;

#if (target.threaded)
import sys.thread.Thread in Th;
#end

class Thread {
	public function new() {};

	// Fake thread for platforms such as JS,
	// always return same "Thread" object
	public static final CURRENT:Thread = new Thread();

	static public function currentThread():Any {
		#if (target.threaded)
		return Th.current();
		#end
		return CURRENT;
	}
}
