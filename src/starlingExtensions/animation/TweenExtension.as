package starlingExtensions.animation
{
import flash.utils.Dictionary;

import starling.animation.Tween;

public class TweenExtension extends Tween
	{
		public static var tweensByTarget:Dictionary = new Dictionary();
		
		public function TweenExtension(target:Object, time:Number, transition:Object="linear")
		{
			super(target, time, transition);
		}
		public function resetProgress():void
		{	
			mCurrentTime = 0.0;
			mProgress = 0.0;
			mCurrentCycle = -1;
			_playing = true;
		}
		public function set totalTime(value:Number):void { mTotalTime = Math.max(0.0001, value); }
		
		override public function reset(target:Object, time:Number, transition:Object="linear"):Tween
		{
			var _tweens:Vector.<TweenExtension> = tweensByTarget[target] as Vector.<TweenExtension>;
			if(!_tweens) 
			{
				_tweens = new Vector.<TweenExtension>();
				tweensByTarget[target] = _tweens;
			}
			if(_tweens.indexOf(this)<0) _tweens.push(this);
			_playing = true;
			
			return super.reset(target, time, transition);
		}
		private var _playing:Boolean = false;
		public function get playing():Boolean
		{
			return _playing;
		}
		public function pause():void
		{
			_playing = false;
		}
		public function resume():void
		{
			_playing = true;
		}
		override public function advanceTime(time:Number):void
		{
			if(!_playing) return;
			super.advanceTime(time);
		}	
		public static function updateTweens(obj:Object,play:Boolean):void
		{
			var _tweens:Vector.<TweenExtension> = tweensByTarget[obj] as Vector.<TweenExtension>;
			for each(var t:TweenExtension in _tweens)
			{
				play ? t.resume() : t.pause();
			}
		}
	}
}