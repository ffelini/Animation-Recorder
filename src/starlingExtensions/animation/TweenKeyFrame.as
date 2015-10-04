package starlingExtensions.animation {
import reflection.interfaces.IPublicAPI;
import reflection.interfaces.IPublicApiHolder;
import reflection.model.AbstractPublicAPI;

import starling.animation.Transitions;
import starling.display.DisplayObjectContainer;

import starlingExtensions.parsers.model.DisplayObjectProps;
import starlingExtensions.parsers.model.TweenProps;
import starlingExtensions.abstract.IDisplayObject;

import utils.ObjUtil;

public class TweenKeyFrame extends TweenExtension implements IPublicApiHolder {
    public static const transitions:Array = [Transitions.LINEAR, Transitions.EASE_IN, Transitions.EASE_OUT, Transitions.EASE_IN_OUT, Transitions.EASE_OUT_IN, Transitions.EASE_IN_BACK, Transitions.EASE_OUT_BACK,
        Transitions.EASE_IN_OUT_BACK, Transitions.EASE_OUT_IN_BACK, Transitions.EASE_IN_ELASTIC, Transitions.EASE_OUT_ELASTIC, Transitions.EASE_IN_OUT_ELASTIC,
        Transitions.EASE_OUT_IN_ELASTIC, Transitions.EASE_IN_BOUNCE, Transitions.EASE_OUT_BOUNCE, Transitions.EASE_IN_OUT_BOUNCE, Transitions.EASE_OUT_IN_BOUNCE];


    public var from:DisplayObjectProps;
    public var to:DisplayObjectProps;
    public var properties:Vector.<Object>;

    public var name:String;

    public function TweenKeyFrame(target:Object, time:Number, transition:Object = "linear") {
        super(target, time, transition);
    }

    public var _publicAPI:AbstractPublicAPI;
    public function get publicAPI():IPublicAPI {
        if (!_publicAPI) {
            _publicAPI = new AbstractPublicAPI(this);
            _publicAPI.addApi("properties", "transition", "name", "totalTime", "delay", "repeatCount", "repeatDelay", "reverse", "roundToInt");
            _publicAPI.addApiValues("transition", Transitions.LINEAR, Transitions.EASE_IN, Transitions.EASE_OUT, Transitions.EASE_IN_OUT, Transitions.EASE_OUT_IN, Transitions.EASE_IN_BACK, Transitions.EASE_OUT_BACK,
                    Transitions.EASE_IN_OUT_BACK, Transitions.EASE_OUT_IN_BACK, Transitions.EASE_IN_ELASTIC, Transitions.EASE_OUT_ELASTIC, Transitions.EASE_IN_OUT_ELASTIC,
                    Transitions.EASE_OUT_IN_ELASTIC, Transitions.EASE_IN_BOUNCE, Transitions.EASE_OUT_BOUNCE, Transitions.EASE_IN_OUT_BOUNCE, Transitions.EASE_OUT_IN_BOUNCE);
            //_publicAPI.addApiValuesList("properties",Animation.getAnimObjProperties(target as DisplayObject));
        }
        return _publicAPI;
    }

    override public function resetProgress():void {
        reset(target, totalTime, transition);

        for each(var prop:String in properties) {
            if (to.hasOwnProperty(prop)) animate(prop, to[prop]);
        }
    }

    public static function getTween(_conf:TweenProps, container:DisplayObjectContainer):TweenKeyFrame {
        var t:TweenKeyFrame = new TweenKeyFrame(container.getChildAt(_conf.targetIndex), _conf.totalTime, _conf.transition);
        t.conf = _conf;
        return t;
    }

    protected var _conf:TweenProps;
    public function set conf(value:TweenProps):void {
        _conf = value;

        ObjUtil.cloneFields(_conf, this, "transition", "name", "delay", "properties", "repeatCount", "repeatDelay", "reverse", "to");
    }

    public function get conf():TweenProps {
        if (!_conf) _conf = new TweenProps();

        _conf.targetIndex = (target as IDisplayObject).getParent().getAChildIndex(target as IDisplayObject);
        ObjUtil.cloneFields(this, _conf, "transition", "totalTime", "name", "delay", "properties", "repeatCount", "repeatDelay", "reverse", "to");

        return _conf;
    }

    public function clone():TweenKeyFrame {
        var c:TweenProps = conf;
        _conf = new TweenProps();

        var t:TweenKeyFrame = new TweenKeyFrame(target, totalTime, transition);
        t.conf = c;
        t.to = to.clone();

        return t;
    }
}
}