/**
* Logging Flex and Flash projects using LocalConnection and Farata Log4fx External Viewer
* 
* @version	0.9
* @date		01/27/2011
*
* @author	Thomas Burleson [www.gridlinked.info]
*
*/

package com.farata.log4fx.localConnection
{
	import flash.net.LocalConnection;
	
	import org.osflash.thunderbolt.firebug.LoggerUtils;
	
	public class Logger
	{
		public static const INFO  : String = "info";
		public static const WARN  : String = "warn";
		public static const ERROR : String = "error";
		public static const LOG	  : String = "log";

		// public vars
		public static var includeTime	: Boolean = true;
		public static var showCaller	: Boolean = true;
		
		/**
		 * Logs info messages including objects for calling Firebug
		 * 
		 * @param 	msg				String		log message 
		 * @param 	logObjects		Array		Array of log objects using rest parameter
		 * 
		 */		
		public static function info (msg: String = null, ...logObjects): void
		{
			Logger.log( Logger.INFO, "", msg, logObjects );			
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
			Logger.log( Logger.WARN, "", msg, logObjects );			
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
			Logger.log( Logger.ERROR, "", msg, logObjects );			
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
			Logger.log( Logger.LOG, "", msg, logObjects );			
		}		
	    					 
		/**
		 * Writes log information to local Connection with Farata Log4Fx Viewer
		 * Add time	to log message, get package and class name + line number; using getStackTrace();
		 * And then add message text to log message
		 * 
		 * @param 	level		String			log level 
 		 * @param 	msg			String			log message 
		 * @param 	logObjects	Array			Array of log objects
		 */			 
		public static function log (level: String, category:String="", msg: String = "", logObjects: Array = null): void {
		 	var logMsg : String = "";
			
				logMsg += showCaller  ? LoggerUtils.logCaller()      : "";            			
				logMsg += msg;
				
		 	// send message	to the logging system
			connection.send(logMsg, category, level, new Date());
    			
			if (logObjects != null) {
				var i: int = 0, l: int = logObjects.length;	 	
				for (i = 0; i < l; i++) 
				{
					connection.send (LoggerUtils.logObject(logObjects[i]), category, level, new Date());
				}					
			}
				
		}
		
		
		private static function get connection():Log4FxConnection {
			if ( _aConnection == null ) _aConnection = new Log4FxConnection();
			return _aConnection;
		}
		private static var _aConnection : Log4FxConnection = null;
		
	}
}



import flash.errors.EOFError;
import flash.events.StatusEvent;
import flash.events.TimerEvent;
import flash.net.LocalConnection;
import flash.utils.ByteArray;
import flash.utils.Timer;

class Log4FxConnection {
	
	public var maxQueueSize : Number = 5000000;		// 500 Kb
	
	public function Log4FxConnection(destinationID:String=null) {
		_destination = (destinationID == null) ? DEFAULT_CONNECTION_ID : destinationID;
		establishConnection();
	}
	
	
	/**
	 * Send a msg to the Log4Fx receiver/viewer. If the connect has not yet been established, then place the message 
	 * in a queue that will be batched delivered once the connection is ready.
	 *  
	 * @param msg			String
	 * @param category		String
	 * @param level			String (warn,debug,fatal, info)
	 * @param time			Date   
	 * 
	 */
	public function send (msg:String, category:String, level:String, time:Date=null):void {
		if (msg != "") 				addToQueue(msg,category,level,time);
		if (_isConnected == true) 	processQueue();
	}
	
	/**
	 * Establish a connection to the Log4Fx Viewer (receiver). If fails, then wait 2 seconds and try again... 
	 * This process implementation attempts to act as [exclusively] a receiver. If connect() succeeds, then another Viewer is not yet listening so
	 * close immediately and try again later.
	 * 
	 */
	private function establishConnection():void {
		_connection = new LocalConnection();
		_connection.addEventListener(StatusEvent.STATUS,onStatus_establishConnection,false,0,true);
		
		try {
			// Try to start as the receiving part....
			// If the connection worked then the Log4Fx Viewer has not been started!
			// Close the connection and poll every 2 secs to see if the connection has started...
			
			_connection.connect(_destination);
			_connection.close();
			
			_autoConnector = new Timer(2);
			_autoConnector.addEventListener(TimerEvent.TIMER,onPolling_establishConnection,false,0,true);
			_autoConnector.start();
			
		} catch (error:*) {
			// Destination is already open for sending... GOOD!
			_isConnected = true;
		}
	}
	
	/**
	 * Asynchronous response to send() method
	 *  
	 * @param event
	 */
	private function onStatus_establishConnection(event:StatusEvent):void {
		
		switch(event.level) {
			case 'error':	{
				_stopped = true;
				break;
			}
				
		}
	}
	
	/**
	 * Timer event handler that provides a continuous polling to determine if the Log4Fx viewer has been
	 * started. Once started, the connection is established and the timer is deactivated.
	 *  
	 * @param e
	 */
	private function onPolling_establishConnection(e:TimerEvent):void {
		try {
		
			_connection.connect(_destination);
			_connection.close();

		} catch (error:*) {
			// If the connection failed, then the Log4Fx viewer has been opened...
			
			_autoConnector.stop();
			_autoConnector.removeEventListener(TimerEvent.TIMER,onPolling_establishConnection);
			
			// Destination has been opened for sending... GOOD!
			_isConnected = true;
			
			processQueue();
		}
	}
	
	
	/**
	 * Place the message at the end of the queue. Note that the LocalConnection only supports send() operations with data <= 32K. 
	 * If the message size is greater, then the message should be partitioned into smaller sections for iterative delivery. 
	 *  
	 * @param msg
	 * @param category
	 * @param level
	 * @param time
	 * 
	 */
	private function addToQueue(msg:String, category:String, level:String, time:Date=null):void {
		if (msg == "") return;
		
		var numChars : int    = 0;
		var segment  : String = "";
		var buffer   : *      = new ByteArray();
		
			buffer.writeMultiByte(msg,"UTF-8");
			buffer.position = 0;
		
		do {
			// partition the msg into section sizes that can be delivered via the LocalConnection pipeline
			try {
				numChars = (buffer.length - buffer.position) < MAX_LOCAL_CONNECTION_BYTES ? (buffer.length - buffer.position) : MAX_LOCAL_CONNECTION_BYTES;
				segment  = buffer.readUTFBytes(numChars);
				
				_messageQueue.push( new QueueItem(segment,category,level,time) );
				
			} catch (e:EOFError) {
				break;
			}
			
		} while (buffer.position < buffer.length);
		
		// Clip queue size to maxLimit (if needed)
		
		while (queueSize > maxQueueSize) {
			// Remove oldes first...
			_messageQueue.shift();
		}
	}
	
	/**
	 * Using a FIFO algorithm, sequentially deliver all messages in the current queue.
	 * This implementation supports dynamic additions of messages to the queue end while processing is still
	 * running.  
	 */
	private function processQueue():void {
		if (_isSending == true) return;
		
		try {
			_isSending = true;
			
			while (_messageQueue.length > 0  && !_stopped) {
				var it : QueueItem = _messageQueue.shift();

				_connection.send( _destination,_handler,it.msg, it.category, it.level,it.time );
			}
			
		} finally {
			_isSending 	= false;
			_stopped    = false;
		}
	}
	
	
	private function get queueSize():Number {
		var results : Number = 0;
		
		_messageQueue.forEach(
			function(it:QueueItem, index:int, arr:Array):void {
				results += it.msg.length;
			});
		
		return results;
	}
	
	// If you are implementing communication between different domains, you need to define connectionName 
	// in both the sending and receiving LocalConnection objects in such a way that the current superdomain 
	// is not added to connectionName, we use a "_" to prevent superDomain addition.
	
	private var _destination	: String  		  = "";
	private var _handler 		: String		  = "lcHandler";
	
	private var _isConnected	: Boolean         = false;
	private var _stopped		: Boolean         = false;
	private var _connection 	: LocalConnection = null;
				
	private var _autoConnector  : Timer           = null;
	
	private var _messageQueue   : Array           = [ ];
	private var _isSending		: Boolean         = false;
	
	private static const DEFAULT_CONNECTION_ID      : String = "_LocalPanelLog";
	private static const MAX_LOCAL_CONNECTION_BYTES : Number = 32768;

}

class QueueItem {
	
	public var msg		:String,
			   category	:String, 
			   level	:String, 
			   time		:Date=null;
			   
		public function QueueItem(msg:String, category:String, level:String, time:Date=null) {
			this.msg 		= msg;
			this.category 	= category;
			this.level		= level;
			this.time		= time;
		}
}