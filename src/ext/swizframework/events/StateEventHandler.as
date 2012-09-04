package ext.swizframework.events
{
	import ext.swizframework.metadata.StateEventHandlerMetadataTag;

	import org.swizframework.reflection.MetadataHostMethod;
	import org.swizframework.reflection.MethodParameter;

	/**
	 * Data class for holding pertinent information and handling state change events.
	 */
    public class StateEventHandler
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
		 * The method to handle the change
		 */
        public function get handler():Function
        {
            return _handler;
        }

        private var _handler:Function;

		/**
		 * The priority of the handler (0 being highest priority)
		 */
        public function get priority():int
        {
            return _priority;
        }

        private var _priority:int;

		/**
		 * The associated metadata tag
		 */
        public function get metadataTag():StateEventHandlerMetadataTag
        {
            return _metadataTag;
        }

        private var _metadataTag:StateEventHandlerMetadataTag;

		/**
		 *
		 * @param view The view to navigate to
		 * @param handler The method to handle the change
		 * @param metadataTag The associated metadata tag
		 * @param priority The priority of the handler
		 */
        public function StateEventHandler(view:String, handler:Function, metadataTag:StateEventHandlerMetadataTag, priority:int)
        {
            _state = view;
            _handler = handler;
            _metadataTag = metadataTag;
            _priority = priority;
        }

		/**
		 * Handles the event.
		 *
		 * @param event The StateEvent instance that triggered the change
		 */
        public function handleEvent(event:StateEvent):void
        {
            var hostMethod:MetadataHostMethod = metadataTag.host as MetadataHostMethod;

            if (hostMethod)
            {
                if (hostMethod.requiredParameterCount == 0)
                {
                    handler();
                }
                else if (hostMethod.requiredParameterCount == 1)
                {
                    var parameterClass:Class = getParameterType();

                    if (parameterClass == StateEvent)
                    {
                        handler(event);
                    }
                    else if (parameterClass == Object)
                    {
                        handler(event.parameters);
                    }
                }
            }
            else
            {
                handler(event.parameters);
            }
        }

        private function getParameterType():Class
        {
            var hostMethod:MetadataHostMethod = MetadataHostMethod(metadataTag.host);
            var parameters:Array = hostMethod.parameters;

            return (parameters[0] as MethodParameter).type;

            return null;
        }

    }
}
