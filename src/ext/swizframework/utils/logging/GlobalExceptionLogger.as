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

package ext.swizframework.utils.logging
{
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	import mx.managers.ISystemManager;
	
	/**
	 * For use with Flex SDK 4 and FlashPlayer 10.1 or higher to catch all
	 * unhandled exceptions within Flex 4 applications.
	 * 
	 * This class uses generic properties access and assignments in order
	 * to remove dependencies on flash.events.UncaughtErrorEvent which is only
	 * available in FP 10.1 and Flex 4. 
	 * 
	 * This class will still compile for Flex 3.x but will silently fail and will
	 * not attach a listener for global, unhandled exceptions.
	 * 
	 */
	
	[MIXIN]
	public class GlobalExceptionLogger
	{
		 public var loggingTarget  : ILoggingTarget = null;
		 public var preventDefault : Boolean 		= false;
		 
		 public function get isReady() : Boolean {
			 return (_loaderInfo && _loaderInfo.hasOwnProperty("uncaughtErrorEvents"));
		 } 
		 
		 /**
		  * Constructor with default args to support programmatic instantiation
		  * 
		  * @param preventDefault Boolean to prevent default action after the global exception error has been logged 
		  * @param loggingTarget ILoggingTarget instance
		  * 
		  */
		 public function GlobalExceptionLogger(preventDefault:Boolean=false,loggingTarget:ILoggingTarget=null) {
			 this.preventDefault = preventDefault;
			 this.loggingTarget  = loggingTarget;
			 
			 initUncaughtExceptions();
		 }
		
		/**
		 * Called by SystemManager or FlexModuleFactory after the Flex Application or 
		 * module is initialized. 
		 * 
		 * Requires both Flex 4 SDK and FlashPlayer target of 10.1 or greater
		 * Requires the [MIXIN] metadata on the LogProcessor class...
		 *  
		 * @param sm ISystemManager 
		 * 
		 */		
		public static function init(sm:ISystemManager):void	{
			_loaderInfo = sm.loaderInfo;
		}
		
		// ****************************************************************************
		// Functionality to provide Logging for Unhandled Global Exceptions
		// ****************************************************************************
		
		/**
		 * Listen for global exceptions (so logging will occur); use generic objects
		 * to remove compile-time dependencies on Flex 4 / FP 10.1 requirements
		 */
		private function initUncaughtExceptions():void {
			if (_loaderInfo != null) {
				if (_loaderInfo.hasOwnProperty("uncaughtErrorEvents")) {
					var dispatcher : IEventDispatcher = _loaderInfo["uncaughtErrorEvents"] as IEventDispatcher;
					if (dispatcher != null) {
						dispatcher.addEventListener(UNCAUGHT_ERROR,	onUncaughtError);
					}
				}
			}
		}
		/**
		 * Global Handler for uncaught errors/exceptions simply logs the error
		 *  
		 * @param event flash.events.UncaughtErrorEvent.UNCAUGHT_ERROR 
		 * 
		 */
		private function onUncaughtError(event:Event):void {
			var logger : ILogger = this.getLogger();
			if (event.hasOwnProperty("error")) {
				var info   : Error   = event["error"] as Error;
				
				if (info != null) {
					logger.error("{0}. {1}\n {2}",info.errorID,info.message,info.getStackTrace());
					if (preventDefault == true) event.preventDefault();
				}
			}
		}
		
		/**
		 * Build a default LoggingTarget if not specified in the GlobalExceptionLogger instantiation.
		 * A default LoggingTarget is constructed 1x if not already specified; when the 1st unCaughtError occurs 
		 */
		private function getLogger() : ILogger {
			var results : ILogger = Logger.getLogger("UncaughtException");
			
			// Build a LoggingTarget for all global, unhandled exceptions and register with the Swiz logger
			if (loggingTarget == null) {
				var target : TraceTarget = new TraceTarget();
				
				target.filters			= ["*"];
				target.level 			= LogEventLevel.ALL;
				target.includeDate 		= true;
				target.includeTime 		= true;
				target.includeCategory 	= true;
				target.includeLevel 	= true;
				
				loggingTarget = target;
				loggingTarget.addLogger(results);
			}
			
			return results;
		}		
		
		static private const 	UNCAUGHT_ERROR 	: String 	 = "uncaughtError"; 
		static private  var 	_loaderInfo		: LoaderInfo = null;
		
	}
}