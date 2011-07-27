/*
 * Copyright 2010 Swiz Framework Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package ext.swizframework.utils.chain
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.swizframework.utils.async.AsynchronousChainOperation;
	import org.swizframework.utils.async.IAsynchronousOperation;
	import org.swizframework.utils.chain.ChainType;
	import org.swizframework.utils.chain.EventChain;
	import org.swizframework.utils.chain.EventChainStep;
	import org.swizframework.utils.chain.IChain;
	
	public class ThrottledEventChain extends EventChain
	{
		/**
		 * Amount of time to idle/delay before the next step is processed...
		 */
		public var idleTime : Number = 0;
		
		// ========================================
		// constructor
		// ========================================

		/**
		 * Constructor.
		 */
		public function ThrottledEventChain(idleTime:Number, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true )
		{
			super( dispatcher, mode, stopOnError );
			
			this.idleTime = idleTime;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Only intercept the stepComplete() [which triggers the next event in the chain to be dispatched]
		 * if the mode == SEQUENCE
		 */
		override public function stepComplete():void
		{
			var intercepted : Function = super.stepComplete as Function;
			
			if (mode == ChainType.SEQUENCE) idle( intercepted );
			else							intercepted();
			
		}
		
		
		// ========================================
		// protected methods
		// ========================================

		/**
		 * Idle for the specified `idleTime` before calling stepComplete();
		 * which would then fire/trigger the next event in the chain (if any).
		 */
		protected function idle( intercepted:Function ):void {
		
				/**
				 *  Now call the intercepted request for stepComplete();
				 */
				function onComplete_idle(e:TimerEvent=null):void {
					if (e != null) 
						IEventDispatcher(e.target).removeEventListener(TimerEvent.TIMER_COMPLETE, onComplete_idle);
					
					intercepted();
				}
				
				
			if (idleTime > 0) {
				var timer : Timer = new Timer( idleTime, 1 );
				
					timer.addEventListener( TimerEvent.TIMER_COMPLETE, onComplete_idle );
					timer.start();
					
					return;
			} 
			
			super.stepComplete();
		}
		
		// ========================================
		// Static Builder Method
		// ========================================
		
		/**
		 * Utility method to construct an eventChain and auto-add the specified events; added to the chain in
		 * the order listed in the events[].
		 * 
		 * <p>The IChain instance has not been "started".</p>
		 *  
		 * @param events Array of Event instances
		 * @param dispatcher IEventDispatcher, typically this is the Swiz dispatcher
		 * @param mode String SEQUENCE or PARALLEL
		 * @param stopOnError 
		 * @return IChain
		 */
		static public function createThrottledChain(idleTime:Number, events:Array, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IChain {
			var chain : IChain = new ThrottledEventChain(idleTime, dispatcher,mode,stopOnError);
				
				for each (var it:Event in events) {
					if (it == null) continue;
					chain.addStep( new EventChainStep( it ) );
				}
			
			return chain;
		}
		
		/**
		 * Utility method to construct an eventChain, start it, and wrap it in an AsynchronousChainOperation.
		 * 
		 * <p>The IChain instance has not been "started".</p>
		 *  
		 * @param events Array of Event instances
		 * @param dispatcher IEventDispatcher, typically this is the Swiz dispatcher
		 * @param mode String SEQUENCE or PARALLEL
		 * @param stopOnError 
		 * @return IAsynchronousOperation
		 */
		static public function createAsyncOperation(idleTime:Number, events:Array, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IAsynchronousOperation {
			var chain : IChain = ThrottledEventChain.createThrottledChain(idleTime, events, dispatcher, mode, stopOnError);
			
			return new AsynchronousChainOperation( chain.start() );
		}		
	}
}
