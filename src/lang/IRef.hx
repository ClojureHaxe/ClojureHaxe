package lang;

interface IRef extends IDeref {
	private function setValidator(vf:IFn):Void;

	private function getValidator():IFn;

	private function getWatches():IPersistentMap;

	private function addWatch(key:Any, callback:IFn):IRef;

	private function removeWatch(key:Any):IRef;
}
