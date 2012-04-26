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

package org.osflash.thunderbolt.firebug
{
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.system.Security;
	
	/**
	* Thunderbolts AS3 Logger class
	* 
	*/
	
	public class Logger
	{
		// Firebug supports 5 log levels only
		public static const INFO : String = "info";
		public static const WARN : String = "warn";
		public static const ERROR: String = "error";
		public static const DEBUG: String = "debug";
		public static const LOG	 : String = "log";

		public static const FIREBUG_METHODS: Array = [ERROR, WARN, INFO, DEBUG, LOG];

		// public vars
		public static var includeTime: Boolean = true;
		public static var showCaller : Boolean = true;
			
		/**
		 * Information about the current version of ThunderBoltAS3
		 *
		 */		 
		public static function about():void
	    {
			var VERSION: String = "2.3";
			var AUTHOR : String = "Jens Krause [www.websector.de] & Thomas Burleson [www.gridlinked.info]";
	        var message: String = 	"+++ Welcome to ThunderBolt AS3 | VERSION: " 
	        						+ VERSION 
	        						+ " | AUTHOR: " 
	        						+ AUTHOR 
	        						+ " | Happy logging +++";
			Logger.info (message);
	    }
	
		
				
		/**
		 * Logs info messages including objects for calling Firebug
		 * 
		 * @param 	msg				String		log message 
		 * @param 	logObjects		Array		Array of log objects using rest parameter
		 * 
		 */		
		public static function info (msg: String = null, ...logObjects): void
		{
			Logger.log( Logger.INFO, msg, logObjects );			
		}
		
		/**
		 * Logs warn messages including objects for calling Firebug
		 * 
		 * @param 	msg				String		log message 
		 * @param 	logObjects		Array		Array of log objects using rest parameter
		 * 
		 */		
		public static function warn (msg: String = null, ...logObjects): void
		{
			Logger.log( Logger.WARN, msg, logObjects );			
		}

		/**
		 * Logs error messages including objects for calling Firebug
		 * 
		 * @param 	msg				String		log message 
		 * @param 	logObjects		Array		Array of log objects using rest parameter
		 * 
		 */		
		public static function error (msg: String = null, ...logObjects): void
		{
			Logger.log( Logger.ERROR, msg, logObjects );			
		}
		
		/**
		 * Logs debug messages messages including objects for calling Firebug
		 * 
		 * @param 	msg				String		log message 
		 * @param 	logObjects		Array		Array of log objects using rest parameter
		 * 
		 */		
		public static function debug (msg: String = null, ...logObjects): void
		{
			Logger.log( Logger.DEBUG, msg, logObjects );			
		}		
			
		/**
		 * Hides the logging process calling Firebug
		 * @param 	value	Boolean     Hide or show the logs of ThunderBolt within Firebug. Default value is "false"
		 */		 
		public static function set hide(value: Boolean):void
	    {
	        _enabled = value;
	    }

		/**
		 * Flag to use console trace() methods
		 * @param 	value	Boolean     Flag to use Firebug or not. Default value is "true".
		 */		 
		public static function set console(value: Boolean):void
	    {
			_isFireBug = isFireBugAvailable() && !value;
	    }
	    					 
		/**
		 * Calls Firebugs command line API to write log information
		 * 
		 * @param 	level		String			log level 
 		 * @param 	msg			String			log message 
		 * @param 	logObjects	Array			Array of log objects
		 */			 
		public static function log (level: String, msg: String = "", logObjects: Array = null): void
		{
		 	var logMsg: String = "";
			
			if( _enabled == false)
			{
				logMsg += includeTime ? LoggerUtils.getCurrentTime() : "";
				logMsg += showCaller  ? LoggerUtils.logCaller() 	 : "";
			 	logMsg += msg;
				
			 	send( logMsg, level );
	    			
			 	// log objects	
				if (logObjects != null){
					
					_logLevel = level;
					LoggerUtils.groupCallback = handleGroupAction;
					
					for (var i:int = 0; i < logObjects.length; i++) 
					{
						send( LoggerUtils.logObject(logObjects[i]), level );
			    	}					
				}				
			}
	 	
		}


		
		
		/**
		 * Call wheter to Firebug console or 
		 * use the standard trace method logging by flashlog.txt
		 * 
		 * @param 	msg			 String			log message
		 * 
		 */							
		public static function send (msg: String, level:String): void
		{
			if ( _isFireBug == true )	ExternalInterface.call("console." + level, msg);			
			else						trace ( msg);	

		}
		
		/**
		 * Calls an action to open or close a group of log properties
		 * 
		 * @param 	groupAction		String			Defines the action to open or close a group 
		 * @param 	msg			 	String			log message
		 * 
		 */
		private static function handleGroupAction (groupAction: String, msg: String = ""): void
		{
			switch( groupAction ) {
				case LoggerUtils.GROUP_START : 
				{
					if ( _isFireBug ) 	ExternalInterface.call("console.group", msg);
					else 				trace( _logLevel + "." + groupAction + " " + msg);
					break;
				}
				case LoggerUtils.GROUP_END   :
				{
					if ( _isFireBug ) 	ExternalInterface.call("console.groupEnd");		
					else 				trace( _logLevel + "." + groupAction + " " + msg);
					break;
				}
				default						 :
				{
					if ( _isFireBug ) 	ExternalInterface.call("console." + ERROR, "group type has not defined");		
					else 				trace ( ERROR + "group type has not defined");
					break;
				}
			}
		}


		private static function isFireBugAvailable():Boolean
		{
			var isBrowser: Boolean = ( Capabilities.playerType == "ActiveX" || Capabilities.playerType == "PlugIn" );
			
			if ( isBrowser && ExternalInterface.available )
			{
				// check if firebug installed and enabled
				var requiredMethodsCheck:String = "";
				for each (var method:String in FIREBUG_METHODS) {
					
					// Most browsers report typeof function as 'function'
					// Internet Explorer reports typeof function as 'object'
					requiredMethodsCheck += " && (typeof window.console." + method + " == 'function' || typeof window.console." + method + " == 'object') ";
				}
				
				Security.allowDomain("*");
				
				if ( ExternalInterface.call( "function(){ return typeof window.console == 'object' " + requiredMethodsCheck + "}" ) )
					return true;
			}
			
			return false;
		}
		
		
		private static var _logLevel  : String  = "";
		private static var _enabled   : Boolean = false;
		private static var _isFireBug : Boolean = isFireBugAvailable();

	}
	
}
