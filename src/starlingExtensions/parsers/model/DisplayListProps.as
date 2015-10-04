package starlingExtensions.parsers.model
{
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.DisplayListProps")]
	public class DisplayListProps extends DisplayObjectProps
	{
		public var children:Array = [];
		public var animation:AnimationProps;
		public var tweenSequence:TweenSequenceProps;
		
		public function DisplayListProps()
		{
		}
		override public function clone():DisplayObjectProps
		{
			var c:DisplayListProps = new DisplayListProps();
			ObjUtil.cloneFields(this,c,"aliasName","name","x","y","width","height","scaleX","scaleY","skewX","skewY","pivotX","pivotY","rotation","alpha","color","type","hierarchyID","index");
			
			c.tweenSequence = tweenSequence ? tweenSequence.clone() : null;
			c.animation = animation ? animation.clone() : null;
			
			return c;
		}
		
	}
}