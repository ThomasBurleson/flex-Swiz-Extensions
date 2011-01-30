/**
* Logging Flex and Flash projects using Firebug and ThunderBolt AS3
* 
* @version	2.2
* @date		03/06/09
*
* @author	Jens Krause [www.websector.de]
*
* @see		http://www.websector.de/blog/category/thunderbolt/
* @see		http://code.google.com/p/flash-thunderbolt/
* @source	http://flash-thunderbolt.googlecode.com/svn/trunk/as3/
* 
* ***********************
* HAPPY LOGGING ;-)
* ***********************
* 
*/

package org.osflash.thunderbolt
{
	import mx.logging.AbstractTarget;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	import org.osflash.thunderbolt.firebug.Logger;
	
	public class ThunderBoltTarget extends AbstractTarget {

		[Inspectable(category="General", defaultValue="true")]	   	    	
		public var includeLevel: Boolean = true;
		
		[Inspectable(category="General", defaultValue="false")]	   	    	
		public var includeCategory: Boolean = false;
	
		 
	     /**
	     *  Setter method to stop logs
	     * 
		 * @param 	value	Boolean - default value is "false"
		 * 
	     */
		[Inspectable(category="General", defaultValue="false")]		
		public function set hide( value: Boolean ):void {
			org.osflash.thunderbolt.firebug.Logger.hide = value;
		}   		

	     /**
	     *  Setter method for using a timestamp
	     * 
		 * @param 	value	Boolean - default value is "true"
		 * 
	     */
		[Inspectable(category="General", defaultValue="true")]		
		public function set includeTime( value: Boolean ):void {
			org.osflash.thunderbolt.firebug.Logger.includeTime = value;
		}   		
    		
	     /**
	     *  Setter method for using ThunderBolt AS3 console or not
	     * 
		 * @param 	value	Boolean for using console or not. Default value is "false"
		 * 
	     */
		[Inspectable(category="General", defaultValue="false")]		
		public function set console( value: Boolean ):void {
			org.osflash.thunderbolt.firebug.Logger.console = value;
		}   		
    		
	     /**
	     *  Setter method for showing caller of a log message
	     * 
		 * @param 	value	Boolean Default value is "true"
		 * 
	     */
		[Inspectable(category="General", defaultValue="true")]		
		public function set showCaller( value: Boolean ):void {
			org.osflash.thunderbolt.firebug.Logger.showCaller = value;
		}   

	     /**
	     *  Setter method for filters
	     * 
		 * @param 	value	Filters of classes
		 * 
	     */		
		override public function set filters( value: Array ):void {
    		super.filters = value;
    		
    		// includeCategory if we have filters
    		this.includeCategory = ( filters != null && filters.length > 0 );
    		
    	} 	
  		
		// ***************************************************************************
		//  Public Overrides
		// ***************************************************************************
		
		/**
		 *  Listens to an log event based on Flex Logging Framework
		 * 	and calls ThunderBolt trace method
		 * 
		 * @param 	Event	LogEvent
		 * 
		 */
		override public function logEvent( event: LogEvent ):void {
			var showCaller : Boolean = Logger.showCaller;
			
			try {
				org.osflash.thunderbolt.firebug.Logger.showCaller = includeCategory;
				
				var level   	 : String = includeLevel ? getLogLevel( event.level ) : "";
				var message 	 : String = event.message.length ? event.message : ""
				
				// calls ThunderBolt	
				org.osflash.thunderbolt.firebug.Logger.log( level, message );
			} finally {
				
				// Restore master value...
				org.osflash.thunderbolt.firebug.Logger.showCaller = showCaller;
			}
		}   
		
		// ***************************************************************************
		//  Private Methods
		// ***************************************************************************
		
		/**
		 * Translates Flex log levels to Firebugs log levels
		 * 
		 * @param 	int			log level as integer
		 * @return 	String		level description
		 * 
		 */		
		private static function getLogLevel (logLevel: int): String
		{
			var level: String = Logger.LOG;			// LogLevel.DEBUG && LogLevel.ALL
			
			switch (logLevel) 
			{
				
				// Firebug doesn't support a fatal level
				case LogEventLevel.FATAL:	level = Logger.ERROR;	break;
				case LogEventLevel.ERROR:	level = Logger.ERROR;	break;
				case LogEventLevel.WARN	:	level = Logger.WARN;		break;				
				case LogEventLevel.INFO	:	level = Logger.INFO;		break;
				case LogEventLevel.DEBUG:	level = Logger.DEBUG;	break;
				
				default					:	level = Logger.LOG;		break;
				
			}
			
			return level;
		} 
		
		private static function getCategoryInfo(event:Object):String {
			return ILogger( event.target ).category + org.osflash.thunderbolt.firebug.LoggerUtils.FIELD_SEPERATOR;
		}		    
		
	}

}