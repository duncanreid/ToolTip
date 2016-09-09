package com.novelastudios.ui.strategies
{
	import com.hybrid.ui.strategies.IToolTipTweenStrategy;
	
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	
	import com.greensock.TweenLite;
	
	/**
	 * @author JohnBailey, NovelaStudios ©2010
	 */
	public class ToolTipTweenStrategy extends EventDispatcher implements IToolTipTweenStrategy
	{		
		
		///////////////////////////////////////////////////////////////////////////////
		//								ACCESSORS
		///////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////
		//-------------------------
		//	onComplete
		//-------------------------
		private var _onComplete:Function;
		private var _hasOnComplete:Boolean;
		public function set onComplete(value:Function):void
		{
			_onComplete = value;
			_hasOnComplete = Boolean(value != null);
		}
		
		public function get onComplete():Function
		{
			return _onComplete;
		}
		
		///////////////////////////////////////////////////////////////////////////////
		//								PUBLIC METHODS
		///////////////////////////////////////////////////////////////////////////////
		public function animate(value:Boolean, target:DisplayObject):void
		{
			var end:int = value == true ? 1 : 0;
			var transitionOptions:Object = {};
			transitionOptions["alpha"] = end;
			if(!value)transitionOptions["onComplete"] = handleCompleteEvent;
			TweenLite.to(target,.5,transitionOptions);
		}
		
		///////////////////////////////////////////////////////////////////////////////
		//								HANDLERS
		///////////////////////////////////////////////////////////////////////////////
		protected function handleCompleteEvent():void
		{
			if(_hasOnComplete) onComplete();
		}
	}
}