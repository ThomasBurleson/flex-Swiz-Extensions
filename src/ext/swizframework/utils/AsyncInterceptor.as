package ext.swizframework.utils
{
	import flash.events.IEventDispatcher;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.swizframework.utils.services.ServiceHelper;

	/**
	 * This utility class provides developers an easy way to intercept
	 * asyncCommands (e.g. calls to delegates) and transform the incoming data
	 * to an output format. Transforms are achieved using method closures.
	 * 
	 * Ideally suited for asynchronous RPC calls where ResultEvent or FaultEvent
	 * data structures need to be transparently converted to expected data constructs.
	 * Such auto-conversion allows the Swiz framework to never have to worry about data
	 * conversions
	 * 
	 * @author thomasburleson
	 * @date   May 3, 2010
	 * 
	 * @code
	 * 		// FormUtils converts Objects to FormVOs
	 * 	    // "agent" is ServiceHelper
	 * 	    // delegate is FormDelegate which uses RemoteObject for its RPC
	 * 
	 * 		var convertor : AsyncInterceptor = new AsyncInterceptor(FormsUtils.toFormVO);
	 *		var token     : AsyncToken 		 = delegate.saveForm(form);		
	 *		var handlers  : IResponder 		 = new Responder(onResults_saveForm, null);
	 *		
	 *		agent.addResponder(convertor.intercept(token),handlers);
	 *   
	 */
	public class AsyncInterceptor
	{
		/**
		 * Construct to configure the transform closures, call scope, and any ServiceHelper fallbacks.
		 *  
		 * @param resultTransformer Closure invoked to transform ResultEven data to custom data
		 * @param faultTransformer	Closure invoked to transform FaultEvent data to custom formats
		 * @param funcScope			Function scope for transform closures
		 * @param agent				Swiz helper class to provide framework-wide response handlers (optional)
		 * 
		 */
		public function AsyncInterceptor(resultTransformer:Function, faultTransformer:Function=null, funcScope:*=null, agent:ServiceHelper=null) {
			_resultTransform	= resultTransformer;
			_faultTransform	    = faultTransformer;
			_scope				= funcScope;
			
			_agent     			= agent;
		}
		
		
		/**
		 * This method will cache the specified token and "intercpet" the async responses. 
		 * A new token is provided and the cached version is used for internal intercept handlers.
		 * 
		 * @param token			AsyncToken provided from invocation of Async operations
		 * @param responders  	Closures to be invoked AFTER the interception and data transformation is finished.
		 * @param agent  	  	ServiceHelper to be invoke on new, proxy token
		 * @param releaseAfter	Should all references be released (for GC) after the intercept handlers are executed
		 * 
		 * @return AsyncToken Proxy async token to which outsiders can add responders, these will be invoked AFTER transformations 
		 * 
		 */
		public function intercept(token:AsyncToken, responders:IResponder=null, agent:ServiceHelper=null, releaseAfter:Boolean=true):AsyncToken {
			_token 			= cloneToken(token);
			_releaseAfter	= releaseAfter;
			
			if (agent == null)  		agent = _agent;
			if (agent && responders) 	agent.executeServiceCall(_token, responders.result, responders.fault);

				// This intercepts the originating response
				addInterceptors(token);
					
			return _token;
		}

		// ***************************************************************************
		// Asynchronous EventHandlers for (original remote method invocation)
		// ***************************************************************************
		
		/**
		 * Closure assigned to handle the ResultEvent or success response of the remote
		 * method call. The assocated data is then transformed and all outside listeners
		 * are notified with the "transformed" data
		 *  
		 * @param data ResultEvent 
		 * 
		 */
		protected function resultHandler(data:Object):void {
			var output : * = data;
			
			if (_resultTransform != null) {
				var input  : * = data.hasOwnProperty("result") ? data['result'] : data;
				
				output = _resultTransform.apply((_scope !=null) ? _scope : this, [input]);
			} 

			for each (var announcer:IResponder in _token.responders) {
				announcer.result(output);
			}
			
			releaseAfter();
		}
		
		/**
		 * Closure assigned to handle the FaultEvent or error response of the remote
		 * method call. The assocated data is then transformed and all outside listeners
		 * are notified with the "transformed" data
		 *  
		 * @param data FaultEvent 
		 * 
		 */
		protected function faultHandler(info:Object):void {
			var output : * = info;
			
			if (_faultTransform != null) {
				var input  : * = info.hasOwnProperty("fault") ? info['fault'] : info; 
				output = _faultTransform.apply((_scope !=null) ? _scope : this, [input]);
			}
			
			for each (var announcer:IResponder in _token.responders) {
				if (announcer.fault != null) announcer.fault(output);
			}

			releaseAfter();
		}
		
		
		
		// ***************************************************************************
		// Private Methods
		// ***************************************************************************

		
		/**
		 * Add private intercept handlers to the original async token.
		 * NOTE: it is assumed that the specified token is CLEAN and that no other 
		 * responders have already been added, otherwise the transformation process is not safe.
		 *  
		 * @param token AsyncToken resulting for invocation of remote operation/method
		 * 
		 */
		private function addInterceptors(token:AsyncToken):void {
			// Assume no other responders ("clean" token)
			token.addResponder(new Responder(resultHandler,faultHandler));
		}
		
		/**
		 * Clone method used to create a proxy copy of the incoming token.
		 * This proxy is to provide all dynamic properties of the original
		 * but responders to this token will not affect the response of the original
		 * invocation.
		 * 
		 * @param token AsyncToken generatored from the original invocation of the async operation
		 * @return AsyncToken clean token for "safe" adding of responders
		 * 
		 */
		private function cloneToken(token:AsyncToken):AsyncToken {
			var results : AsyncToken = new AsyncToken();
			for (var key:String in token) {
				if ((key == "message" || key == "responders")) continue;
				
				results[key] = token[key];
			}
			
			return results;
		}
		
		
		/**
		 * Method to release all references so GC can collect 
		 * 
		 */
		private function releaseAfter():void {
			_token		 	= null;
			
			if (_releaseAfter == true) {
				_resultTransform= null;
				_faultTransform = null;
				_scope		 	= null;
				_agent       	= null;
			}
		}
		
		// ***************************************************************************
		// Private Methods
		// ***************************************************************************

		private var _resultTransform : Function	 = null;
		private var _faultTransform	 : Function  = null;

		/**
		 * Should all references be released after the intercept handlers execute?
		 * If yes, this means that an AsyncInterceptor can only be used once per 
		 * instance. 
		 * 
		 * @defaultValue true 
		 */
		private var _releaseAfter: Boolean       = true;
		
		private var _scope		 : *   	 		 = null;
		private var _token 		 : AsyncToken 	 = null;
		private var _agent	     : ServiceHelper = null;
	}
}