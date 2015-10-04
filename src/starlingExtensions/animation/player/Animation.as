package starlingExtensions.animation.player {
import flash.utils.Dictionary;

import starlingExtensions.abstract.IDisplayObject;

import starlingExtensions.abstract.IDisplayObjectContainer;

import starlingExtensions.parsers.model.AnimationProps;

public class Animation {
    public var movieClip:IDisplayObjectContainer;

    public var name:String;
    public var frames:Vector.<AnimationFrame> = new Vector.<AnimationFrame>();

    public static const animations:Vector.<Animation> = new <Animation>[];

    public function Animation(_movieClip:IDisplayObjectContainer) {
        movieClip = _movieClip;

        animations.push(this);
    }

    protected var _conf:AnimationProps;
    public function get conf():AnimationProps {
        if (!_conf) _conf = new AnimationProps();

        _conf.name = name;
        _conf.fps = animationPlayer.fps;
        _conf.frames = frames;

        return _conf;
    }

    public function set conf(value:AnimationProps):void {
        if (!value) return;

        _conf = value;
        name = _conf.name;
        frames = _conf.frames ? _conf.frames : frames;
    }

    protected var _animationPlayer:AnimationPlayer;
    public function get animationPlayer():AnimationPlayer {
        if (_animationPlayer) return _animationPlayer;

        _animationPlayer = new AnimationPlayer(movieClip, frames, _conf ? _conf.fps : 24);

        return _animationPlayer;
    }

    private static const animationsByKey:Dictionary = new Dictionary();

    public static function addAnimation(conf:AnimationProps, movieClip:IDisplayObjectContainer):Animation {
        if (!conf || !movieClip) return null;

        var animation:Animation = new Animation(movieClip);
        animation.conf = conf;
        animationsByKey[movieClip] = animation;
        return animation;
    }

    public static function getParentAnimation(obj:IDisplayObject):Animation {
        var container:IDisplayObjectContainer = obj ? obj.getParent() : null;
        if (container) {
            var animation:Animation = animationsByKey[container];
            if (animation) return animation;

            animation = new Animation(container);
            animationsByKey[container] = animation;
        }
        return animation;
    }

    public static function getAnimation(movieClip:IDisplayObjectContainer):Animation {
        return animationsByKey[movieClip];
    }

    public function toString():String {
        return name + " - " + frames.length + " frames";
    }
}
}