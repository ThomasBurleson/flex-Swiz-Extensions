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

package ext.swizframework.metadata
{
	import org.swizframework.reflection.BaseMetadataTag;
	import org.swizframework.reflection.IMetadataTag;
	
	public class DeepLinkMetadataTag extends BaseMetadataTag
	{
		
		// ========================================
		// protected properties
		// ========================================
		
		protected var _pattern:String;
		
		protected var _url:String;
		
		protected var _title:String;
		
		protected var _suspend:String;
		
		// ========================================
		// public properties
		// ========================================
		
		
		/**
		 * String matching fragment; when simple token matching
		 * is not sufficient. This is the master pattern/RegExp
		 * to be used in the url matching process
		 *  
		 * 	e.g.  ^/test/(.+?)/(.*?)$
		 * 
		 * Normally, this pattern is derived from the URL.
		 * But if needed this option supercede the derivation.
		 * 
		 * @return String 
		 * 
		 */
		public function get pattern():String 
		{
			return _pattern;
		}
		
		/**
		 * String matching fragment with simple tokens
		 * 	e.g.  /test/{0}/{1}
		 * 
		 * @return String 
		 */
		public function get url():String
		{
			return _url;
		}
		
		public function get title():String
		{
			return _title;
		}
		
		/**
		 * Feature used to suspend or activate the DeepLinkProcessor
		 * Any [DeepLink(suspend="true|false")] can toggle the processor activity.
		 */
		public function get suspend():String
		{
			return _suspend;
		}
		
		// ========================================
		// constructor
		// ========================================
		
		public function DeepLinkMetadataTag()
		{
			super();
			
			defaultArgName = "url";
		}
		
		// ========================================
		// public methods
		// ========================================
		
		override public function copyFrom( metadataTag:IMetadataTag ):void
		{
			super.copyFrom( metadataTag );
			
			if( hasArg( "url" ) )
			{
				_url = getArg( "url" ).value;
			}
			
			if( hasArg( "title" ) )
			{
				_title = getArg( "title" ).value;
			}
			
			if( hasArg( "suspend" ) )
			{
				_suspend = getArg( "suspend" ).value;
			}
			
			if( hasArg( "pattern" ) )
			{
				_suspend = getArg( "pattern" ).value;
			}
		}
		
	}
}