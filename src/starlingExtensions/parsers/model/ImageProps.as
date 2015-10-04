package starlingExtensions.parsers.model
{
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.ImageProps")]
	public class ImageProps extends DisplayObjectProps
	{
		public var atlasName:String;
		public var textureName:String;
		
		public var topColor:uint = 0xFFFFFF;
		public var bottomColor:uint = 0xFFFFFF;
		public var leftColor:uint = 0xFFFFFF;
		public var rightColor:uint = 0xFFFFFF;
		
		public var topAlpha:Number;
		public var bottomAlpha:Number;
		public var leftAlpha:Number;
		public var rightAlpha:Number;
		
		public var textureExtrusion:Number;
		public var scale3TextureDirection:String;
		
		public function ImageProps()
		{
			super();
		}
		override public function clone():DisplayObjectProps
		{
			var c:ImageProps = new ImageProps();
			ObjUtil.cloneFields(this,c,"atlasName","textureName","topColor","bottomColor","leftColor","rightColor","topAlpha","bottomAlpha","leftAlpha","rightAlpha","textureExtrusion","scale3TextureDirection",
				"aliasName","name","x","y","width","height","scaleX","scaleY","skewX","skewY","pivotX","pivotY","rotation","alpha","color","type","hierarchyID","index");
			return c;
		}
	}
}