package starlingExtensions.parsers.model
{
import starlingExtensions.animation.player.AnimationFrame;

import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.AnimationProps")]
	public class AnimationProps
	{
		public var fps:Number = 24;
		public var name:String;
		public var frames:Vector.<AnimationFrame> = new Vector.<AnimationFrame>();
				
		public function AnimationProps()
		{
		}
		public function addFrameAt(frame:AnimationFrame,index:int):void
		{
			var numObjects:int = frames.length;
			
			if(index>=numObjects)
			{
				for(var i:int = 0;i<index-numObjects;i++)
				{
					frames.push(null);
				}
			}
			frames[index] = frame;
		}
		public function clone():AnimationProps
		{
			var c:AnimationProps = new AnimationProps();
			ObjUtil.cloneFields(this,c,"fpf","name");
			
			for each(var frame:AnimationFrame in frames)
			{
				c.frames.push(frame.clone());
			}
			return c;
		}
	}
}