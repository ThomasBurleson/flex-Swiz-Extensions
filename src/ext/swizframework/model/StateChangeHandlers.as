package ext.swizframework.model
{
	import ext.swizframework.events.StateChangeHandler;

	import flash.utils.Dictionary;

	/**
	 * Collection to handle StateEventHandlers.
	 */
    public class StateChangeHandlers
    {
        private const handlers:Dictionary = new Dictionary();

		/**
		 * A count of the current number of handlers in the collection
		 */
        public var handlerCount:int = 0;

		/**
		 * Add a handler to the collection
		 *
		 * @param handler The StateEventHandler to add
		 */
        public function addHandler(handler:StateChangeHandler):void
        {
	        var state:String = handler.state;

            if (handlers[state] == null)
                handlers[state] = [];

            handlers[state].push(handler);
            handlers[state].sortOn("priority");

            handlerCount++;
        }

		/**
		 * Removes a handler from the collection.
		 *
		 * @param view The view of the handler
		 * @param handler The handler method
		 */
        public function removeHandler(view:String, handler:Function):void
        {
            for (var i:int = 0; i < handlers[view].length; i++)
            {
                var fn:Function = handlers[view][i].handler;

                if (fn == handler)
                {
                    handlers[view].splice(i, 1);

                    handlerCount--;

                    break;
                }
            }
        }

        public function getHandlersForView(view:String):Array
        {
            return handlers[view];
        }
    }
}
