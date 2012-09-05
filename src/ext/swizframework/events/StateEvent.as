package ext.swizframework.events
{
	import flash.events.Event;

	/**
	 * This event is dispatched to trigger application wide state changes. This event is then handled by Swiz
	 * and passed off to methods carrying the StateEventHandler metadata.
	 *
	 * @see StateEventHandlerProcessor
	 */
    public class StateEvent extends Event
    {
		/**
		 * Event to trigger state changes
		 */
        public static const STATE_CHANGE:String = "stateChange";

		/**
		 * The state to navigate to
		 */
        public var state:String;
		/**
		 * Optional parameters to aid in switching states
		 */
        public var parameters:Object;

		/**
		 *
		 * @param type The event type
		 * @param state The new state
		 * @param parameters Optional parameters for the state change
		 * @param bubbles Event bubbling switch
		 * @param cancelable Event cancelling switch
		 */
        public function StateEvent(type:String, state:String, parameters:Object = null, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);

            this.state = state;
            this.parameters = parameters;
        }
    }
}
