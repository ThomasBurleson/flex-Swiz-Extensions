package ext.swizframework.metadata
{
	import org.swizframework.core.ISwiz;
	import org.swizframework.reflection.ClassConstant;
	import org.swizframework.utils.logging.SwizLogger;

	/**
	 * Expression class to handle parsing the value of the state name. Supports
	 * state names of String or of a public static.
	 */
    public class StateEventTypeExpression
    {
        private const logger:SwizLogger = SwizLogger.getLogger(this);

        private var swiz:ISwiz;

		/**
		 * The parsed state value
		 */
        public function get state():String
        {
            return _state;
        }

        private var _state:String;

		/**
		 *
		 * @param expression The value passed in through the MetadataTag's "state" parameter
		 * @param swiz The Swiz instance
		 * @param viewStatePackages An Array of package names to include as state values
		 */
        public function StateEventTypeExpression(expression:String, swiz:ISwiz, viewStatePackages:Array)
        {
            this.swiz = swiz;

            parse(expression, viewStatePackages);
        }

        private function parse(expression:String, statePackages:Array):void
        {
            if (swiz.config.strict && ClassConstant.isClassConstant(expression))
            {
                var viewStateTypeClass:Class = ClassConstant.getClass(swiz.domain, expression, statePackages);

                if (viewStateTypeClass)
                {
                    _state = ClassConstant.getConstantValue(swiz.domain, viewStateTypeClass, ClassConstant.getConstantName(expression));
                }
                else
                {
                    logger.error("State constants class not found: {0}", expression);
                }
            }
            else
            {
                _state = expression;
            }
        }

    }
}
