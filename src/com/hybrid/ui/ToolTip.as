
/**

The MIT License

Copyright (c) 2008 Duncan Reid ( http://www.hy-brid.com )

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

**/



package com.hybrid.ui {
	
	
	import com.hybrid.ui.strategies.IToolTipTweenStrategy;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.utils.Timer;
	
	/**
	 * Public Setters:
	 
	 *		tipWidth 				Number				Set the width of the tooltip
	 *		titleFormat				TextFormat			Format for the title of the tooltip
	 * 		stylesheet				StyleSheet			StyleSheet object
	 *		contentFormat			TextFormat			Format for the bodycopy of the tooltip
	 *		titleEmbed				Boolean				Allow font embed for the title
	 *		contentEmbed			Boolean				Allow font embed for the content
	 *		align					String				left, right, center
	 *		delay					Number				Time in milliseconds to delay the display of the tooltip
	 *		hook					Boolean				Displays a hook on the bottom of the tooltip
	 *		hookSize				Number				Size of the hook
	 *		cornerRadius			Number				Corner radius of the tooltip, same for all 4 sides
	 *		colors					Array				Array of 2 color values ( [0xXXXXXX, 0xXXXXXX] ); 
	 *		autoSize				Boolean				Will autosize the fields and size of the tip with no wrapping or multi-line capabilities, 
	 													 helpful with 1 word items like "Play" or "Pause"
	 * 		border					Number				Color Value: 0xFFFFFF
	 *		borderSize				Number				Size Of Border
	 *		buffer					Number				text buffer
	 * 		bgAlpha					Number				0 - 1, transparency setting for the background of the ToolTip
	 *
	 * Example:
	 
	 		var tf:TextFormat = new TextFormat();
			tf.bold = true;
			tf.size = 12;
			tf.color = 0xff0000;
			
			var tt:ToolTip = new ToolTip();
			tt.hook = true;
			tt.hookSize = 20;
			tt.cornerRadius = 20;
			tt.align = "center";
			tt.titleFormat = tf;
			tt.show( DisplayObject, "Title Of This ToolTip", "Some Copy that would go below the ToolTip Title" );
	 *
	 *
	 * @author Duncan Reid, www.hy-brid.com
	 * @date October 17, 2008
	 * @version 1.2
	 */
	 
	public class ToolTip extends Sprite {
		

		//objects
		protected var _stage:Stage;
		protected var _parentObject:DisplayObject;
		protected var _tf:TextField;  // title field
		protected var _cf:TextField;  //content field
		protected var _contentContainer:Sprite = new Sprite(); // container to hold both textfields
		//protected var _tween:Tween;
		
		//formats
		protected var _titleFormat:TextFormat;
		protected var _contentFormat:TextFormat;
		
		//stylesheet
		protected var _stylesheet:StyleSheet;
		
		/* check for stylesheet override */
		protected var _styleOverride:Boolean = false;
		
		/* check for format override */
		protected var _titleOverride:Boolean = false;
		protected var _contentOverride:Boolean = false;
		
		// font embedding
		protected var _titleEmbed:Boolean = false;
		protected var _contentEmbed:Boolean = false;
		
		//defaults
		protected var _defaultWidth:Number = 200;
		protected var _defaultHeight:Number;
		protected var _padding:Number = 10;
		protected var _align:String = "center"
		protected var _cornerRadius:Number = 12;
		protected var _bgColors:Array = [0xFFFFFF, 0x9C9C9C];
		protected var _autoSize:Boolean = false;
		protected var _hookEnabled:Boolean = false;
		protected var _delay:Number = 0;  //millilseconds
		protected var _hookSize:Number = 10;
		protected var _borderColor:Number;
		protected var _borderAlpha:Number;
		protected var _borderSize:Number = 0;
		protected var _bgAlpha:Number = 1;  // transparency setting for the background of the tooltip
		
		//offsets
		protected var _offSetBottom:Number = 5
		protected var _offSet:Number;
		protected var _hookOffSet:Number;
		
		//delay
		protected var _timer:Timer;
		
		protected var _tweenStrategy:IToolTipTweenStrategy;
		protected var _followMouse:Boolean = true;
		protected var _speed:Number = 3;
		

	
		public function ToolTip(tweenStrategy:IToolTipTweenStrategy):void {
			//do not disturb parent display object mouse events
			this.mouseEnabled = false;
			this.buttonMode = false;
			this.mouseChildren = false;
			//setup delay timer
			_timer = new Timer(this._delay, 1);
            _timer.addEventListener("timer", timerHandler);
			
			_tweenStrategy = tweenStrategy;
			_tweenStrategy.onComplete = cleanUp;
		}
		
		public function setContent( title:String, content:String = null ):void {
			this.graphics.clear();
			this.addCopy( title, content );
			this.setOffset();
			this.drawBG();
		}
		
		public function show( p:DisplayObject, title:String, content:String=null):void {
			//get the stage from the parent
			this._stage = p.stage;
			this._parentObject = p;
			// added : DR : 04.29.2010
			var onStage:Boolean = this.addedToStage( this._contentContainer );
			if( ! onStage ){
				this.addChild( this._contentContainer );
			}
			// end add
			this.addCopy( title, content );
			this.setOffset();
			this.drawBG();
			this.bgGlow();
			
			//initialize coordinates
			var parentCoords:Point = new Point( _parentObject.mouseX, _parentObject.mouseY );
			var globalPoint:Point = p.localToGlobal(parentCoords);
			this.x = globalPoint.x + this._offSet;
			this.y = globalPoint.y - this.height - _offSetBottom;
			
			this.alpha = 0;
			this._stage.addChild( this );
			this._parentObject.addEventListener( MouseEvent.ROLL_OUT, this.onMouseOut );
			//removed mouse move handler in lieu of enterframe for smoother movement
			//this._parentObject.addEventListener( MouseEvent.MOUSE_MOVE, this.onMouseMovement );
			
			if (followMouse) {
				follow(true);
			} else {
				position();
			}
			
            _timer.start();
		}
		
		public function hide():void {
			this.animate( false );
		}
		
		protected function timerHandler( event:TimerEvent ):void {
			this.animate(true);
		}

		protected function onMouseOut( event:MouseEvent ):void {
			event.currentTarget.removeEventListener(event.type, arguments.callee);
			this.hide();
		}
		
		protected function follow( value:Boolean ):void {
			if( value ){
				addEventListener( Event.ENTER_FRAME, this.eof );
			}else{
				removeEventListener( Event.ENTER_FRAME, this.eof );
			}
		}
		
		protected function eof( event:Event ):void {
			this.position();
		}
		
		protected function position():void {
			var globalPoint:Point = _parentObject.localToGlobal(parentCoords);
			var xp:Number = globalPoint.x + this._offSet;
			var yp:Number = globalPoint.y - defaultHeight - _offSetBottom;
		
		
			/*switch(placement)
			{
				default:
				case "top":
					xp  = globalPoint.x + _offSet;
					yp	= globalPoint.y - height - 10;
					break;
				
				case "bottom":
					xp  = globalPoint.x + _offSet;
					yp	= globalPoint.y - height + getBounds(this).height + 10;
					break;
			}*/

			var overhangRight:Number = this.defaultWidth + xp;
			if( overhangRight > stage.stageWidth ) {
				xp =  stage.stageWidth -  this.defaultWidth;
			}
			if( xp < 0 ) {
				xp = 0;
			}
			if( (yp) < 0 ){
				yp = 0;
			}
			this.x += ( xp - this.x ) / speed;
			this.y += ( yp - this.y ) / speed;
		}
		
		protected function get parentCoords():Point {
			return new Point( _parentObject.mouseX, _parentObject.mouseY);
		}
	
		protected function addCopy( title:String, content:String = null ):void {
			if( this._tf == null ){
				this._tf = this.createField( this._titleEmbed ); 
			}
			// if using a stylesheet for title field
			if( this._styleOverride ){
				this._tf.styleSheet = this._stylesheet;
			}
			this._tf.htmlText = title;
			
			// if not using a stylesheet
			if( ! this._styleOverride ){
				// if format has not been set, set default
				if( ! this._titleOverride ){
					this.initTitleFormat();
				}
				this._tf.setTextFormat( this._titleFormat );
			}
			if( this._autoSize ){
				this._defaultWidth = this._tf.textWidth + 4 + ( _padding * 2 );
			}else{
				this._tf.width = this.defaultWidth - ( _padding * 2 );
			}
			
			
				
			this._tf.x = this._tf.y = this._padding;
			this.textGlow( this._tf );
			this._contentContainer.addChild( this._tf );
			
			//if using content
			if( content != null ){
				
				if( this._cf == null ){
					this._cf = this.createField( this._contentEmbed );
				}
				
				// if using a stylesheet for title field
				if( this._styleOverride ){
					this._cf.styleSheet = this._stylesheet;
				}
			
				this._cf.htmlText = content;
				
				// if not using a stylesheet
				if( ! this._styleOverride ){
					// if format has not been set, set default
					if( ! this._contentOverride ){
						this.initContentFormat();
					}
					this._cf.setTextFormat( this._contentFormat );
				}
			
				var bounds:Rectangle = this.getBounds( this );
				
				this._cf.x = this._padding;
				this._cf.y = this._tf.y +  this._tf.textHeight;
				this.textGlow( this._cf );
				
				if( this._autoSize ){
					var cfWidth:Number = this._cf.textWidth + 4 + ( _padding * 2 )
					this._defaultWidth = cfWidth > this.defaultWidth ? cfWidth : this.defaultWidth;
				}else{
					this._cf.width = this.defaultWidth - ( _padding * 2 );
				}
				this._contentContainer.addChild( this._cf );	
			}
		}
		
		//create field
		protected function createField( embed:Boolean ):TextField {
			var tf:TextField = new TextField();
			tf.embedFonts = embed;
			tf.gridFitType = "pixel";
			//tf.border = true;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.selectable = false;
			if( ! this._autoSize ){
				tf.multiline = true;
				tf.wordWrap = true;
			}
			return tf;
		}
		
		//draw background, use drawing api if we need a hook
		protected function drawBG():void {
			
			/* re-add : 04.29.2010 : clear graphics in the event this is a re-usable tip */
			this.graphics.clear();
			/* end add */
			var bounds:Rectangle = this.getBounds( this );

			var h:Number = isNaN( this.defaultHeight ) ? bounds.height + ( this._padding * 2 ) : this.defaultHeight;
			
			if (this._borderSize > 0) {
				this.graphics.lineStyle( _borderSize, _borderColor, 1 );
			}
			
			drawGradient(h);
		
			if ( this._hookEnabled ) {
				var xp:Number = 0; var yp:Number = 0; var w:Number = this.defaultWidth; 
				this.graphics.moveTo ( xp + this._cornerRadius, yp );
				this.graphics.lineTo ( xp + w - this._cornerRadius, yp );
				this.graphics.curveTo ( xp + w, yp, xp + w, yp + this._cornerRadius );
				this.graphics.lineTo ( xp + w, yp + h - this._cornerRadius );
				this.graphics.curveTo ( xp + w, yp + h, xp + w - this._cornerRadius, yp + h );
				
				//hook
				this.graphics.lineTo ( xp + this._hookOffSet + this._hookSize, yp + h );
				this.graphics.lineTo ( xp + this._hookOffSet , yp + h + this._hookSize );
				this.graphics.lineTo ( xp + this._hookOffSet - this._hookSize, yp + h );
				this.graphics.lineTo ( xp + this._cornerRadius, yp + h );
				
				this.graphics.curveTo ( xp, yp + h, xp, yp + h - this._cornerRadius );
				this.graphics.lineTo ( xp, yp + this._cornerRadius );
				this.graphics.curveTo ( xp, yp, xp + this._cornerRadius, yp );
				this.graphics.endFill();
			} else {
				this.graphics.drawRoundRect( 0, 0, this.defaultWidth, h, this._cornerRadius );
			}
		}
		
		protected function drawGradient(h:Number):void {
			var fillType:String = GradientType.LINEAR;
			//var colors:Array = [0xFFFFFF, 0x9C9C9C];
			var alphas:Array = [ this._bgAlpha, this._bgAlpha];
			var ratios:Array = [0x00, 0xFF];
			var matr:Matrix = new Matrix();
			var radians:Number = 90 * Math.PI / 180;
			matr.createGradientBox(this.defaultWidth, h, radians, 0, 0);
			var spreadMethod:String = SpreadMethod.PAD;
			
			this.graphics.beginGradientFill(fillType, this._bgColors, alphas, ratios, matr, spreadMethod); 
		}

			
		/* Fade In / Out */
		
		protected function animate( value:Boolean ):void 
		{
			if(_tweenStrategy)
			{
				_tweenStrategy.animate(value,this);
			}
			else
			{
				alpha = value ? 1 : 0;
				if(!value) cleanUp();
			}
			
			if(!value)
			{
				_timer.reset();
			}
		}
	
		/* End Fade */
			

		/** Getters / Setters */
		public function set offSetBottom( value:Number ):void {
			this._offSetBottom = value;
		}
		
		public function set padding( value:Number ):void {
			this._padding = value;
		}
		
		public function get padding():Number {
			return this._padding;
		}
		
		public function set bgAlpha( value:Number ):void {
			this._bgAlpha = value;
		}
		
		public function get bgAlpha():Number {
			return this._bgAlpha;
		}
		
		public function set tipWidth( value:Number ):void {
			this._defaultWidth = value;
		}
		
		public function set titleFormat( tf:TextFormat ):void {
			this._titleFormat = tf;
			if( this._titleFormat.font == null ){
				this._titleFormat.font = "_sans";
			}
			this._titleOverride = true;
		}
		
		public function set contentFormat( tf:TextFormat ):void {
			this._contentFormat = tf;
			if( this._contentFormat.font == null ){
				this._contentFormat.font = "_sans";
			}
			this._contentOverride = true;
		}
		
		public function set stylesheet( ts:StyleSheet ):void {
			this._stylesheet = ts;
			this._styleOverride = true;
		}
		
		public function set align( value:String ):void {
			this._align = value;
		}
		
		public function set delay( value:Number ):void {
			this._delay = value;
			this._timer.delay = value;
		}
		
		public function set hook( value:Boolean ):void {
			this._hookEnabled = value;
		}
		
		public function set hookSize( value:Number ):void {
			this._hookSize = value;
		}
		
		public function set cornerRadius( value:Number ):void {
			this._cornerRadius = value;
		}
		
		public function set colors( colArray:Array ):void {
			this._bgColors = colArray;
		}
		
		public function set autoSize( value:Boolean ):void {
			this._autoSize = value;
		}
		
		public function set borderColor( value:Number ):void {
			this._borderColor = value;
		}
		
		public function set borderAlpha( value:Number ):void {
			this._borderAlpha = value;
		}
		
		public function set borderSize( value:Number ):void {
			this._borderSize = value;
		}
		
		public function set tipHeight( value:Number ):void {
			this._defaultHeight = value;
		}

		public function set titleEmbed( value:Boolean ):void {
			this._titleEmbed = value;
		}
		
		public function set contentEmbed( value:Boolean ):void {
			this._contentEmbed = value;
		}
		
		public function get tweenStrategy() : IToolTipTweenStrategy
		{
			return _tweenStrategy;
		}
		
		public function get defaultHeight():Number
		{
			return this._defaultHeight;
		}
		
		public function get defaultWidth():Number
		{
			return this._defaultWidth;
		}
		/**
		 * This is the what will be used for tweening the ToolTip. If not set, the ToolTip will simply show without animation.
		 * 	Ergo, settings and properties such as <i>delay</i> will be ignored. 
		 * 
		 * @param value Any object that implements IToolTipTweenStrategy.
		 * 
		 */		
		public function set tweenStrategy( value : IToolTipTweenStrategy ) : void
		{
			_tweenStrategy = value;
			if(value) _tweenStrategy.onComplete = cleanUp;
			dispatchEvent( new Event( "tweenStrategyChange" ) );
		}
		
		public function set followMouse( value:Boolean ):void {
			this._followMouse = value;
		}
		
		public function get followMouse():Boolean {
			return this._followMouse;
		}
		
		public function set speed( value:Number ):void {
			this._speed = value;
		}
		
		public function get speed():Number {
			return this._speed;
		}
		
		
		
		
		/* End Getters / Setters */
		
		
		
		/* Cosmetic */
		
		protected function textGlow( field:TextField ):void {
			var color:Number = 0x000000;
            var alpha:Number = 0.35;
            var blurX:Number = 2;
            var blurY:Number = 2;
            var strength:Number = 1;
            var inner:Boolean = false;
            var knockout:Boolean = false;
            var quality:Number = BitmapFilterQuality.HIGH;

           var filter:GlowFilter = new GlowFilter(color,
                                  alpha,
                                  blurX,
                                  blurY,
                                  strength,
                                  quality,
                                  inner,
                                  knockout);
            var myFilters:Array = new Array();
            myFilters.push(filter);
        	field.filters = myFilters;
		}
		
		protected function bgGlow():void {
			var color:Number = 0x000000;
            var alpha:Number = 0.20;
            var blurX:Number = 5;
            var blurY:Number = 5;
            var strength:Number = 1;
            var inner:Boolean = false;
            var knockout:Boolean = false;
            var quality:Number = BitmapFilterQuality.HIGH;

           var filter:GlowFilter = new GlowFilter(color,
                                  alpha,
                                  blurX,
                                  blurY,
                                  strength,
                                  quality,
                                  inner,
                                  knockout);
            var myFilters:Array = new Array();
            myFilters.push(filter);
            filters = myFilters;
		}
		
		protected function initTitleFormat():void {
			_titleFormat = new TextFormat();
			_titleFormat.font = "_sans";
			_titleFormat.bold = true;
			_titleFormat.size = 20;
			_titleFormat.color = 0x333333;
		}
		
		protected function initContentFormat():void {
			_contentFormat = new TextFormat();
			_contentFormat.font = "_sans";
			_contentFormat.bold = false;
			_contentFormat.size = 14;
			_contentFormat.color = 0x333333;
		}
	
		/* End Cosmetic */
	
	
		
		/* Helpers */
		
		protected function addedToStage( displayObject:DisplayObject ):Boolean {
			var hasStage:Stage = displayObject.stage;
			return hasStage == null ? false : true;
		}
		
		protected function setOffset():void {
			switch( this._align ){
				case "left":
					this._offSet = - defaultWidth +  ( _padding * 3 ) + this._hookSize; 
					this._hookOffSet = this.defaultWidth - ( _padding * 3 ) - this._hookSize; 
				break;
				
				case "right":
					this._offSet = 0 - ( _padding * 3 ) - this._hookSize;
					this._hookOffSet =  _padding * 3 + this._hookSize;
				break;
				
				case "center":
					this._offSet = - ( defaultWidth / 2 );
					this._hookOffSet =  ( defaultWidth / 2 );
				break;
				
				default:
					this._offSet = - ( defaultWidth / 2 );
					this._hookOffSet =  ( defaultWidth / 2 );
				break;
			}
		}
		
		/* End Helpers */
		
		
		
		/* Clean */
		
		protected function cleanUp():void {
			this._parentObject.removeEventListener( MouseEvent.ROLL_OUT, this.onMouseOut );
			//this._parentObject.removeEventListener( MouseEvent.MOUSE_MOVE, this.onMouseMovement );
			this.follow( false );
			this._tf.filters = [];
			this.filters = [];
			this._contentContainer.removeChild( this._tf );
			this._tf = null;
			if( this._cf != null ){
				this._cf.filters = []
				this._contentContainer.removeChild( this._cf );
			}
			this.graphics.clear();
			removeChild( this._contentContainer );
			parent.removeChild( this );
		}
		
		/* End Clean */

		
	}
}
