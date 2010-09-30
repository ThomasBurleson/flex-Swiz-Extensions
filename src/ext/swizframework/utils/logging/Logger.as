/*
* Copyright 2010 Swiz Framework Contributors
* 
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License. You may obtain a copy of
* the License. You may obtain a copy of the License at
* 
* http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
* License for the specific language governing permissions and limitations under
* the License.
*/

package ext.swizframework.utils.logging
{
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	
	public class Logger extends EventDispatcher implements ILogger
	{
		public static function getLogger( target:Object ):ILogger	{	
			return LoggerRegistry.getLogger(target);
		}
		
		public static function addLoggingTarget( loggingTarget:ILoggingTarget ):void {
			LoggerRegistry.addLoggingTarget(loggingTarget);
		}
		
		// ========================================
		// instance stuff below
		// ========================================
		
		protected var _category:String;
		
		public function Logger( className:String = "" )
		{
			super();
			
			_category = className;
		}
		
		/**
		 *  The category this logger send messages for.
		 */
		public function get category():String
		{
			return _category;
		}
		
		protected function constructMessage( msg:String, params:Array ):String
		{
			// replace all of the parameters in the msg string
			for( var i:int = 0; i < params.length; i++ )
			{
				msg = msg.replace( new RegExp( "\\{" + i + "\\}", "g" ), params[ i ] );
			}
			return msg;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 *  @inheritDoc
		 */
		public function log( level:int, msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), level ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function debug( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.DEBUG ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function info( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.INFO ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function warn( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.WARN ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function error( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.ERROR ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function fatal( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.FATAL ) );
			}
		}
	}
}
