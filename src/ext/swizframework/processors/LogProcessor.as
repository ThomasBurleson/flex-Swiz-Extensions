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

package ext.swizframework.processors
{
	import ext.swizframework.utils.logging.GlobalExceptionLogger;
	import ext.swizframework.utils.logging.LoggerRegistry;
	
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.processors.ProcessorPriority;
	import org.swizframework.reflection.IMetadataTag;
	
	import ext.swizframework.utils.logging.LoggerRegistry;
	
	/**
	 * This Metadata Tag processor supports the [Log] tag to inject a logger reference.
	 * The power of this processor is that when it attaches/injects a logger reference into a target class
	 * it also creates a custom logger for that same class. The logger is auto-configured to prepend 
	 * Class B's name in the log message. It may also auto-add the target class's package path as a filter to its
	 * custom internal log target.
	 * 
	 * For example consider the target class BeadTester below:
	 * 
	 * 	 class org.test.services.BeadTester {
	 * 
	 *  	[Log]
	 *   	public var log  : ILogger = null;
	 * 
	 *   	public function startTest(testID:String):void {
	 *     		log.debug("startTest(); testID=#"+testID);
	 *   	}
	 *    }
	 *
	 *  and the LogProcessor registered with the Swiz instance using: 
	 * 
	 * 		<swiz:customProcessors>
	 * 			<!-- Let's use the default internal logger, 
	 *               with auto-filters, auto-categories, LogEventLevel.ALL 
	 * 			-->
	 *			<swiz:LogProcessor />
	 *		</swiz:customProcessors>
	 * 
	 *   or use with custom <ILoggingTarget> TraceTarget instance 
	 *  
	 * 		<swiz:customProcessors>
	 *			<ext:LogProcessor>
	 *				<ext:loggingTarget>
	 *					<mx:TraceTarget fieldSeparator="  "
	 *							filters="{['org.test.services.*']}"
	 *							includeCategory="true"
	 *							includeTime="true"
	 *							includeLevel="false"
	 *							level="{LogEventLevel.DEBUG }" />
	 *				</ext:loggingTarget>
	 *			</ext:LogProcessor>
	 *		</swiz:customProcessors>
	 * 
	 * 
 	 *  With the above settings, a call to an instance <BeadTester>.startTest(4) would yield output of:
	 * 
	 *        10:17:04.233  org.test.services::BeadTester  startTest(); testID=#4  
	 *
	 * 
	 * @author thomasburleson
	 * @date   May, 2010
	 * 
	 */
	public class LogProcessor extends BaseMetadataProcessor
	{
		/**
		 * Provides optional override of SwizLogger so custom classes
		 * can be used; e.g. ThunderLogger 
		 */
		public var loggerClass : Class = null;
		
		public function set loggingTarget(val:ILoggingTarget):void 	{   settings.loggingTarget = val;	}
		public function set level(value:int)			  	:void	{	settings.level = value;			}
		public function set filters(value:Array)		  	:void 	{	settings.filters = value;			}
		public function set includeDate(value:Boolean)	  	:void 	{	settings.includeDate = value;		}
		public function set includeTime(value:Boolean)	  	:void	{	settings.includeTime = value;		}
		public function set includeCategory(value:Boolean)	:void	{	settings.includeCategory = value;	}
		public function set includeLevel(value:Boolean)	  	:void	{	settings.includeLevel = value;		}
		
		/**
		 * Constructor to support programmatic instantiation
		 *  
		 * @param loggingTarget ILoggingTarget instance; defaults to null. If not null, then all other parameters are ignored.
		 * @param level			LogEventLevel; defaults to ALL
		 * @param filters		String[] specifies which packages are filtered (allowed).
		 * @param includeDate	Boolean indicates if Log date is included in the log output
		 * @param includeTime	Boolean indicates if Log time is included in the log output
		 * @param includeCategory	Boolean indicates if target className is included in the log output
		 * @param includeLevel	Boolean indicates if LogLevel is included in the log output
		 * 
		 */
		public function LogProcessor(loggingTarget  :ILoggingTarget = null,
									 level			:int 	 = LogEventLevel.ALL, 
									 filters		:Array 	 = null, 
									 includeDate	:Boolean = true, 
									 includeTime	:Boolean = true, 
									 includeCategory:Boolean = true, 
									 includeLevel	:Boolean = true) {
			super([LOG]);
			
			// Defer creation of shared target until Swiz is ready and calls init()
			settings = new CachedSettings(	loggingTarget,level,filters,
											includeDate,includeTime,includeCategory,includeLevel);
		}
		
		
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * Set the processing priority so the [Log] processor runs BEFORE the [Inject] or [EventHandler]
		 */
		override public function get priority():int {
			return ProcessorPriority.INJECT + 10;
		}
		
		
		/**
		 * Init method to configure the processor and build default 
		 * LoggerTarget if not provided
		 *  
		 * @param swiz Swiz needed to access bean factory
		 * 
		 */
		override public function init( swiz:ISwiz ):void {
			super.init(swiz);
			
			// Allow custom override of category ID (which is used with filters)
			buildLogTarget();	
			
			// Then create a global Exception logger (for FlashPlayer 10.1)
			_globalExceptions = new GlobalExceptionLogger(true); 
			if (_globalExceptions.isReady == true) {
				logger.debug( "LogProcessor added global error handler [GlobalExecptionLogger]; logs unhandled errors");	
			} else {
				logger.warn( "LogProcessor unable to configure global error handler; requires Flex 4 and FP 10.1.");
			}
		}
		
		
		/**
		 * Assign ILogger instance; each assigned/customized for the targeted bean class
		 */
		override public function setUpMetadataTags( metadataTags:Array, bean:Bean ):void{
			super.setUpMetadataTags( metadataTags, bean );
			
			for each (var metadataTag:IMetadataTag in metadataTags) {
				var classInstance : Object = bean.source;
				
				// (1) Auto-add the target class package as Filter
				// (2) Now inject the custom logger instance into the target class property
				autoAddLogFilter(classInstance);
				bean.source[ metadataTag.host.name ] = LoggerRegistry.getLogger(classInstance,loggerClass); 

				//logger.debug( "LogProcessor::setUpMetadataTags({0},{1})", metadataTag.toString(), bean.toString() );
				logger.debug( "LogProcessor::setUpMetadataTags({0} {1},{2})", metadataTag.toString(), metadataTag.host.name.toString(), bean.typeDescriptor.className );
			}
		}
		
		/**
		  * Remove ILogger instance
		 */
		override public function tearDownMetadataTag( metadataTag:IMetadataTag, bean:Bean ):void {
			bean.source[ metadataTag.host.name ] = null;
			logger.debug( "LogProcessor::tearDownMetadataTag({0},{1})", metadataTag.toString(), bean.toString() );
		}
		
		
		/**
		 * Build a default LoggingTarget if not specified in the LogProcessor instantiation. 
		 * 
		 */
		private function buildLogTarget() : void {
			if (!settings.filters || settings.filters.length==0) {
				settings.filters = [DUMMY_FILTER]; 
			} 

			// Build one and register with Swiz and shared
			var logTarget : ILoggingTarget = settings.loggingTarget as ILoggingTarget;
			if (logTarget == null) {
				var target : TraceTarget = new TraceTarget();
				
				target.filters			= settings.filters;
				target.level 			= settings.level;
				target.includeDate 		= settings.includeDate;
				target.includeTime 		= settings.includeTime;
				target.includeCategory 	= settings.includeCategory;
				target.includeLevel 	= settings.includeLevel;
				
				logTarget = target;
				settings.loggingTarget  = target;
			}
			
			LoggerRegistry.addLoggingTarget(logTarget);
		}
		
		/**
		 * Each [Log] target will have its package path auto-added as an "allowed" filter.
		 * Use the fully-qualified classname to get its package path.
		 *  
		 * @param target Class instance with a [Log] metadata tag inserted.
		 * 
		 */
		private function autoAddLogFilter(target:Object):void {
			var logTarget : ILoggingTarget = settings.loggingTarget as ILoggingTarget;
			if (logTarget != null) {
				logTarget.filters ||= [];
				
				var clazzName   : String  = getQualifiedClassName( target );
				var packages    : String  = clazzName.substr(0,clazzName.indexOf(":")) + ".*";
				
					logger.debug( "LogProcessor::autoAddLogFilter({0})", packages );
					
					// Append new package to existing list of filters
					logTarget.filters = addToFilters(packages, logTarget.filters);
			}
		}
		
		/**
		 * Method supports auto-Filters to automatically add the bean.source package path 
		 * as another filter; to allow valid log output with our custom logger.
		 *  
		 * @param category String value is the package of the bean.source class
		 * @param filters Array of existing filters
		 * 
		 * @return Array modified/updated filter set 
		 * 
		 */
		private function addToFilters(category:String, filters:Array):Array {
			var results : Array   = [];
			var len     : int 	  = category.indexOf( "*" ) - 1;
			var found   : Boolean = false;
			
			for each (var it:String in filters) {
				// Remove default wildcard "match all" filter 
				if (it == "*") 			continue;
				if (it == DUMMY_FILTER) continue;
				
				if (category.substring(0, len) != it.substring(0, len)) {
					// existing filter item to keep
					results.push(it);	
				}
			}
			
			// Add newest filter category filter was not in list... so add it!
			results.push(category);
			
			return results;
		}
		
		/**
		 * On-demand access to the ILogger for LogProcessor class  
		 * @return 
		 * 
		 */
		protected function get logger():ILogger {
			return LoggerRegistry.getLogger(this,loggerClass); 
		}
		
		
		static  protected  var    	_globalExceptions : GlobalExceptionLogger = null;
		
		static	protected  const 	LOG			:String 	 	= "Log";
		static  protected  const    DUMMY_FILTER:String         = "dummy.remove.asap.*";
		
				protected  var      settings 	:CachedSettings = null;

	}
}



import flash.utils.getQualifiedClassName;

import mx.logging.ILoggingTarget;
import mx.logging.LogEventLevel;

/**
 * Helper class used to cache all initialization settings associated with LoggingTarget
 *  
 * @author thomasburleson
 * 
 */
class CachedSettings {

	public var loggingTarget    : ILoggingTarget 	= null;
	
	public var level 			: int 				= LogEventLevel.ALL;
	public var filters			: Array  			= [];
	
	public var includeDate  	: Boolean			= true;
	public var includeTime  	: Boolean			= true;
	public var includeCategory	: Boolean			= true;
	public var includeLevel		: Boolean			= true;
	
	public function CachedSettings (loggingTarget	:ILoggingTarget = null,
									level			:int 	 = LogEventLevel.ALL, 
									filters			:Array   = null, 
									includeDate		:Boolean = true, 
									includeTime		:Boolean = true, 
									includeCategory	:Boolean = false, 
									includeLevel	:Boolean = true) {
	
		this.loggingTarget      = loggingTarget;
		
		this.level				= level;
		this.filters			= filters;
		
		this.includeDate		= includeDate; 
		this.includeTime		= includeTime; 
		this.includeCategory 	= includeCategory; 
		this.includeLevel		= includeLevel;
	}
}