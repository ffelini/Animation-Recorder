package starlingExtensions.animation.player {
import starlingExtensions.parsers.model.DisplayObjectProps;

[RemoteClass(alias="starlingExtensions.animation.player.AnimationFrame")]
public class AnimationFrame {
    public var index:int;
    public var name:String;
    public var fps:Number;

    public var displayObjects:Vector.<DisplayObjectProps>;

    public function AnimationFrame(numObjects:int = -1, fixedLength:Boolean = false) {
        if (numObjects > 0) displayObjects = new Vector.<DisplayObjectProps>(numObjects, fixedLength);
        else displayObjects = new Vector.<DisplayObjectProps>();
    }

    public function addObjectAt(obj:DisplayObjectProps, index:int):void {
        var numObjects:int = displayObjects.length;

        if (index >= numObjects) {
            for (var i:int = 0; i < index - numObjects; i++) {
                displayObjects.push(null);
            }
        }
        displayObjects[index] = obj;
    }

    public function getDisplayObjectAt(index:int):DisplayObjectProps {
        return index < displayObjects.length ? displayObjects[index] : null;
    }

    public function clone():AnimationFrame {
        var f:AnimationFrame = new AnimationFrame();

        for each(var objProp:DisplayObjectProps in displayObjects) {
            f.displayObjects.push(objProp.clone());
        }
        return f;
    }

    public function toString():String {
        return "Name - " + name + " Index - " + index + " Num. objects - " + displayObjects.length;
    }
}
}