package lang;

interface IReference extends IMeta {
	public function alterMeta(alter:IFn, args:ISeq):IPersistentMap;

	public function resetMeta(m:IPersistentMap):IPersistentMap;
}
