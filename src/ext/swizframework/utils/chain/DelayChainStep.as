package ext.swizframework.utils.chain
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.swizframework.utils.chain.BaseChainStep;
	import org.swizframework.utils.chain.IAutonomousChainStep;
	
	public class DelayChainStep extends BaseChainStep implements IAutonomousChainStep
	{
		/**
		 * Number of milliseconds to idle before announcing completion
		 */
		public var interval : int = 0;
		
		/**
		 * Constructor 
		 */
		public function DelayChainStep(interval:Number=0)
		{
			super();
			
			this.interval = interval;
		}
		
		
		public function doProceed():void
		{
			if ( interval > 0 )  doIdle();
			else				 complete();
		}
		
		/**
		 * Perform the idle process for a non-zero
		 * amount of milliseconds. 
		 */				
		protected function doIdle():void 
		{
				// Internal completion handler
				function onComplete_idle(event:TimerEvent):void {
					
					_timer.removeEventListener( TimerEvent.TIMER_COMPLETE,onComplete_idle );
					_timer = null;
					
					// Announce that this step has finished/completed
					complete();
				}
				
			_timer = new Timer(interval,1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE,onComplete_idle)
					
			_timer.start();

		}
		
		protected var _timer : Timer;
		
	}
}