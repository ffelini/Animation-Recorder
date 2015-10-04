package starlingExtensions.animation.recorder
{
import starlingExtensions.abstract.IDisplayObject;
import starlingExtensions.abstract.IDisplayObjectContainer;
import starlingExtensions.animation.player.Animation;
import starlingExtensions.parsers.model.ModelEntity;

public class AnimationRecorderModel extends ModelEntity
	{
		public var animation:Animation;
		public var animationObject:IDisplayObject;
		public var movieClip:IDisplayObjectContainer;
		/**
		 * properties to be recorded 
		 */		
		public var recordProperties:Vector.<Object>;
		/**
		 * curent active animation tools 
		 */		
		public var recordPropertiesTools:Vector.<Object> = new Vector.<Object>();
		
		public var selectedFrames:Vector.<Object>;
		
		public var isRecording:Boolean = false;
		public var isPlaying:Boolean = false;
		public var currentFrame:int;
		
		public function AnimationRecorderModel(data:Object=null)
		{
			super(data);
		}
		public function get hasRecordProperties():Boolean
		{
			return recordProperties && recordProperties.length>0;
		}
	}
}