package starlingExtensions.parsers {
import starlingExtensions.animation.TweenSequence;
import starlingExtensions.animation.player.Animation;
import starlingExtensions.animation.player.AnimationFrame;
import starlingExtensions.parsers.model.AnimationProps;
import starlingExtensions.parsers.model.DisplayObjectProps;
import starlingExtensions.parsers.model.TweenProps;
import starlingExtensions.parsers.model.TweenSequenceProps;
import starlingExtensions.abstract.IDisplayObjectContainer;

import utils.ObjUtil;

public class AnimationParser {
    public function AnimationParser() {
    }

    public static function addSequenceFrom(obj:Object, movieClip:IDisplayObjectContainer):TweenSequence {
        var conf:TweenSequenceProps = obj as TweenSequenceProps;
        if (!conf) {
            conf = new TweenSequenceProps();
            var tweenProps:TweenProps;

            if (obj is XML) {
                var confXml:XML = obj as XML;
                conf.name = confXml.name;

                var tweens:XMLList = confXml.tweens.children();
                var numChildren:int = tweens.length();
                var tweenXml:XML;
                var nodeName:String;

                for (var i:int = 0; i < numChildren; i++) {
                    tweenXml = tweens[i];
                    nodeName = tweenXml.name();

                    if (nodeName != "fixed" && nodeName != "length") {
                        tweenProps = new TweenProps();
                        tweenProps.properties = new Vector.<Object>();
                        tweenProps.to = new DisplayObjectProps();

                        ObjUtil.cloneFields(tweenXml, tweenProps, "totalTime", "delay", "repeatCount", "repeatDelay", "reverse", "roundToInt", "targetIndex", "transition", "name");
                        ObjUtil.cloneFields(tweenXml.to, tweenProps.to, "aliasName", "name", "x", "y", "width", "height", "scaleX", "scaleY", "skewX", "skewY", "pivotX", "pivotY", "rotation", "alpha", "color", "type", "hierarchyID", "index");

                        for each(var prop:XML in tweenXml.properties.children()) {
                            nodeName = prop.localName();
                            if (nodeName != "fixed" && nodeName != "length") tweenProps.properties.push(prop.toString());
                        }

                        conf.tweens.push(tweenProps);
                    }
                }
            }
            else {
                ObjUtil.cloneFields(obj, conf, "name");

                for each(var tween:Object in obj.tweens as Array) {
                    tweenProps = new TweenProps();
                    tweenProps.properties = new Vector.<Object>();
                    tweenProps.to = new DisplayObjectProps();

                    ObjUtil.cloneFields(tween, tweenProps, "totalTime", "delay", "repeatCount", "repeatDelay", "reverse", "roundToInt", "targetIndex", "transition", "name");
                    ObjUtil.cloneFields(tween.to, tweenProps.to, "aliasName", "name", "x", "y", "width", "height", "scaleX", "scaleY", "skewX", "skewY", "pivotX", "pivotY", "rotation", "alpha", "color", "type", "hierarchyID", "index");

                    tweenProps.properties = Vector.<Object>(tween.properties);

                    conf.tweens.push(tweenProps);
                }
            }
        }
        return TweenSequence.addSequence(conf, movieClip);
    }

    public static function addAnimationFrom(obj:Object, movieClip:IDisplayObjectContainer):Animation {
        var conf:AnimationProps = obj as AnimationProps;
        if (!conf) {
            conf = new AnimationProps();
            var numFarmes:int;

            if (obj is XML) {
                var confXml:XML = obj as XML;
                ObjUtil.cloneFields(confXml, conf, "name", "fps");

                var framesList:XMLList = confXml.frames.children();
                numFarmes = framesList.length();
                var doProps:DisplayObjectProps;
                var doPropsXml;
                var frameXml:XML;
                var frame:AnimationFrame;

                for (var i:int = 0; i < numFarmes; i++) {
                    frameXml = framesList[i];
                    frame = new AnimationFrame(numFarmes, true);
                    ObjUtil.cloneFields(frameXml, frame, "index", "name", "fps");

                    var displayObjectsList:XMLList = frameXml.displayObjects.children();
                    var numObjects:int = displayObjectsList.length();
                    for (var j:int = 0; j < numObjects; j++) {
                        doPropsXml = displayObjectsList[j];

                        if (doPropsXml.localName() != "length" && doPropsXml.localName() != "fixed") {
                            doProps = new DisplayObjectProps();
                            ObjUtil.cloneFields(doPropsXml, doProps, "aliasName", "name", "x", "y", "width", "height", "scaleX", "scaleY", "skewX", "skewY", "pivotX", "pivotY", "rotation", "alpha", "color", "type", "hierarchyID", "index");

                            frame.addObjectAt(doProps, parseInt(doPropsXml.localName()));
                        }
                    }
                    conf.addFrameAt(frame, parseInt(frameXml.localName() + ""));
                }
            }
            else {
                ObjUtil.cloneFields(obj, conf, "index", "name", "fps");

                for each(var fr:Object in obj.frames) {
                    frame = new AnimationFrame();
                    ObjUtil.cloneFields(fr, frame, "index", "name", "fps");

                    for each(var objProps:Object in fr.displayObjects) {
                        doProps = null;

                        if (objProps) {
                            doProps = new DisplayObjectProps();
                            ObjUtil.cloneFields(objProps, doProps, "aliasName", "name", "x", "y", "width", "height", "scaleX", "scaleY", "skewX", "skewY", "pivotX", "pivotY", "rotation", "alpha", "color", "type", "hierarchyID", "index");
                        }

                        frame.displayObjects.push(doProps);
                    }
                    conf.frames.push(frame);
                }
            }
        }
        return Animation.addAnimation(conf, movieClip);
    }
}
}