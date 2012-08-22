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
	
	import org.swizframework.utils.async.AsynchronousChainOperation;
	import org.swizframework.utils.async.IAsynchronousOperation;
	import org.swizframework.utils.chain.ChainType;
	import org.swizframework.utils.chain.EventChain;
	import org.swizframework.utils.chain.EventChainStep;
	import org.swizframework.utils.chain.IChain;
	import org.swizframework.utils.chain.IChainStep;
	
	public class ChainBuilder extends EventChain
	{
		/**
		 * Constructor.
		 */
		public function ChainBuilder( dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true )
		{
			super( dispatcher, mode, stopOnError );
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
		static public function createChain(events:Array, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IChain {
			var chain : IChain = new EventChain(dispatcher,mode,stopOnError);
				
				for each (var it:* in events) {
										
					if ( it is IChainStep) {
						
						// Simply add the chainStep instance
						chain.addStep ( IChainStep(it) );
						
					} else if (it is Event)  {
						
						// Wrap the event so it can be used in a chain
						chain.addStep(  new EventChainStep( it as Event ) );
					}
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
		static public function createAsyncOperation(events:Array, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IAsynchronousOperation {
			var chain : IChain = ChainBuilder.createChain(events, dispatcher, mode, stopOnError);
				chain.start();
				
			return new AsynchronousChainOperation( chain );
		}		
	}
}
