package starlingExtensions.parsers.model
{
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.TextProps")]
	public class TextProps extends DisplayObjectProps
	{
		public var text:String = "no text";
		public var fontName:String;
		public var bold:Boolean;
		public var fontSize:int = 12;
		public var hAlign:String;
		public var vAlign:String;
		
		public function TextProps()
		{
			super();
		}
		override public function clone():DisplayObjectProps
		{
			var c:TextProps = new TextProps();
			ObjUtil.cloneFields(this,c,"text","fontName","bold","fontSize","hAlign","vAlign",
				"aliasName","name","x","y","width","height","scaleX","scaleY","skewX","skewY","pivotX","pivotY","rotation","alpha","color","type","hierarchyID","index");
			return c;
		}
	}
}