package starlingExtensions.animation.recorder {
import flash.errors.IllegalOperationError;
import flash.utils.flash_proxy;

import starlingExtensions.abstract.IDisplayObject;

import starlingExtensions.abstract.IDisplayObjectContainer;

import starlingExtensions.animation.player.Animation;
import starlingExtensions.animation.player.AnimationFrame;
import starlingExtensions.animation.player.AnimationPlayer;
import starlingExtensions.parsers.DisplayListParser;
import starlingExtensions.parsers.model.DisplayObjectProps;

[Event(name="frameAdded", type="flash.events.Event")]
[Event(name="frameRemoved", type="flash.events.Event")]
public class AnimationRecorder extends AnimationPlayer {
    public static const DEBUG_POSITIONS:String = "debugPositions";
    public static const DEBUG_PIVOTS:String = "debugPivots";
    public static const DEBUG_BOUNDS:String = "debugBounds";
    public static const DEBUG_FRAME_OBJECTS:String = "debugFrameObjects";
    public static const DEBUG_FPS:String = "debugFps";
    public static const DEBUG_OPTIONS:Array = [DEBUG_FRAME_OBJECTS, DEBUG_POSITIONS, DEBUG_PIVOTS, DEBUG_BOUNDS, DEBUG_FPS];

    public var recorderModel:AnimationRecorderModel = new AnimationRecorderModel();

    public function AnimationRecorder(obj:IDisplayObjectContainer, _frames:Vector.<AnimationFrame>) {
        super(obj, _frames);
        loop = false;
        fps = 40;
    }

    override public function set currentFrame(value:int):void {
        if (value == mCurrentFrame) return;
        super.currentFrame = value;
    }

    public var _animation:Animation;
    public function set animation(value:Animation):void {
        if (!value || _animation == value) return;

        _animation = value;
        recorderModel.flash_proxy::setProperty("animation", _animation);

        frames = _animation.frames;
        reset();
    }

    public function get animation():Animation {
        return _animation;
    }

    public function get curentAnimationFrame():AnimationFrame {
        return mCurrentFrame < frames.length ? frames[mCurrentFrame] : null;
    }

    public function openMovieClip(value:IDisplayObjectContainer):void {
        if (!value || _movieClip == value) return;

        stop();

        _animationObject = objPropertiesToIgnore = null;
        recorderModel.recordProperties = null;
        recorderModel.flash_proxy::setProperty("animationObject", _animationObject);

        animation = Animation.getAnimation(value);

        _movieClip = _animation.movieClip;
    }

    protected var _animationObject:IDisplayObject;
    public function set animationObject(value:IDisplayObject):void {
        if (!value || _animationObject == value) return;

        pause();

        _animationObject = objPropertiesToIgnore = value as IDisplayObject;
        recorderModel.recordProperties = null;
        recorderModel.flash_proxy::setProperty("animationObject", _animationObject);

        animation = Animation.getParentAnimation(value);

        _movieClip = _animation.movieClip;
    }

    public function get animationObject():IDisplayObject {
        return _animationObject;
    }

    public function toggleRecording():void {
        if (!recorderModel.recordProperties || recorderModel.recordProperties.length == 0) return;

        recorderModel.flash_proxy::setProperty("isRecording", !recorderModel.isRecording);

        pause();

        if (recorderModel.isRecording) {
            objPropertiesToIgnore = _animationObject;
            propertiesToIgnore = recorderModel.recordProperties;
            setupProperFrames();
        }
        else {
            objPropertiesToIgnore = null;
            propertiesToIgnore = null;
        }

        if (DEBUG) trace("AnimationRecorder.toggleRecording()", "isRecording-" + recorderModel.isRecording, "isPlaying-" + isPlaying, frames.length);
    }

    protected function setupProperFrames():void {
        if (frames.length == 0) recordDO(_animationObject, mCurrentFrame + 1);
    }

    public function togglePlaying():void {
        if (isPlaying) pause();
        else {
            setupProperFrames();
            play();
        }
    }

    override public function pause():void {
        super.pause();
        recorderModel.flash_proxy::setProperty("isPlaying", false);
    }

    override public function play():void {
        super.play();
        recorderModel.flash_proxy::setProperty("isPlaying", true);
    }

    override public function stop():void {
        super.stop();
        recorderModel.flash_proxy::setProperty("isPlaying", false);
    }

    override protected function onComplete():void {
        trace("AnimationRecorder.onComplete()", recorderModel.isRecording);

        if (recorderModel.isRecording) {
            recordDO(_animationObject, mCurrentFrame + 1);
            recordDO(_animationObject, mCurrentFrame + 2);
            recordDO(_animationObject, mCurrentFrame + 3);
            return;
        }
        super.onComplete();
    }

    override protected function update(passedTime:Number = -1, newFrame:Boolean = true):void {
        super.update(passedTime, newFrame);

        if (recorderModel.isRecording) recordDO(_animationObject, mCurrentFrame);

        recorderModel.flash_proxy::setProperty("currentFrame", mCurrentFrame);
    }

    override public function advanceTime(passedTime:Number):void {
        if (!mPlaying || passedTime <= 0.0) return;

        super.advanceTime(passedTime);
    }

    public function recordDO(obj:IDisplayObject, frameIndex:int):DisplayObjectProps {
        if (!obj) return null;

        var frame:AnimationFrame = frameIndex < frames.length ? frames[frameIndex] : null;

        if (!frame) {
            frame = new AnimationFrame();
            frame.index = frameIndex;
            addFrame(frame);
        }
        var objIndex:int = obj.getParent() ? obj.getParent().getAChildIndex(obj) : -1;

        var objProps:DisplayObjectProps = DisplayListParser.recordDisplayObjectProperties(obj, frame.getDisplayObjectAt(objIndex));
        frame.addObjectAt(objProps, objIndex);

        if (DEBUG) trace("AnimationRecorder.recordDO(obj, frameIndex, property)", frameIndex, objProps.x, objProps.y);

        return objProps;
    }

    // frame manipulation

    /** Adds an additional frame, optionally with a sound and a custom duration. If the
     *  duration is omitted, the default framerate is used (as specified in the constructor). */
    public function addFrame(frame:AnimationFrame, sound:Object = null, duration:Number = -1):void {
        addFrameAt(numFrames, frame, sound, duration);
    }

    /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
    public function addFrameAt(frameID:int, frame:AnimationFrame, sound:Object = null,
                               duration:Number = -1):void {
        if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
        if (duration < 0) duration = mDefaultFrameDuration;

        frames[frameID] = frame;
        mDurations.splice(frameID, 0, duration);
        mSounds.splice(frameID, 0, sound);

        if (frameID > 0 && frameID == numFrames)
            mStartTimes[frameID] = mStartTimes[int(frameID - 1)] + mDurations[int(frameID - 1)];
        else
            updateStartTimes();

        onFramesUpdated();
    }

    /** Removes the frame at a certain ID. The successors will move down. */
    public function removeFrameAt(frameID:int):void {
        if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
        if (numFrames == 1) throw new IllegalOperationError("Animation recorder must not be empty");

        frames.splice(frameID, 1);
        mDurations.splice(frameID, 1);
        mSounds.splice(frameID, 1);

        updateStartTimes();
        onFramesUpdated();
    }

    public function getFrames():Vector.<AnimationFrame> {
        return frames;
    }

    /*override public function get numFrames():int
     {
     return frames.length+5;
     }*/
    public function clear():void {
        frames.length = 0;
        reset();
        onFramesUpdated();
    }

    protected function onFramesUpdated():void {
        throw new Error("All extensions should implement AnimationRecoreder.onFramesUpdated method;");
    }
}
}