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

	/*@:op(A == B)
		public inline function equals(other:Thread):Bool {
			#if (target.threaded)
			return Th.current();
			#else 
			return this == other;
			#end

			return getHandle().id() == other.getHandle().id();
	}*/
	static public function equals(thread1:Any, thread2:Any):Bool {
		#if (target.threaded)
		return (thread1 : Th) == (thread2 : Th);
		#end
		return thread1 == thread2;
	}
}
