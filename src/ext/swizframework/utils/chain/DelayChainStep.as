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
					timer.removeEventListener( TimerEvent.TIMER_COMPLETE,onComplete_idle );
					
					// Announce that this step has finished/completed
					complete();
				}
				
			var timer : Timer = new Timer(interval);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE,onComplete_idle)
					
				timer.start();

		}
		
	}
}