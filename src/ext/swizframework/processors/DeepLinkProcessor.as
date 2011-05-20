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
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.metadata.EventHandlerMetadataTag;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.reflection.ClassConstant;
	import org.swizframework.reflection.Constant;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.reflection.TypeCache;
	import org.swizframework.reflection.TypeDescriptor;
	
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
			
			logger.debug( "Set up link url='{0}' on {1}", deepLink.url, metadataTag.host.name );
		}
		
		/**
		 * Executed when a [DeepLink] has been removed
		 */
		override public function tearDownMetadataTag(metadataTag:IMetadataTag, bean:Bean):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			var method:Function = bean.source[ metadataTag.host.name ] as Function;
			
			removeDeepLink( deepLink, method );
			logger.debug( "Tear down link url='{0}' on {1}", deepLink.url, metadataTag.host.name );
		}
		
		/**
		 * Executed when the browser URL changes
		 */
		public function onBrowserURLChange( event:Event ):void {
			var url:String = event.hasOwnProperty("url") ? event["url"] : "";
			
			url = url.indexOf( "#" ) > -1 ? url.substr( url.indexOf( "#" ) + 1 ) : "";
			
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
			logger.debug( "addDeepLink(url='{0}',title='{1}')", deepLink.url, deepLink.title );
			
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
			logger.debug( "removeDeepLink(url='{0}',title='{1}')", deepLink.url, deepLink.title );
			
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
			
			logger.debug( "add mediation handling for event='{0}'",eventType );
		}
		
		/**
		 * Remove mediate event handler
		 */
		protected function removeEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			swiz.dispatcher.removeEventListener( eventType, mediateEventHandler );
			mediateEventTypes.splice( mediateEventTypes.lastIndexOf( eventType ), 1 );
			
			logger.debug( "remove mediation handling for event='{0}'",eventType );
		}
		
		/**
		 * Process an incoming URL change
		 */
		protected function processDeepLink( match:Array, deepLink:DeepLinkMetadataTag, method:Function ):void
		{
			var parameters:Array = [];
			var placeholders:Array = deepLink.url.match( /\{\d+\}/g );
			
			for each ( var placeholder:String in placeholders ) {
				var index:int = int( placeholder.substr( 1, placeholder.length - 2 ) ) + 1;
				parameters[ parameters.length ] = unescape( match[ index ] );
			}
			
			logger.debug( "incoming url change invokes {0}({1})", String(method), parameters.toString() );
			method.apply( null, parameters );
			
			if( deepLink.title != null ) {
				var title : String = constructUrl( deepLink.title, parameters );
				
				browserManager.setTitle( title );
				logger.debug( "browserManager.setTitle({0})", title );
			}
		}
		
		/**
		 * Sets the url when ever a mediated method is called
		 */
		protected function mediateEventHandler( event:Event ):void
		{
			var deepLink: DeepLinkMetadataTag = DeepLinkMetadataTag( deepLinks[ mediateEventTypes.lastIndexOf( event.type ) ] );
			var mediate	: IMetadataTag 		  = deepLink.host.getMetadataTagByName( "Mediate" ) || deepLink.host.getMetadataTagByName( "EventHandler" );
			var args	: Array 			  = mediate.hasArg( "properties" ) ? getEventArgs( event, mediate.getArg( "properties" ).value.split( /\s*,\s*/ ) ) : null;
			
			if( deepLink != null ) {
				var url:String = deepLink.url;
				    url = url.replace( /\*/g, "" );
				
				if( args != null ) {
					for ( var i:int = 0; i < args.length; i++ ) {
						
						url = url.replace( new RegExp( "\\{" + i + "\\}", "g" ), escape( args[ i ] ) );
					}
				}
				
				logger.debug( "for mediated event='{0}', browserManager.setFragment( '{1}' )",event.type, url );
				browserManager.setFragment( url );
				
				if( deepLink.title != null ) {
					var title : String = constructUrl( deepLink.title, args );
					
					logger.debug( "for mediated event='{0}', browserManager.setTitle( '{1}' )",event.type, title );
					browserManager.setTitle( title );
				}
			}
		}
		
		
		// ********************************************************************************************************
		// Utility Methods for Processor configuration
		// ********************************************************************************************************
		
		
		/**
		 *
		 */
		protected function constructUrl( url:String, params:Array ):String
		{
			for( var i:int = 0; i < params.length; i++ )
			{
				url = url.replace( new RegExp( "\\{" + i + "\\}", "g" ), params[ i ] );
			}
			
			return url;
		}
		
		/**
		 *
		 */
		protected function getEventArgs( event:Event, properties:Array ):Array
		{
			var args:Array = [];
			
			for each( var property:String in properties )
			{
				args[ args.length ] = event[ property ];
			}
			
			return args;
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
				
	}
}