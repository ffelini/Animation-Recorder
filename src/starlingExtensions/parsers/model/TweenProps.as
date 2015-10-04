package starlingExtensions.parsers.model
{
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.TweenSequenceProps")]
	public class TweenProps
	{
		public var totalTime:Number;
		public var delay:Number;
		public var repeatCount:int;
		public var repeatDelay:Number;
		public var reverse:Boolean;
		public var roundToInt:Boolean;
		
		public var targetIndex:int;
		public var to:DisplayObjectProps;
		public var properties:Vector.<Object>;
	
		public var transition:String;
		public var name:String;
		
		public function TweenProps()
		{
		}
		public function clone():TweenProps
		{
			var c:TweenProps = new TweenProps();
			
			ObjUtil.cloneFields(this,c,"totalTime","delay","repeatCount","repeatDelay","reverse","roundToInt","targetIndex","transition","name");
			
			c.to = to.clone();
			c.properties = properties.concat();
			
			return c;
		}
	}
}