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

package ext.swizframework.processors
{
	import ext.swizframework.metadata.DeepLinkMetadataTag;
	import ext.swizframework.utils.SWFAddressManager;
	import ext.swizframework.utils.logging.Logger;
	
	import flash.events.Event;
	
	import mx.events.BrowserChangeEvent;
	import mx.logging.ILogger;
	import mx.managers.BrowserManager;
	import mx.managers.IBrowserManager;
	import mx.utils.StringUtil;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.metadata.EventHandlerMetadataTag;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.processors.ProcessorPriority;
	import org.swizframework.reflection.ClassConstant;
	import org.swizframework.reflection.Constant;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.reflection.TypeCache;
	import org.swizframework.reflection.TypeDescriptor;
	
	import utils.string.supplant;
	import utils.string.toArray;
	import utils.string.toString;
	
	/**
	 * [DeepLink] metadata processor is a derivative of the excellent URLMapping class created by Ryan Campbell
	 * His original version is documented on his blog http://www.ryancampbell.com/2010/03/26/introducing-the-swiz-urlmapping-metadata-processor/comment-page-1/#comment-2737 
	 * This version has logging features and allows SWFAddress to be used instead of the Flex BrowserManager singleton. 
	 * 
	 *  Usage snippets
	 * 
	 * 	[DeepLink( url="/helloWorld" )]
	 * 	public function sayHelloWorld():void
	 * 	{
	 * 		model.msg = "Hello world!";
	 * 	}
	 * 
	 * The URL Mapping processor will automatically start listening for URL changes. For the above example, 
	 * any time the URL changes to flexapp.html#/helloWorld the sayHelloWorld() method will automatically get 
	 * called. Also, since url is the default metadata argument, the following example works exactly the same:
	 * 
	 * 	[DeepLink( "/helloWorld" )]
	 * 	public function sayHelloWorld():void
	 * 	{
	 * 		model.msg = "Hello world!";
	 * 	}
	 * 
	 * You can also use parts of the URL as parameters:
	 * 
	 * 	[DeepLink( "/hello/{0}" )]
	 * 	public function sayHello( name:String ):void
	 * 	{
	 * 		model.msg = "Hello " + name + "!";
	 * 	}
	 * 
	 * And optionally change the browser window title when the URL changes:
	 * 
	 * 	[DeepLink( url="/hello/{0}", title="Hello {0}!" )]
	 * 	public function sayHello( name:String ):void
	 * 	{
	 * 		model.msg = "Hello " + name + "!";
	 * 	}
	 * 
	 * Lastly, [DeepLink] also works in reverse with the help of the Swiz [EventHandler] metadata. In this example 
	 * the URL will change to /hello/Ryan and the browser window title to "Hello Ryan!" when the 
	 * HelloEvent.HELLO event is dispatched:
	 * 
	 * 	[DeepLink( url="/hello/{0}", title="Hello {0}!" )]
	 * 	[EventHandler( event="HelloEvent.HELLO", properties="name" )]
	 * 	public function sayHello( name:String ):void
	 * 	{
	 * 		model.msg = "Hello " + name + "!";
	 * 	}
	 * 
	 * And then dispatch the event:
	 * 
	 * 		<s:TextInput id="nameInput" text="Ryan" />
	 * 		<s:Button label="Say Hello" click="dispatchEvent( new HelloEvent( HelloEvent.HELLO, nameInput.text ) )" />
 	 * 
 	 * 
	 */
	public class DeepLinkProcessor extends BaseMetadataProcessor
	{
		
		// ========================================
		// protected properties
		// ========================================
		
		/**
		 * Reference to the an IBrowserManager instance.
		 * 
		 * @defaultValue Singleton instance for the Flex SDK BrowserManager
		 */
		public var browserManager:IBrowserManager;
		
		/**
		 * Should the urls be escaped/unescaped 
		 */
		public var enableEscape : Boolean = true;
		
		/**
		 * List of mediate event types
		 */
		protected var mediateEventTypes:Array = [];
		
		/**
		 * List of attached urll mappings
		 */
		protected var deepLinks:Array = [];
		
		/**
		 * List of url regexs to match browser urls against
		 */
		protected var regexs:Array = [];
		
		/**
		 * List of methods to call
		 */
		protected var methods:Array = [];
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function DeepLinkProcessor( metadataNames:Array = null )
		{
			super( ( metadataNames == null ) ? [ "DeepLink" ] : metadataNames, DeepLinkMetadataTag );
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Set the processing priority so the [DeepLink] processor runs BEFORE the [Mediate] or [EventHandler]
		 */
		override public function get priority():int {
			return ProcessorPriority.EVENT_HANDLER + 10;
		}
		
		/**
		 * Init
		 */
		override public function init( swiz:ISwiz ):void
		{
			super.init( swiz );
			
			if (browserManager == null) {
				// Defaults to internal reference to Flex SDK BrowserManager
				browserManager = BrowserManager.getInstance();
				browserManager.addEventListener( BrowserChangeEvent.BROWSER_URL_CHANGE, onBrowserURLChange );
				
			} else {
			
				var sam : SWFAddressManager = browserManager as SWFAddressManager;
				if (sam && (sam.urlChangeHandler == null)) {
					// Hook the SWFAddressEvent.CHANGE process to call DeepLinkProcessor::onBrowserURLChange() 
					sam.urlChangeHandler = onBrowserURLChange;	
				} 
			}
			
			browserManager.init();
		}
		
		/**
		 * Executed when a new [DeepLink] is found
		 */
		override public function setUpMetadataTag( metadataTag:IMetadataTag, bean:Bean ):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			var method:Function = bean.source[ metadataTag.host.name ] as Function;
			
			addDeepLink( deepLink, method );
			
			logger.debug( supplant("setup link url='{url}' on {name}", {url: deepLink.url, name:metadataTag.host.name} ) );
		}
		
		/**
		 * Executed when a [DeepLink] has been removed
		 */
		override public function tearDownMetadataTag(metadataTag:IMetadataTag, bean:Bean):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			var method	:Function 			 = bean.source[ metadataTag.host.name ] as Function;
			
				logger.debug( supplant("teardown link url='{url}' on {name}", {url: deepLink.url, name:metadataTag.host.name}) );
			
			removeDeepLink( deepLink, method );
		}
		
		/**
		 * Executed when the browser URL changes
		 */
		public function onBrowserURLChange( event:Event ):void {
			var url:String = event.hasOwnProperty("url") ? event["url"] : "";
			
			if ( url.indexOf( "#" ) > -1 )
				url = url.substr( url.indexOf( "#" ) + 1 );
			
			if (url != "") {
				logger.debug( "onBrowserURLChange(url='{0}')",url );

				for ( var i:int = 0; i < regexs.length; i++ ) {
					
					var match:Array = url.match( regexs[ i ] );
					
					if ( match != null ) {
						processDeepLink( match, deepLinks[ i ] as DeepLinkMetadataTag, methods[ i ] as Function );
					}
				}
			}
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		/**
		 * Add a URL mapping
		 */
		protected function addDeepLink( deepLink:DeepLinkMetadataTag, method:Function ):void
		{
			logger.debug( supplant("addDeepLink(url='{url}',title='{title}')", deepLink ) );
			
			addMediate( deepLink );
			
			var index:int = deepLinks.length;
			var regex:RegExp = new RegExp( "^" + deepLink.url.replace( /[\\\+\?\|\[\]\(\)\^\$\.\,\#]{1}/g, "\$1" ).replace( /\*/g, ".*" ).replace( /\{.+?\}/g, "(.+?)" ) + "$" );
			
			// add mapping to arrays
			deepLinks[ index ] = deepLink;
			methods[ index ]   = method;
			regexs[ index ]    = regex;
			
			// check if mapping matches the current url
			var url:String = browserManager.url != null ? browserManager.url.substr( browserManager.url.indexOf( "#" ) + 1 ) : "";
			var match:Array = url.match( regex );
			
			// if a match is found, process the url change
			if ( match != null ) {
				processDeepLink( match, deepLink, method );
			}
		}
		
		/**
		 * Remove a URL mapping
		 */
		protected function removeDeepLink( deepLink:DeepLinkMetadataTag, method:Function ):void {
			logger.debug( supplant("removeDeepLink(url='{url}',title='{title}')", deepLink ) );
			
			var index:int = deepLinks.indexOf( deepLink );
			if ( index != -1 ) {
				// remove mapping from arrays
				deepLinks.splice( index, 1 );
				methods.splice( index, 1 );
				regexs.splice( index, 1 );
			}
			
			removeMediate( deepLink );
		}
		
		/**
		 * Add a reverse URL mapping if possible
		 */
		protected function addMediate( deepLink:DeepLinkMetadataTag ):void
		{
			var srcTag : IMetadataTag = deepLink.host.getMetadataTagByName( "EventHandler" );
				srcTag ||= deepLink.host.getMetadataTagByName( "Mediate" )
					
			if ( srcTag != null ) {
				
				var mediateTag : EventHandlerMetadataTag = new EventHandlerMetadataTag();
				    mediateTag.copyFrom(srcTag);
				
					logger.debug( "addMediate(event='{0}')", mediateTag.event );	
					
				if( mediateTag.event.substr( -2 ) == ".*" )
				{
					var clazz:Class = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages );
					var td:TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants )
					{
						addEventHandler( deepLink, constant.value );
					}
				}
				else
				{
					var eventType:String = parseEventTypeExpression( mediateTag.event );
					
					addEventHandler( deepLink, eventType );
				}
			}
		}
		
		/**
		 * Remove a reverse URL mapping
		 */
		protected function removeMediate( deepLink:DeepLinkMetadataTag ):void
		{
			var srcTag : IMetadataTag = deepLink.host.getMetadataTagByName( "EventHandler" );
				srcTag ||= deepLink.host.getMetadataTagByName( "Mediate" )
			
			if ( srcTag != null ) {

				var mediateTag : EventHandlerMetadataTag = new EventHandlerMetadataTag();
					mediateTag.copyFrom(srcTag);
				
					logger.debug( "removeMediate(event='{0}')", mediateTag.event );
				
				if( mediateTag.event.substr( -2 ) == ".*" ) {
					var clazz:Class = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages);
					var td:TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants ) {
						removeEventHandler( deepLink, constant.value );
					}
					
				} else {
					var eventType:String = parseEventTypeExpression( mediateTag.event );
					
					removeEventHandler( deepLink, eventType );
				}
			}
		}
		
		/**
		 * Add mediate event handler
		 */
		protected function addEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			swiz.dispatcher.addEventListener( eventType, mediateEventHandler );
			mediateEventTypes[ mediateEventTypes.length ] = eventType;
			
			logger.debug( "addEventHandler( event='{0}' )",eventType );
		}
		
		/**
		 * Remove mediate event handler
		 */
		protected function removeEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			swiz.dispatcher.removeEventListener( eventType, mediateEventHandler );
			mediateEventTypes.splice( mediateEventTypes.lastIndexOf( eventType ), 1 );
			
			logger.debug( "remove eventHandler( event='{0}' )",eventType );
		}
		
		/**
		 * Process an incoming URL change to (a) call the associated eventHandler method and (b) set browser title.
		 * The eventHandler function may have 0-n arguments; which are constructed as either 
		 *   i. Array of args
		 *       e.g.
		 *  		  [DeepLink( url="/jump/{0}/{1}", title="State {0}!" )]
		 *            [EventHandler(event="GotoEvent.GOTO",properties="action,options")]
		 * 
		 *            public function onGoto( action:String,options:String ):void {... }
		 * 
		 *   ii. Hashmap of field names whose values are the args
		 *       e.g.
		 * 			  [DeepLink( url="/jump/{action}/{options}", title="State {name}!" )]
		 *            [EventHandler(event="GotoEvent2.GOTO",properties="details")]
		 * 
		 *            public function onGoto( details:Object ):void { ... }
		 * 
		 * This allows
		 */
		protected function processDeepLink( lookups:Array, deepLink:DeepLinkMetadataTag, method:Function ):void
		{
				function isComplex():Boolean {
					var mediate	: IMetadataTag = deepLink.host.getMetadataTagByName( "Mediate" ) || deepLink.host.getMetadataTagByName( "EventHandler" );
					var args  : Array          = mediate ? mediate.getArg( "properties" ).value.split( /\s*,\s*/ ) : null;
					
					return (args.length == 1) && (matches.length > 1);	
				}
				
			var matches	  :Array  = deepLink.url.match( /\{([^\{\}]*)\}/g );
			var parameters:*      = isComplex() ?  new Object : new Array;
			
			for ( var j:int=0; j<matches.length; j++) 
			{
				var key : String = String( matches[j] ).replace( /\{/gi,"").replace( /\}/gi,"");
				var val : *      = lookups[ j + 1 ];
				
				if ( parameters is Array ) parameters.push( unescape( val ) );
				else                       parameters[ key ] = unescape( val );
			}
			
			// Call the method associated with [EventHandler(event="",properties="")]
			
			if ( method != null) 
			{
				logger.debug( "incoming url change invokes function({0})", utils.string.toString(parameters,",") );
				method.apply( null, toArray(parameters) );
			}
			
			// Set the Browser title
			
			if( deepLink.title != null ) {
				var title : String = supplant( deepLink.title, parameters );
				
				browserManager.setTitle( title );
				logger.debug( "browserManager.setTitle( '{0}' )", title );
			}
		}
		
		/**
		 * When a mediated method is called, construct the deeplink url and title equivalents
		 * The eventHandler function may have 0-n arguments; which are constructed as either:
		 *  
		 *   i. Array of args
		 *       e.g.
		 *  		  [DeepLink( url="/jump/{0}/{1}", title="State {0}!" )]
		 *            [EventHandler(event="GotoEvent.GOTO",properties="action,options")]
		 * 
		 *            public function onGoto( action:String,options:String ):void {... }
		 * 
		 *   ii. Hashmap of field names whose values are the args
		 *       e.g.
		 * 			  [DeepLink( url="/jump/{action}/{options}", title="State {name}!" )]
		 *            [EventHandler(event="GotoEvent2.GOTO",properties="details")]
		 * 
		 *            public function onGoto( details:Object ):void { ... }
		 * 
		 * To build the URL, collect the function arguments as a hashmap of name/values, then
		 * build the URL based tokens in the url=`` template. 
		 * 
		 * NOTE: this process calls ::setFragment() which in turn invokes the processDeepLink() above...
		 */
		protected function mediateEventHandler( event:Event ):void
		{
			var deepLink: DeepLinkMetadataTag = DeepLinkMetadataTag( deepLinks[ mediateEventTypes.lastIndexOf( event.type ) ] );

			if( deepLink != null ) {
				
				var mediate	: IMetadataTag 	= deepLink.host.getMetadataTagByName( "Mediate" ) || deepLink.host.getMetadataTagByName( "EventHandler" );
				var fields  : Array         = mediate ? mediate.getArg( "properties" ).value.split( /\s*,\s*/ ) : null;
				var args	: Object 		= fields  ? getEventArgs( event, fields ) 							: null;
				
				var url		:String 		= supplant( deepLink.url.replace( /\*/g, "" ), args );
				
				logger.debug( "for mediated event='{0}', browserManager.setFragment( '{1}' )",event.type, url );
				browserManager.setFragment( url );
				
				if( deepLink.title != null ) {
					var title : String = supplant( deepLink.title, args );
					
					logger.debug( "for mediated event='{0}', browserManager.setTitle( '{1}' )",event.type, title );
					browserManager.setTitle( title );
				}
				
				event.stopImmediatePropagation();
				event.preventDefault();
			}
		}
		
		
		// ********************************************************************************************************
		// Utility Methods for Processor configuration
		// ********************************************************************************************************
		
		
		/**
		 *
		 */
		protected function getEventArgs( event:Event, properties:Array ):*
		{
			var args	  : Array   = new Array;
				
				function isComplex():Boolean {
					return (args.length == 1) && (args[0] is Object) && !(args[0] is String);	
				}
				
			for each( var property:String in properties )
			{
				args[ args.length ] = escapeArgs(event[ property ]);
			}
			
			return isComplex() ? args[0] : args;
		}
		
		/**
		 *
		 */
		protected function parseEventTypeExpression( value:String ):String
		{
			if( swiz.config.strict && ClassConstant.isClassConstant( value ) )
			{
				var clazz : Class = ClassConstant.getClass(swiz.domain, value, swiz.config.eventPackages );
				return ClassConstant.getConstantValue(swiz.domain, clazz , ClassConstant.getConstantName( value ) );
			}
			else
			{
				return value;
			}
		}
		
		
		/**
		 * On-demand access to the ILogger for LogProcessor class  
		 * @return 
		 * 
		 */
		protected function get logger():ILogger {
			return Logger.getLogger(this);
		}
		
		protected function escapeArgs(val:*):* {
			var result : * = null;
			
			if (val is String) {
				
				result = enableEscape ? escape( String(val) ) : val;
				
			} else if (val is Object) {
				
				var tmp : Object = new Object;
				
				for (var key:* in val) 
				{
					var kVal:* = val[key] as String;
					
					tmp[key] = 	!kVal 			? val[key] 			: 
								enableEscape	? escape( kVal )	: kVal;
				}
				
				result = tmp;
			}
			
			return result;
		}
				
	}
}