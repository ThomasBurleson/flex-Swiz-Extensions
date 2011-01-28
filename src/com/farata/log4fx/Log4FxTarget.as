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

package com.farata.log4fx
{
	import com.farata.log4fx.utils.LoggerUtils;
	
	import mx.logging.AbstractTarget;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	
	import org.osflash.thunderbolt.FireBugLogger;
	
	public class Log4FxTarget extends AbstractTarget {

		[Inspectable(category="General", defaultValue="true")]	   	    	
		public var includeLevel: Boolean = true;
		
		[Inspectable(category="General", defaultValue="false")]	   	    	
		public var includeCategory: Boolean = false;
	
		 
	     /**
	     *  Setter method for using a timestamp
	     * 
		 * @param 	value	Boolean - default value is "true"
		 * 
	     */
		[Inspectable(category="General", defaultValue="true")]		
		public function set includeTime( value: Boolean ):void {
			LocalConnectionLogger.includeTime = value;
			FireBugLogger.includeTime = value;
			
		}   		
    		
	     /**
	     *  Setter method for showing caller of a log message
	     * 
		 * @param 	value	Boolean Default value is "true"
		 * 
	     */
		[Inspectable(category="General", defaultValue="true")]		
		public function set showCaller( value: Boolean ):void {
			LocalConnectionLogger.showCaller = value;
			FireBugLogger.showCaller = value;
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
			var showCaller : Boolean = LocalConnectionLogger.showCaller;
			
			try {
				LocalConnectionLogger.showCaller = FireBugLogger.showCaller = includeCategory;
				
				var category     : String = getCategoryInfo(event,false);
				var message 	 : String = event.message.length ? event.message : "";
				
				//  Call BOTH the Log4fx viewer and the ThunderBolt console (useful if the Log4Fx viewer is not open)
				LocalConnectionLogger.log ( LogEvent.getLevelString( event.level ), category, message );
				FireBugLogger.log ( getFireBugLevel(event.level) , message );
				
				
			} finally {
				
				// Restore master value...
				LocalConnectionLogger.showCaller = FireBugLogger.showCaller = showCaller;
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
		private static function getFireBugLevel (logLevel: int): String{
			var level: String = LocalConnectionLogger.LOG;			// LogLevel.DEBUG && LogLevel.ALL
			
			switch (logLevel) 
			{
				case LogEventLevel.INFO:		level = LocalConnectionLogger.INFO;		break;
				case LogEventLevel.WARN:		level = LocalConnectionLogger.WARN;		break;				
				case LogEventLevel.ERROR:		level = LocalConnectionLogger.ERROR;		break;
				
				// Firebug doesn't support a fatal level
				case LogEventLevel.FATAL:		level = LocalConnectionLogger.ERROR;		break;
			}
			
			return level;
		} 
		
		private static function getCategoryInfo(event:Object, addSeperator:Boolean=true):String {
			return ILogger( event.target ).category + (addSeperator ? LoggerUtils.FIELD_SEPERATOR : "");
		}		    
		
	}

}