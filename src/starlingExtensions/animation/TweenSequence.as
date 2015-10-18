package starlingExtensions.animation {
import flash.utils.Dictionary;

import managers.Handlers;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;

import starlingExtensions.interfaces.IJugglerAnimator;
import starlingExtensions.parsers.model.TweenProps;
import starlingExtensions.parsers.model.TweenSequenceProps;
import starlingExtensions.abstract.IDisplayObjectContainer;
import starlingExtensions.abstract.IDisplayObject;

import utils.Range;
import utils.TimeOut;
import utils.Utils;

/**
 * A sequence of Tween instances played in a the order you push them.
 * IMPORTANT !!!!!!
 * Do not set Tween.onComplete listener for pushed tweens because it is used internally by this class.
 * Use TweenSequence.EVENT_TWEEN_COMPLETE event instead
 */
public dynamic class TweenSequence extends Array {
    public var name:String = "";

    protected var juggler:Juggler;

    public function TweenSequence(_juggler:Juggler = null) {
        length = 0;

        juggler = _juggler ? _juggler : Starling.current.juggler;

        super();
    }

    protected var _conf:TweenSequenceProps;

    public function setConf(value:TweenSequenceProps, obj:IDisplayObjectContainer):void {
        _conf = value;
        name = _conf.name;

        length = 0;

        if (_conf.tweens && _conf.tweens.length > 0) {
            var t:TweenKeyFrame;
            var target:IDisplayObject;
            var movieClipNumChildren:int = obj ? obj.numChildren : 0;

            for each(var tweenProp:TweenProps in _conf.tweens) {
                target = tweenProp.targetIndex < movieClipNumChildren ? obj.getAChildAt(tweenProp.targetIndex) : null;
                t = new TweenKeyFrame(target, tweenProp.totalTime, tweenProp.transition);
                t.conf = tweenProp;

                push(t);
            }
        }
    }

    public function get conf():TweenSequenceProps {
        if (!_conf) _conf = new TweenSequenceProps();
        _conf.name = name;
        _conf.tweens.length = 0;

        for each(var tween:TweenKeyFrame in this) {
            _conf.tweens.push(tween.conf);
        }

        return _conf;
    }

    /**
     *
     * @return container that holds this tween sequence (his children are used as targets for sequence tweens)
     *
     */
    public function get owner():IDisplayObjectContainer {
        return tweenSequencesByKey[this] as IDisplayObjectContainer;
    }

    private static const tweenSequencesByKey:Dictionary = new Dictionary();

    public static function addSequence(conf:TweenSequenceProps, obj:IDisplayObjectContainer):TweenSequence {
        if (!conf || !obj) return null;

        var sequence:TweenSequence = new TweenSequence(obj is IJugglerAnimator ? (obj as IJugglerAnimator).juggler : null);
        tweenSequencesByKey[obj] = sequence;
        tweenSequencesByKey[sequence] = obj;

        sequence.setConf(conf, obj);
        return sequence;
    }

    public static function getParentSequence(obj:IDisplayObject):TweenSequence {
        var container:IDisplayObjectContainer = obj ? obj.getParent() : null;
        if (container) {
            var animation:TweenSequence = tweenSequencesByKey[container];
            if (animation) return animation;

            animation = new TweenSequence();
            tweenSequencesByKey[container] = animation;
        }
        return animation;
    }

    public static function getSequence(movieClip:IDisplayObjectContainer):TweenSequence {
        return tweenSequencesByKey[movieClip];
    }

    public function goToAndPlay(tweenIndex:int, reversible:Boolean = false, loop:Boolean = false):void {
        _tweenIndex = tweenIndex;
        Handlers.call(EVENT_SEQUENCE_START);
        play(reversible, loop);
    }

    protected var _tweenIndex:int = 0;
    public function set tweenIndex(value:int):void {
        _tweenIndex = value;
    }

    public function get tweenIndex():int {
        return _tweenIndex;
    }

    public var loopDelayRandomRange:Range;
    protected var _loop:Boolean = false;
    public function get loop():Boolean {
        return _loop;
    }

    public function set loop(value:Boolean):void {
        _loop = value;
    }

    protected var _playReversible:Boolean = false;

    protected var _curentTween:TweenExtension;
    public function get curentTween():TweenExtension {
        return _curentTween;
    }

    public function play(reversible:Boolean = false, loop:Boolean = false):void {
        _playReversible = reversible;
        _loop = loop;

        _curentTween = this[_tweenIndex];
        if (_curentTween) {
            _curentTween.resetProgress();
            _curentTween.onComplete = onTweenComplete;
            _curentTween.onCompleteArgs = [_curentTween];
            _curentTween.onUpdate = onTweenUpdate;
            _curentTween.onUpdateArgs = [_curentTween];
            juggler.add(_curentTween);

            Handlers.call(EVENT_TWEEN_START);
            Handlers.call(EVENT_TWEEN_CHANGED);
        }
    }

    public var EVENT_TWEEN_START:Object = {};
    public var EVENT_TWEEN_STOP:Object = {};
    public var EVENT_TWEEN_COMPLETE:Object = {};
    public var EVENT_TWEEN_PAUSE:Object = {};
    public var EVENT_TWEEN_UPDATE:Object = {};
    public var EVENT_TWEEN_CHANGED:Object = {};

    private function onTweenUpdate(tween:TweenExtension):void {
        Handlers.call(EVENT_TWEEN_UPDATE);
    }

    public function pause():void {
        if (_curentTween) _curentTween.pause();
        Handlers.call(EVENT_TWEEN_PAUSE);
    }

    public function get isPlaying():Boolean {
        return _curentTween && _curentTween.playing;
    }

    public function togglePlaying():void {
        if (isPlaying) pause();
        else play();
    }

    public function stop():void {
        _tweenIndex = 0;
        if (_curentTween) {
            juggler.remove(_curentTween);
            _curentTween = null;
        }
        TimeOut.clearTimeOuts(play);
        Handlers.call(EVENT_TWEEN_STOP);
    }

    protected function onTweenComplete(tween:TweenExtension):void {
        _tweenIndex = indexOf(tween);

        juggler.remove(tween);

        Handlers.call(EVENT_TWEEN_COMPLETE);
        Handlers.call(tween);

        if (_tweenIndex + 1 < this.length) {
            _tweenIndex++;
            play(_playReversible, _loop);
        }
        else {
            _tweenIndex = 0;
            _curentTween = null;
            onSequenceComplete();

            if (_loop) {
                if (loopDelayRandomRange) TimeOut.setTimeOutFunc(play, Utils.randRange(loopDelayRandomRange.from, loopDelayRandomRange.to), true, _playReversible, _loop);
                else play(_playReversible, _loop);
            }
        }
    }

    public var EVENT_SEQUENCE_START:Object = {};
    public var EVENT_SEQUENCE_COMPLETE:Object = {};
    public var sequenceCompleteHandler:Function;

    protected function onSequenceComplete():void {
        Handlers.functionCall(sequenceCompleteHandler);
        Handlers.call(EVENT_SEQUENCE_COMPLETE);
    }

    public function set totalTime(value:Number):void {
        var _totalTime:Number = this.totalTime;
        var factor:Number = value / _totalTime;

        for each(var t:TweenExtension in this) {
            t.totalTime *= factor;
        }
    }

    public function get totalTime():Number {
        var time:Number = 0;
        for each(var t:TweenExtension in this) {
            time += t.totalTime;
        }
        return time;
    }

    public function getTweenTime(tween:Tween):Number {
        var tweenIndex:int = indexOf(tween);
        var time:Number;

        if (tweenIndex >= 0) {
            for (var i:int = 0; i < tweenIndex; i++) {
                time += (this[i] as Tween).totalTime;
            }
        }
        return time;
    }
}
}