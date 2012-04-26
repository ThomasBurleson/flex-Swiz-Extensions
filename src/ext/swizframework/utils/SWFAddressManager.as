////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Mindspace, LLC - http://www.gridlinked.info/
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.	
////////////////////////////////////////////////////////////////////////////////

package ext.swizframework.utils
{
	import com.asual.swfaddress.SWFAddress;
	import com.asual.swfaddress.SWFAddressEvent;
	
	import flash.events.Event;
	
	import mx.events.BrowserChangeEvent;
	import mx.managers.IBrowserManager;
	import mx.utils.StringUtil;
	
	/**
	 * This optional class uses the Adapater pattern to interface the use of SWFAddress (v2.3) with the DeepLinkProcessor's
	 * expectations and use of an internal IBrowserManager reference. This class then allows the DeepLinkProcessor to transparently
	 * use SWFAddress instead of BrowserManager [which is not as robust].
	 * 
	 *   <Swiz>
	 * 		<customProcessors>
	 * 
	 *			<DeepLinkProcessor id={dlProcessor}>
	 *				<browserManager>
	 * 					<!-- 
	 * 						 Optional: 
	 * 						 If not used, then a BrowserManager instance is created and used internally by the DeepLinkProcessor 
	 * 					-->
	 * 					<SWFAddressManager baseTitle="DeepLink Demo" />
	 *				<browserManager>
	 * 			</DeepLinkProcess>
	 * 
	 *		</customProcessors>
	 *   </Swiz>  
	 * 
	 * Of course, this solution requires that SWFAddress.js has been loaded in the SWF wrapper html/DOM.
	 * 
	 * @author thomasburleson
	 * @date   May 2010
	 * 
	 */
	public class SWFAddressManager implements IBrowserManager  {
		
		/**
		 * Basic (root) title [to be shown in the Browser title bar] for the application 
		 */
		public var baseTitle 	 : String = "";
		
		/**
		 * Delimiter to be used between the root title and any other title suffixes 
		 */
		public var delimiter : String = " >> ";
		
		/**
		 * Callback `function (event:BrowserChangeEvent):void` to handle external
		 * changes in the browser URL. This function should be assigned a reference to the handler inside the 
		 * DeepLinkProcessor instance
		 */		
		public var urlChangeHandler : Function = null;
		
		
		// ****************************************************************************************************
		// Support for IEventDispatcher interface
		// ****************************************************************************************************

		public function get base():String  				{	return SWFAddress.getBaseURL();				}
		public function get url():String				{	return SWFAddress.getPath();				}
		public function get title():String				{	return SWFAddress.getTitle();				}
		public function get fragment():String			{	return SWFAddress.getValue();				}
		
		public function setTitle(value:String):void		{	SWFAddress.setTitle(StringUtil.substitute("{0}{1}{2}",[baseTitle,delimiter,value]));					}
		public function setFragment(value:String):void	{	SWFAddress.setValue(value);					}
		
		// ****************************************************************************************************
		// Init for methods
		// ****************************************************************************************************
		
		/**
		 * The BrowserManager will get the initial URL.  If it has a fragment, it will 
     	 *  dispatch BROWSER_URL_CHANGE, so add your event listener before calling this method.
		 * 
		 *  This method is called by the DeepLinkProcessor
		 */
		public function init(value:String=null, title:String=null):void {	 			

			addEventListener(SWFAddressEvent.CHANGE, onBrowserChange);
		}
		
		
		public function initForHistoryManager():void {
			/*Deprecated functionality...*/ ;			
		}
		
		
		// ****************************************************************************************************
		// Internal Methods
		// ****************************************************************************************************
		
		/**
		 * Repackage the incomping SWFAddressEvent and forward to the DeepLinkProcessor handler 
		 * as BrowserChangeEvent...
		 *  
		 * @param event SWFAddressEvent.CHANGE
		 * 
		 */
		private function onBrowserChange(event:SWFAddressEvent):void {
			if (urlChangeHandler != null) {
				var type : String = BrowserChangeEvent.BROWSER_URL_CHANGE;
					
				urlChangeHandler.apply(null, [new BrowserChangeEvent(type,false,false,event.path)] );
			}
		}
		
		
		
		// ****************************************************************************************************
		// Support for IEventDispatcher interface
		// ****************************************************************************************************
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void	{
			SWFAddress.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void	{
			SWFAddress.removeEventListener(type,listener,useCapture);
		}
		public function dispatchEvent(event:Event):Boolean	{
			return SWFAddress.dispatchEvent(event);
		}
		public function hasEventListener(type:String):Boolean	{
			return SWFAddress.hasEventListener(type);
		}
		public function willTrigger(type:String):Boolean	{
			return SWFAddress.hasEventListener(type);
		}
		
	}
}