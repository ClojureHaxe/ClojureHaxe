package lang;

interface IChunkedSeq extends ISeq extends Sequential {
	public function chunkedFirst():IChunk;

	public function chunkedNext():ISeq;

	public function chunkedMore():ISeq;
}
