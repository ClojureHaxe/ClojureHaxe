package lang.compiler;

class EmptyExpr implements Expr {
	public var coll:Any;
/*
	static final HASHMAP_TYPE = Type.getType(PersistentArrayMap.class);
	static final HASHSET_TYPE = Type.getType(PersistentHashSet.class);
	static final VECTOR_TYPE = Type.getType(PersistentVector.class);
	static final IVECTOR_TYPE = Type.getType(IPersistentVector.class);
	static final TUPLE_TYPE = Type.getType(Tuple.class);
	static final LIST_TYPE = Type.getType(PersistentList.class);
	static final EMPTY_LIST_TYPE = Type.getType(PersistentList.EmptyList.class);
*/
	public function new(coll:Any) {
		this.coll = coll;
	}

	public function eval():Any {
		return coll;
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (coll instanceof IPersistentList)
				gen.getStatic(LIST_TYPE, "EMPTY", EMPTY_LIST_TYPE);
			else if (coll instanceof IPersistentVector)
				gen.getStatic(VECTOR_TYPE, "EMPTY", VECTOR_TYPE);
			else if (coll instanceof IPersistentMap)
				gen.getStatic(HASHMAP_TYPE, "EMPTY", HASHMAP_TYPE);
			else if (coll instanceof IPersistentSet)
				gen.getStatic(HASHSET_TYPE, "EMPTY", HASHSET_TYPE);
			else
				throw new UnsupportedOperationException("Unknown Collection type");
			if (context == C.STATEMENT) {
				gen.pop();
			}
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			if (coll instanceof IPersistentList)
				return IPersistentList.class;
			else if (coll instanceof IPersistentVector)
				return IPersistentVector.class;
			else if (coll instanceof IPersistentMap)
				return IPersistentMap.class;
			else if (coll instanceof IPersistentSet)
				return IPersistentSet.class;
			else
				throw new UnsupportedOperationException("Unknown Collection type");
		}
	 */
}
