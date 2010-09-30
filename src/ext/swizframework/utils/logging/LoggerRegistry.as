package ext.swizframework.utils.logging
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.IFactory;
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	

	public class LoggerRegistry
	{
		protected static var loggers		:Dictionary = new Dictionary();
		protected static var loggingTargets	:Array		= [];
		
		public static function getLogger( target:Object, LoggerClazz:Class = null ):ILogger
		{
			loggers ||= new Dictionary();
			
			// Target is a class or instance; we want the fully-qualified Classname
			var className:String  = getQualifiedClassName( target );
			var logger:ILogger    = loggers[ className ] as ILogger;
			
			// if the logger doesn't already exist, create and store it
			if( logger == null )
			{
				if (LoggerClazz == null) LoggerClazz = Logger;
				logger = new LoggerClazz(className) as ILogger;
				
				if (logger != null) loggers[ className ] = logger;
			}
			
			// check for existing targets interested in this logger
			for each( var logTarget:ILoggingTarget in loggingTargets ) {
				
				if( categoryMatchInFilterList( logger.category, logTarget.filters ) )
					logTarget.addLogger( logger );
			}
			
			return logger;
		}
		
		/**
		 *  This method checks that the specified category matches any of the filter
		 *  expressions provided in the <code>filters</code> Array.
		 *
		 *  @param category The category to match against
		 *  @param filters A list of Strings to check category against.
		 *  @return <code>true</code> if the specified category matches any of the
		 *            filter expressions found in the filters list, <code>false</code>
		 *            otherwise.
		 */
		public static function categoryMatchInFilterList( category:String, filters:Array ):Boolean
		{
			var result:Boolean = false;
			var filter:String;
			var index:int = -1;
			for( var i:uint = 0; i < filters.length; i++ )
			{
				filter = filters[ i ];
				// first check to see if we need to do a partial match
				// do we have an asterisk?
				index = filter.indexOf( "*" );
				
				if( index == 0 )
					return true;
				
				index = index < 0 ? index = category.length : index - 1;
				
				if( category.substring( 0, index ) == filter.substring( 0, index ) )
					return true;
			}
			return false;
		}
		
		public static function addLoggingTarget( loggingTarget:ILoggingTarget ):void
		{
			loggingTargets ||= [];
			if( loggingTargets.indexOf( loggingTarget ) < 0 )
				loggingTargets.push( loggingTarget );
			
			if( loggers != null )
			{
				for each( var logger:ILogger in loggers )
				{
					if( categoryMatchInFilterList( logger.category, loggingTarget.filters ) )
						loggingTarget.addLogger( logger );
				}
			}
		}
	
	}
}