package starlingExtensions.parsers.model
{
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.TweenSequenceProps")]
	public class TweenSequenceProps
	{
		public var tweens:Vector.<TweenProps> = new Vector.<TweenProps>();
		public var name:String= "";
		
		public function TweenSequenceProps()
		{
		}
		public function clone():TweenSequenceProps
		{
			var c:TweenSequenceProps = new TweenSequenceProps();
			ObjUtil.cloneFields(this,c,"name");
			
			for each(var tween:TweenProps in tweens)
			{
				c.tweens.push(tween.clone());
			}
			return c;
		}
	}
}