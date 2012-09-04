package ext.swizframework.metadata
{
	import org.swizframework.reflection.BaseMetadataTag;
	import org.swizframework.reflection.IMetadataTag;

	/**
	 * Metadata tag for StateEvent handlers
	 */
    public class StateEventHandlerMetadataTag extends BaseMetadataTag
    {
		/**
		 * The state to navigate to
		 */
        public function get state():String
        {
            return _state;
        }

        private var _state:String;

		/**
		 * String name of the method to handle the change. This is optional if the tag
		 * is placed directly over the handler method
		 */
        public function get handler():String
        {
            return _handler;
        }

        private var _handler:String;

		/**
		 * Optional priority of the handler
		 */
        public function get priority():int
        {
            return _priority;
        }

        private var _priority:int;

        public function StateEventHandlerMetadataTag()
        {
            defaultArgName = "state";
        }

		/**
		 * @inheritDoc
		 */
        override public function copyFrom(metadataTag:IMetadataTag):void
        {
            // super will set name, args and host for us
            super.copyFrom(metadataTag);

            if (hasArg("state"))
                _state = getArg("state").value;

            if (hasArg("handler"))
                _handler = getArg("handler").value;

            if (hasArg("priority"))
                _priority = int(getArg("priority").value);
        }

    }
}
