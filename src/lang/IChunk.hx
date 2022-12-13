package lang;

interface IChunk extends Indexed {
	public function dropFirst():IChunk;

	public function reduce2(f:IFn, start:Any):Any;
}
