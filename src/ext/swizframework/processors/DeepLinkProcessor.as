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
	import flash.utils.Dictionary;
	
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
	import org.swizframework.reflection.MetadataArg;
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
		 * Should the urls arguments be escaped/unescaped 
		 */
		public var escapeArgs : Boolean = true;
		
		/**
		 * Should this processor startup in `suspended` mode
		 * where the link request is cached and not processed 
		 */
		public var suspended : Boolean = false;
		
		/**
		 * Registry of DeepLinkItem where deepLinkMetadataTag instance is the key  
		 */		
		protected var registry : Dictionary = new Dictionary(true);

		/**
		 * Was the most recent browser URLChange cached (due to suspension)? 
		 */
		protected var lastURLChange : Event;
		
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
		// Overrides 
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
			var method	:Function 			 = bean.source[ metadataTag.host.name ] as Function;
			
				logger.debug( supplant("setup link url='{url}' on {name}", {url: deepLink.url, name:metadataTag.host.name} ) );
			
			addDeepLink( deepLink, method );
		}
		
		/**
		 * Executed when a [DeepLink] has been removed
		 */
		override public function tearDownMetadataTag(metadataTag:IMetadataTag, bean:Bean):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			
				logger.debug( supplant("teardown link url='{url}' on {name}", {url: deepLink.url, name:metadataTag.host.name}) );
			
			removeDeepLink( deepLink );
		}

		// ========================================
		// protected Event Handlers
		// ========================================
		
		
		/**
		 * Executed when the browser URL changes
		 */
		protected function onBrowserURLChange( event:Event ):void {
			
				/**
				 *  Process browser URL changes by notifying all url `matching` [DeepLink] methods
				 */ 
				function extractURL() : String 
				{
					var url:String = event.hasOwnProperty("url") ? event["url"] : "";
					
					// Strip `#` prefix (if any)
					
					if ( url.indexOf( "#" ) > -1 )
						url = url.substr( url.indexOf( "#" ) + 1 );
				
					return url;
				}
			
			// Ignore event is suspended
			
			lastURLChange = this.suspended ? event : null;
			if ( lastURLChange != null ) 	return;
			
			var url : String = extractURL();
			
  			if (url != "") 
			{
				logger.debug( "onBrowserURLChange(url='{0}')",url );

				// Now process all tag instances whose URL pattern matches
				
				for each ( var it:DeepLinkItem in registry )
				{
					if ( it.shouldProcessURL( url ) ) 
						processLinkURLChange( it, url );
				}
			}
		}
		
		/**
		 * [DeepLink] processing supercedes [Mediate] or [EventHandler] processing.
		 * So intercept, process, and stop propogation if needed.
		 * 
		 */		
		protected function onInterceptEventHandler( event:Event ):void
		{
			var processed : Boolean = false;
			
			for each ( var link:DeepLinkItem in registry )
			{
				if ( link.shouldProcessEvent( event.type ) )
				{
					processed ||= processLinkEvent( link, event );
				}
			}
			
			if ( processed == true) 
			{
				/**
				 * The browserManager.setFragment(), in turn, triggers processLinkURLChange() [above] which itself invokes the method
				 * attached to the [EventHandler] metadata tag. Therefore we need to stop any subsequent EventHandlerProcessor 
				 * activity; used to prevent the eventHandler method from being invoked 2x!
				 */
				
				event.stopImmediatePropagation();
				event.preventDefault();
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
			
				function buildLinkItem( ): DeepLinkItem
				{
					if ( !registry[deepLink] ) {
						registry[ deepLink ] = new DeepLinkItem( deepLink, method );
						
						addMediate( deepLink );
					}
					return registry[ deepLink ];
				}
			
			// check if mapping matches the current url
			
			var url		:String 		= browserManager.url != null ? browserManager.url.substr( browserManager.url.indexOf( "#" ) + 1 ) 	: "";
			var item 	: DeepLinkItem 	= buildLinkItem( );
			
			// if a match is found, process the url change
			
			if ( item.shouldProcessURL( url ) ) 
				processLinkURLChange( item, url );
		}
		
		/**
		 * Remove a URL mapping
		 */
		protected function removeDeepLink( deepLink:DeepLinkMetadataTag ):void {
			logger.debug( supplant("removeDeepLink(url='{url}',title='{title}')", deepLink ) );
			
			var item : DeepLinkItem = registry[ deepLink ];
			if ( item != null ) 
			{
				removeMediate( deepLink );
				delete registry[ deepLink ];
			}
		}
		
		
		/**
		 * Add a reverse URL mapping if possible
		 */
		protected function addMediate( deepLink:DeepLinkMetadataTag ):void
		{
			// For each [Mediate] or [EventHandler] attached in this bean...
			
			for each (var srcTag in  getItemFor(deepLink).mediations )
			{
				var mediateTag : EventHandlerMetadataTag = new EventHandlerMetadataTag();
				    mediateTag.copyFrom(srcTag);
				
					logger.debug( "addMediate(event='{0}')", mediateTag.event );	
					
				if( mediateTag.event.substr( -2 ) == ".*" )
				{
					var clazz:Class 		 = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages );
					var td	 :TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants )
					{
						addEventHandler( deepLink, constant.value );
					}
				}
				else
				{
					addEventHandler( deepLink, parseEventTypeExpression( mediateTag.event ) );
				}
			}
		}
		
		/**
		 * Remove a reverse URL mapping
		 */
		protected function removeMediate( deepLink:DeepLinkMetadataTag ):void
		{
			for each (var srcTag in getItemFor(deepLink).mediations )
			{
				var mediateTag : EventHandlerMetadataTag = new EventHandlerMetadataTag();
					mediateTag.copyFrom(srcTag);
				
					logger.debug( "removeMediate(event='{0}')", mediateTag.event );
				
				if( mediateTag.event.substr( -2 ) == ".*" ) {
					
					var clazz:Class 		 = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages );
					var td	 :TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants )
					{
						removeEventHandler( deepLink, constant.value );
					}
					
				} else {
					
					removeEventHandler( deepLink, parseEventTypeExpression( mediateTag.event ) );
				}
			}
		}
		
		/**
		 * Add mediate event handler
		 */
		protected function addEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			logger.debug( "addEventHandler( event='{0}' )",eventType );
			
			var link : DeepLinkItem = registry[ deepLink ] as DeepLinkItem;
				
				link.addEvent( eventType ) ;
				
			swiz.dispatcher.addEventListener( eventType, onInterceptEventHandler );
		}
		
		/**
		 * Remove mediate event handler
		 */
		protected function removeEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			// Should we remove the global eventListener for this event::type ?
			// Or are other DeepLinkItem's also using the same event::type ?
			
			var clearListener : Boolean = true;
			
			for each (var link:DeepLinkItem in registry) {
				if ( link == getItemFor(deepLink) ) continue;
				
				clearListener ||= !link.shouldProcessEvent( eventType )
			}
			
			if ( clearListener == true) 
			{
				logger.debug( "remove eventHandler( event='{0}' )",eventType );
				
				swiz.dispatcher.removeEventListener( eventType, onInterceptEventHandler );
			}
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
		 */
		protected function processLinkURLChange( link:DeepLinkItem, url:String ):void
		{
			if ( suspended == true) return;
			
				/**
				 * Does the target method expect a single argument with multiple fields
				 * or multiple arguments?
				 */
				function isComplexArg():Boolean {
					return (link.methodArgs.length == 1) && (fields.length > 1);	
				}
				
			var fields    :Array  = link.urlTokens;
			var values    :Array  = link.extractURLValues(url);
			var parameters:*      = isComplexArg() ?  new Object : new Array;
			
			for ( var j:int=0; j<fields.length; j++) 
			{
				var fieldVal : String = String( values[j] );
				
				if ( parameters is Array ) parameters.push( unescape( fieldVal ) );
				else                       parameters[ fields[j] ] = unescape( fieldVal );
			}
			
			// Set the Browser title
			
			if( link.title != null ) {
				var title : String = supplant( link.title, parameters );
				
				browserManager.setTitle( title );
				logger.debug( "browserManager.setTitle( '{0}' )", title );
			}
			
			// Call the method associated with [EventHandler(event="",properties="")]
			// 
			// !!! Important: with [DeepLink] the target method is ONLY invoked 
			//                based on a URL change.
			
			if ( link.method != null) 
			{
				logger.debug( "incoming url change invokes function({0})", utils.string.toString(parameters,",") );

				/**
				 * Please notice that no argument type creation is attempted!
				 * 
				 * NOTE: the funtion(args){ ... } method must accept arguments of:
				 *     i.) Array of scalar values
				 *    ii.) Hashmap (generic object) of name/value pairs
				 */
				link.method.apply( null, toArray(parameters) );
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
		 * NOTE: this process calls ::setFragment() which in turn invokes the processLinkURLChange() above...
		 * 
		 */
		protected function processLinkEvent(link:DeepLinkItem, event:Event):Boolean {
			var processed : Boolean = false;
			
			updateSuspension(link);
			
			if( link && !this.suspended ) {
				
				if ( lastURLChange != null )
					onBrowserURLChange( lastURLChange );
				
				var args : Object = getEventArgs( event, link );
				
				if( link.title != null ) 
				{
					var title : String = supplant( link.title, args );
					
					logger.debug( "for mediated event='{0}', browserManager.setTitle( '{1}' )",event.type, title );
					browserManager.setTitle( title );
				}
				
				if ( link.url != null ) 
				{
					var url		:String 		= supplant( link.url.replace( /\*/g, "" ), args );
					
					logger.debug( "for mediated event='{0}', browserManager.setFragment( '{1}' )",event.type, url );
					browserManager.setFragment( url );
				}
				
				processed = true;
			}
			
			return processed;
		}
		
		// ********************************************************************************************************
		// Utility Methods for Processor configuration
		// ********************************************************************************************************
		
		
		/**
		 * Easy lookup of DeepLinkItem (with type casting)
		 *  
		 * @param deepLink DeepLinkMetadataTag xref in registry
		 * @return DeepLinkItem
		 */
		protected function getItemFor( deepLink:DeepLinkMetadataTag ) : DeepLinkItem 
		{
			return registry[ deepLink ] as DeepLinkItem;	
		}
		

		/**
		 * This method allows any [DeepLink(suspend="true|false")] tag to activate/deactivate the DeepLink processing.
		 * If OFF [suspended], then onBrowserURLChange() and onInterceptEventHandler() as disabled.
		 *  
		 * @param deepLink DeepLinkMetadataTag instance associated with any event.
		 */		
		protected function updateSuspension(link:DeepLinkItem) : void {
			if ( link == null ) return;
			
			if ( link.suspend != null ) {
			
				switch ( link.suspend.toLowerCase() )
				{
					case "true" : 	this.suspended = true;	break;
					case "false":	this.suspended = false;	break;
				}
				
			}
		}
		
		/**
		 * Grab any specified event property values and save to array or hashmap
		 * 
		 *  i.) array used to match {0}, {1}, etc patterns
		 * ii.) hashmap used to match {key1}, {key2} patterns; where key is the hashmap key
		 * 
		 */
		protected function getEventArgs( event:Event, link : DeepLinkItem ):*
		{
			var keys  : Array  = link.methodArgs;
			var args  : Array  = [ ];
				
				function isComplex():Boolean {
					return (args.length == 1) && (args[0] is Object) && !(args[0] is String);	
				}
				
			for each( var property:String in keys || [ ])
			{
				args[ args.length ] = escapeValue( event[ property ]);
			}
			
			return 	(keys == null)	? null	  :
					isComplex() 	? args[0] : args;
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
		
		protected function escapeValue(val:*):* {
			var result : * = null;
			
			if (val is String) {
				
				result = escapeArgs ? escape( String(val) ) : val;
			
			} else if (val is Number) {
				
				result = val;
				
			} else if (val is Object) {
				
				var tmp : Object = new Object;
				
				for (var key:* in val) 
				{
					var kVal:* = val[key] as String;
					
					tmp[key] = 	!kVal 		? val[key] 			: 
								escapeArgs	? escape( kVal )	: kVal;
				}
				
				result = tmp;
			}
			
			return result;
		}
				
	}
}


import ext.swizframework.metadata.DeepLinkMetadataTag;
import flash.utils.Dictionary;
import org.swizframework.reflection.IMetadataTag;

class DeepLinkItem {
	
	/**
	 * Any target method may have 0-n [EventHandler] or [Mediate] tags associated.
	 * Gather a list of all such assoication... 
	 */
	public function get mediations():Array 
	{
		var results: Array = [ ];
		
		for each (var it:IMetadataTag in _deepLink.host.metadataTags) {
			switch(it.name) {
				case "EventHandler" :
				case "Mediate"		:  results.push(it);  break;
			}
		}
		
		return results;
	}
	
	/**
	 * Method to invoke when onBrowserURLChange() is detected 
	 */
	public function get method()   : Function			{	return _method;										}
	
	/**
	 * When intercepting an [EventHandler(event="",properties="")], extract 
	 * the property names specified. 
	 */
	public function get methodArgs():Array {
		var mediate    : IMetadataTag = mediations && mediations.length ? mediations[0] as IMetadataTag : null;
		
		return mediate ? mediate.getArg( "properties" ).value.split( /\s*,\s*/ ) : null;
	}
	
	/**
	 * Value of the suspend flag (if specified... optional)
	 */
	public function get suspend() : String				{	return _deepLink.suspend;							}
	
	/**
	 * Template/pattern of URL that is managed by this DeepLinkItem 
	 * Specified in the [DeepLink(title=`xxx`)] metadata tag 
	 */
	public function get title() : String 				{	return _deepLink.title;								}
	
	/**
	 * Template/pattern of URL that is managed by this DeepLinkItem
	 * Specified in the [DeepLink(url=`xxx`)] metadata tag 
	 */
	public function get url() : String 					{	return _deepLink.url;								}
	
	/**
	 * Returns an array of fields matches (if any) for the specified `real` URL
	 * based on the template pattern [DeepLink(url='xxx')]
	 */
	
	public function get urlTokens() : Array 			{   return _urlTokens;									}
	
	// ***************************************************************************
	// Public methods 
	// ***************************************************************************
	
	public function addEvent( eventType:String) : void {
		eventType ||= "";
		
		if (eventType != "")
			_events[ eventType ] = true; 
	}

	/**
	 * 
	 */
	public function shouldProcessEvent( eventType:String ) : Boolean {
		eventType ||= "";
		
		return (eventType != "") ? (_events[ eventType ] != null) : false;
	}
	
	public function shouldProcessURL( url : String) : Boolean 	
	{	
		return _regexp ? url.match( _regexp ) != null : false;		
	}
	
	
	/**
	 * Using the link url expression, extract the field
	 * values from the specified url.
	 *  
	 * @param url String with url matching current link settings
	 * @return Array of field/token values extracted. 
	 */
	public function extractURLValues( url:String ) : Array		
	{ 
		var results: Array = [ ];
		var buffer : Array = _regexp ? url.match( _regexp ) : null;
		
		if ( buffer != null ){
			
			for (var j:int=1; j<buffer.length; j++) 
				results.push( String(buffer[j]).replace( /\{/gi,"").replace( /\}/gi,"") );
		}
			
		return buffer ? results : null;
	}
	
		
	// ***************************************************************************
	// Constructor 
	// ***************************************************************************
	
	public function DeepLinkItem( tag:DeepLinkMetadataTag, method:Function )
	{
		_deepLink   = tag;
		_method 	= method;
		
		buildRegExp (tag.url);
	}
	
	// ***************************************************************************
	// Protected Methods 
	// ***************************************************************************
	
	/**
	 * Build a `proper` regexp pattern matcher for URL onBrowserURLChanges() 
	 * @param url String specified in the [DeepLink(url=`xxx`)] metadata tag
	 * 
	 */
	protected function buildRegExp( url:String ) : void{
		url ||= "";
		
		// If no URL then, no pattern matching or processing of link (obviously) 
		// NOTE: need to allow the last URL parameter to be optional
		
		var pattern :String = url.replace( /[\\\+\?\|\[\]\(\)\^\$\.\,\#]{1}/g, "\$1" ).replace( /\*/g, ".*" ).replace( /\{.+?\}/g, "(.+?)" ) + "$";
			pattern = "^" + pattern.replace( /\(\.\+\?\)\$/g, "(.*?)" + "$" );
			
		_regexp 	= (url != "") ? new RegExp(pattern) 			: null;	
		_urlTokens 	= (url != "") ? url.match( /\{([^\{\}]*)\}/g ) 	: null;
	}

	// ***************************************************************************
	// Protected Attributes 
	// ***************************************************************************
	
	protected var _method   : Function;
	
	/**
	 * Tag instance created by Swiz; one for each bean 
	 */
	protected var _deepLink : DeepLinkMetadataTag;

	
	/**
	 * Array of event::type strings associated with methods that are mediated... 
	 * Since the [DeepLink] can be `attached` to method with multiple [EventHandler] tags
	 */
	protected var _events    : Dictionary = new Dictionary(true);

	
	/**
	 * Regexp to use to match again url changes 
	 */	
	private var _regexp 	: RegExp;
	
	/**
	 * Array of token names used in the URL template
	 * 
	 * e.g.  [DeepLink(url='/container/uid={serialNumber}/params={options}')]
	 *       [DeepLink(url='/container/uid={0}/params={1}')]
	 */
	private var _urlTokens : Array;
	
	
}