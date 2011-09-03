package utils.string
{
	/**
	 * Convert the String to an array
	 */
	
	public function toArray(obj:Object = null, delimiter:String = null):Array
	{
		if (obj is Array) 					return (obj as Array);
		if ((obj is String) && delimiter)   return (obj as String).split(delimiter);
		if (obj && !delimiter)				return [ obj ];
		
		return null;
	}
}