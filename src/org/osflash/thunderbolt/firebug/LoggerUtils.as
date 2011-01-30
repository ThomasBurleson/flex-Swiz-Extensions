/**
* Logging Flex and Flash projects using LocalConnection and Farata Log4fx External Viewer
* 
* @version	0.9
* @date		01/27/2011
*
* @author	Thomas Burleson [www.gridlinked.info]
*
* 
*/

package org.osflash.thunderbolt.firebug
{
	import flash.system.System;
	import flash.utils.describeType;
	
	public class LoggerUtils
	{
		public static var groupCallback : Function = function(groupAction: String, msg: String = ""):void {; };
		
		public static const GROUP_START: String = "group";
		public static const GROUP_END  : String = "groupEnd";
		
		public static var FIELD_SEPERATOR: String = " :: ";

		/**
		 * Calculates the amount of memory in MB and Kb currently in use by Flash Player
		 * @return 	String		Message about the current value of memory in use
		 *
		 * Tip: For detecting memory leaks in Flash or Flex check out WSMonitor, too.
		 * @see: http://www.websector.de/blog/2007/10/01/detecting-memory-leaks-in-flash-or-flex-applications-using-wsmonitor/ 
		 *
		 */		 
		public static function memorySnapshot():String
		{
			var currentMemValue: uint = System.totalMemory;
			var message: String = 	"Memory Snapshot: " 
				+ Math.round(currentMemValue / 1024 / 1024 * 100) / 100 
				+ " MB (" 
				+ Math.round(currentMemValue / 1024) 
				+ " kb)";
			return message;
		}
		
		/**
		 * Creates a String of valid time value
		 * @return 			String 		current time as a String using valid hours, minutes, seconds and milliseconds
		 */
		
		public static function getCurrentTime ():String
		{
			var currentDate: Date   =   new Date();
			var currentTime: String = 	""
				+ timeToValidString(currentDate.getHours()) 
				+ ":" 
				+ timeToValidString(currentDate.getMinutes()) 
				+ ":" 
				+ timeToValidString(currentDate.getSeconds()) 
				+ "." 
				+ timeToValidString(currentDate.getMilliseconds()) + FIELD_SEPERATOR;
			
			return currentTime;
		}
		
		/**
		 * Logs nested instances and properties
		 * 
		 * @param 	logObj		Object		log object
		 * @param 	id			String		short description of log object
		 */	
		public static function logObject (logObj:*, id:String = null, depth:int=0): String {
			var results : String = "";
			
			_stopLog = (depth == 0) ? false : _stopLog;
			
			if ( depth < MAX_DEPTH ) {
				++ depth;
				
				var propID: String = id || "";
				var description:XML = describeType(logObj);				
				var type: String = description.@name;
				
				if (primitiveType(type))
				{					
					var msg: String = (propID.length) 	? 	"[" + type + "] " + propID + " = " + logObj
														: 	"[" + type + "] " + logObj;
															
					results = msg;
				}
				else if (type == "Object")
				{
					groupCallback( GROUP_START, "[Object] " + propID);
					
				  	for (var element: String in logObj)
				  	{
					  	results += logObject(logObj[element], element, depth) + "\r";	
				  	}
					
					groupCallback( GROUP_END );
				}
				else if (type == "Array")
				{
					groupCallback( GROUP_START, "[Array] " + propID );
					
					var i: int = 0, max: int = logObj.length;					  					  	
				  	for (i; i < max; i++)
				  	{
						results += logObject(logObj[i], String(i), depth) + "\r";
				  	}
				  	
					groupCallback( GROUP_END );
				}
				else
				{
					// log private props as well - thx to Rob Herman [http://www.toolsbydesign.com]
					var list: XMLList = description..accessor;					
					
					if (list.length())
					{
						for each(var item: XML in list)
						{
							var propItem: String = item.@name;
							var typeItem: String = item.@type;							
							var access: String = item.@access;
							
							// log objects && properties accessing "readwrite" and "readonly" only 
							if (access && access != "writeonly") 
							{
								//TODO: filter classes
								// var classReference: Class = getDefinitionByName(typeItem) as Class;
								var valueItem: * = logObj[propItem];
								results += logObject(valueItem, propItem, depth) + "\r";
							}
						}					
					}
					else
					{
						results += logObject(logObj, type, depth) + "\r";				
					}
				}
			}
			else {
				// call one stop message only
				if (!_stopLog)
				{
					Logger.send( "STOP LOGGING: More than " + depth + " nested objects or properties.", Logger.WARN );
					_stopLog = true;
				}			
			}
			
			
			return results;
		}
		
	    /** 
	    * Message about details of a caller who logs anything
	    * @return String	message of details
	    */
		public static function logCaller(): String
		{
 			var debugError : Error  = null;
 			var message    : String = '';
			
            try {
            	
				debugError = new Error();
				
            } finally {
				
            	// track all stacks only if we have a stackTrace
            	var stackTrace:String = debugError.getStackTrace();
				
				if ( stackTrace != null ) {
 		    		var stacks:Array = stackTrace.split("\n");

		    		if ( stacks != null ) {
						// special stack data for using ThunderBoldTarget which is a subclass of mx.logging.AbstractTarget
						// show details of stackData only if it available
						
						var isValidStack : Boolean   = (String(stacks[4]).indexOf("mx.logging::AbstractTarget") > -1) &&  (stacks.length >= 9); 
		    			var data         : StackData = isValidStack ? LoggerUtils.stackDataFromStackTrace( stacks[ 8 ] ) : null;
		    			
						if ( data != null ) {
							message += (data.packageName && data.packageName != "") ? data.packageName + "." : data.packageName;
							message += data.className;
							message += (data.lineNumber > 0) ? " [" + data.lineNumber + "]" + FIELD_SEPERATOR : "";  
						}
		    		}  		    			
	    		}               
            }
                       
            return cleanLog(message);	
		}
		
		
		private static function cleanLog(logMsg:String):String {
			
			var offset : int = logMsg.indexOf("Function/"); 
			if (offset > -1) logMsg = logMsg.replace("Function/","");
			
			return logMsg;
			
		}

		
		
		
		/**
		 * Checking for primitive types
		 * 
		 * @param 	type				String			type of object
		 * @return 	isPrimitiveType 	Boolean			isPrimitiveType
		 * 
		 */							
		private static function primitiveType (type: String): Boolean
		{
			var isPrimitiveType: Boolean = false;
			
			switch (type) 
			{
				case "Boolean"	:
				case "void"		:
				case "int"		:
				case "uint"		:
				case "Number"	:
				case "String"	:
				case "undefined":
				case "null"		:	isPrimitiveType = true;		break;			
			}
			
			return isPrimitiveType;
		}
		
		
		
		/**
		 * Creates a valid time value
		 * @param 	timeValue	Number     	Hour, minute or second
		 * @return 				String 		A valid hour, minute or second
		 */
		
		private static function timeToValidString(timeValue: Number):String
		{
			return timeValue > 9 ? timeValue.toString() : "0" + timeValue.toString();
		}
		
		
		/** 
		 * Get details of a caller of the log message
		 * which based on Jonathan Branams MethodDescription.createFromStackTrace();
		 * 
		 * @see: http://github.com/jonathanbranam/360flex08_presocode/
		 * 
		 */
		private static function stackDataFromStackTrace(stackTrace: String): StackData {
			// Check stackTrace - Note: It seems that there some issues to match it using Flash IDE, so we use an empty Array instead
			var matches:Array = stackTrace.match(/^\tat (?:(.+)::)?(.+)\/(.+)\(\)\[(?:(.+)\:(\d+))?\]$/) || new Array(); 				
			
			function match(j:int,defaultVal:*=""):String {
				return (j < matches.length) ? matches[j] : defaultVal;
			}
			
			return  new StackData(match(1), match(2), match(3),match(4), match(5,0));
		}	    
		
		// private vars	
		private static const MAX_DEPTH: int = 255;
	
			
		
		
		private static var _stopLog: Boolean = false;
	}

}

/**
* Stackdata for storing all data throwing by an error
* 
*/

internal class StackData
{
	public var packageName	: String;
	public var className	: String;
	public var methodName	: String;
	public var fileName		: String;
	public var lineNumber	: int;
	
	public function StackData(packageName:String, className:String, methodName:String, fileName:String, lineNumber:int) {
		this.packageName = packageName == null ? "" : packageName;
		this.className	 = className;
		this.methodName	 = methodName;
		this.fileName	 = fileName;
		this.lineNumber	 = lineNumber;
	}
	
	public function toString(): String
	{
		var s: String = "packageName " + packageName
						+ " // className " + className
						+ " // methodName " + methodName
						+ " // fileName " + fileName
						+ "// lineNumber " + lineNumber;
		return s;

	}
}