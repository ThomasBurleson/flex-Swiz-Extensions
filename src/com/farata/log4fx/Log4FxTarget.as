////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Mindspace, LLC - http://www.gridlinked.info/
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.	
////////////////////////////////////////////////////////////////////////////////

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
	import com.farata.log4fx.localConnection.Logger;
	
	import mx.logging.AbstractTarget;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	
	import org.osflash.thunderbolt.firebug.Logger;
	import org.osflash.thunderbolt.firebug.LoggerUtils;
	
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
			com.farata.log4fx.localConnection.Logger.includeTime = value;
			org.osflash.thunderbolt.firebug.Logger.includeTime = value;
			
		}   		
    		
	     /**
	     *  Setter method for showing caller of a log message
	     * 
		 * @param 	value	Boolean Default value is "true"
		 * 
	     */
		[Inspectable(category="General", defaultValue="true")]		
		public function set showCaller( value: Boolean ):void {
			com.farata.log4fx.localConnection.Logger.showCaller = value;
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
			var showCaller : Boolean = com.farata.log4fx.localConnection.Logger.showCaller;
			
			try {
				com.farata.log4fx.localConnection.Logger.showCaller = org.osflash.thunderbolt.firebug.Logger.showCaller = includeCategory;
				
				var category     : String = getCategoryInfo(event,false);
				var message 	 : String = event.message.length ? event.message : "";
				
				//  Call BOTH the Log4fx viewer and the ThunderBolt console (useful if the Log4Fx viewer is not open)
				com.farata.log4fx.localConnection.Logger.log ( LogEvent.getLevelString( event.level ), category, message );
				org.osflash.thunderbolt.firebug.Logger.log ( getFireBugLevel(event.level) , message );
				
				
			} finally {
				
				// Restore master value...
				com.farata.log4fx.localConnection.Logger.showCaller = org.osflash.thunderbolt.firebug.Logger.showCaller = showCaller;
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
			var level: String = com.farata.log4fx.localConnection.Logger.LOG;			// LogLevel.DEBUG && LogLevel.ALL
			
			switch (logLevel) 
			{
				case LogEventLevel.FATAL:		level = com.farata.log4fx.localConnection.Logger.ERROR;		break;
				case LogEventLevel.ERROR:		level = com.farata.log4fx.localConnection.Logger.ERROR;		break;
				case LogEventLevel.WARN :		level = com.farata.log4fx.localConnection.Logger.WARN;			break;
				case LogEventLevel.INFO :		level = com.farata.log4fx.localConnection.Logger.INFO;			break;
				default 			    : 		level = com.farata.log4fx.localConnection.Logger.LOG;			// LogLevel.DEBUG && LogLevel.ALL
			}
			
			return level;
		} 
		
		private static function getCategoryInfo(event:Object, addSeperator:Boolean=true):String {
			return ILogger( event.target ).category + (addSeperator ? LoggerUtils.FIELD_SEPERATOR : "");
		}		    
		
	}

}