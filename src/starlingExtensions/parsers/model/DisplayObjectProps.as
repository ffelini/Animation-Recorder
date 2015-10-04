package starlingExtensions.parsers.model {
import utils.ObjUtil;

[RemoteClass(alias="starlingExtensions.parsers.model.DisplayObjectProps")]
public class DisplayObjectProps {
    static public var BUTTON_KEYFRAME_DOWN:String;

    static public var BUTTON_KEYFRAME_UP:String;
    static public var TYPE_POP_UP_LAYER:String;
    static public var TYPE_BTN:String;
    static public var TYPE_PRIMITIVE:String;
    static public var TYPE_QUAD:String;

    static public var TYPE_FLASH_MOVIE_CLIP:String;
    static public var TYPE_FLASH_LABEL_BUTTON:String;
    static public var TYPE_SCALE3_IMAGE:String;
    static public var TYPE_SCALE9_IMAGE:String;
    static public var FIELD_HIERARCHY:String;

    static public var FIELD_QUALITY:String;
    static public var FIELD_DEFAULT_SCALEX:String;
    static public var FIELD_DEFAULT_SCALEY:String;
    static public var FIELD_MOVIECLIP_SIMMILAR_FRAMES:String;

    public var aliasName:String = "";

    public var name:String = "";

    public var x:Number;
    public var y:Number;

    public var width:Number;
    public var height:Number;

    public var scaleX:Number;
    public var scaleY:Number;

    public var skewX:Number;
    public var skewY:Number;

    public var pivotX:Number;
    public var pivotY:Number;

    public var rotation:Number;
    public var alpha:Number;

    public var color:uint = 0xFFFFFF;

    public var type:String = "";

    public var hierarchyID:String = "";
    public var index:int;

    public var subclassProps:Object;

    public function DisplayObjectProps() {
    }

    public function clone():DisplayObjectProps {
        var c:DisplayObjectProps = new DisplayObjectProps();
        ObjUtil.cloneFields(this, c, "aliasName", "name", "x", "y", "width", "height", "scaleX", "scaleY", "skewX", "skewY", "pivotX", "pivotY", "rotation", "alpha", "color", "type", "hierarchyID", "index");
        return c;
    }
}
}