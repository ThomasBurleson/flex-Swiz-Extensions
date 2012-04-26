package ext.swizframework.core
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import org.swizframework.core.IDispatcherAware;
	
	public class AbstractPresentationModel extends EventDispatcher implements IDispatcherAware
	{
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Backing variable for <code>dispatcher</code> property.
		 */
		protected var _swizDispatcher:IEventDispatcher;
		
		// ========================================
		// Public properties
		// ========================================
		
		/**
		 * @inheritDoc
		 */
		public function get dispatcher():IEventDispatcher
		{
			return _swizDispatcher;
		}
		
		public function set dispatcher( value:IEventDispatcher ):void
		{
			_swizDispatcher = value;
		}
		
		// ========================================
		// Constructor
		// ========================================
		
		/**
		 * Constructor.
		 */
		public function AbstractPresentationModel( dispatcher:IEventDispatcher = null )
		{
			super( dispatcher );
		}
		
		// ========================================
		// Public methods
		// ========================================
		
	}
}