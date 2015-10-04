package starlingExtensions.animation.player {

import flash.events.Event;
import flash.events.EventDispatcher;

import starlingExtensions.abstract.IDisplayObject;
import starlingExtensions.abstract.IDisplayObjectContainer;
import starlingExtensions.parsers.DisplayListParser;
import starlingExtensions.parsers.model.DisplayObjectProps;

public class AnimationPlayer extends EventDispatcher {
    public static var DEBUG:Boolean = true;

    private static const PLAY_MODE_NORMAL:String = "normal";
    private static const PLAY_MODE_RANGE:String = "range";

    private var _frames:Vector.<AnimationFrame> = new Vector.<AnimationFrame>();

    protected var _movieClip:IDisplayObjectContainer;

    public function AnimationPlayer(obj:IDisplayObjectContainer, _frames:Vector.<AnimationFrame>, _fps:Number = 24) {
        if (obj) {
            _movieClip = obj
            this._frames = _frames;
        }

        reset(_fps);
    }

    public function playFrames(_frames:Vector.<AnimationFrame>, _fps:Number = -1):void {
        this._frames = _frames;

        reset(_fps);

        play();
    }

    public function reset(fps:Number = 24):void {
        var _numFrames:int = numFrames;

        mDefaultFrameDuration = 1.0 / fps;
        mLoop = true;
        mPlaying = false;
        mCurrentTime = 0.0;
        mCurrentFrame = 0;
        mDurations = new Vector.<Number>(_numFrames);
        mStartTimes = new Vector.<Number>(_numFrames);
        mSounds = new Vector.<Object>(numFrames);

        for (var i:int = 0; i < _numFrames; ++i) {
            mDurations[i] = mDefaultFrameDuration;
            mStartTimes[i] = i * mDefaultFrameDuration;
        }
    }

    protected var mDurations:Vector.<Number>;
    protected var mStartTimes:Vector.<Number>;
    protected var mSounds:Vector.<Object>;

    protected var mDefaultFrameDuration:Number;
    protected var mCurrentTime:Number;
    protected var mCurrentFrame:int;
    protected var mLoop:Boolean;
    protected var mPlaying:Boolean;

    protected function updateStartTimes():void {
        var numFrames:int = this.numFrames;

        mStartTimes.length = 0;
        mStartTimes[0] = 0;

        for (var i:int = 1; i < numFrames; ++i)
            mStartTimes[i] = mStartTimes[int(i - 1)] + mDurations[int(i - 1)];
    }

    public function play():void {
        reversePlaying = false;
        paused = false;
        mPlaying = true;
    }

    public function gotoAndPlay(frame:*):void {
        currentFrame = filterFrame(frame);
        play();
    }

    public function playReversible():void {
        play();
        reversePlaying = true;
    }

    // play mode
    protected var _playMode:String;
    public function set playMode(value:String):void {
        _playMode = value;
    }

    public function get playMode():String {
        return _playMode;
    }

    public function resetPlayMode():void {
        playMode = PLAY_MODE_NORMAL;
    }

    protected var playRange:Range;

    public function playBetween(startFrame:int, endFrame:int, loop:Boolean = true):void {
        if (startFrame > endFrame || startFrame == endFrame || startFrame < 0 || startFrame > numFrames - 1 || endFrame < 0 || endFrame > numFrames - 1) return;

        if (!playRange) playRange = new Range(-1, -1, false);
        currentFrame = startFrame;
        playRange.from = startFrame;
        playRange.to = endFrame;

        this.loop = loop;
        playMode = PLAY_MODE_RANGE;
        if (!isPlaying) play();
    }

    private var _playTill:int = -1;

    public function playTill(frame:*):void {
        _playTill = filterFrame(frame);
        play();
    }

    public function playWithDelay(delay:Number):void {
        if (delay > 0) TimeOut.setTimeOutFunc(play, delay);
        else play();
    }

    public function next(step:int = 1):void {
        currentFrame = filterFrame(currentFrame + step);
    }

    private function filterFrame(value:int):int {
        if (value >= numFrames) return 0;
        if (value < 0) return numFrames - 1;
        return value;
    }

    public function gotoAndStop(frame:*):void {
        stop();
        currentFrame = filterFrame(frame);

    }

    public var hideOnStop:Boolean = true;

    public function stop():void {
        TimeOut.clearTimeOuts(play);

        currentFrame = 0;
        paused = false;
    }

    public var paused:Boolean = false;

    public function pause():void {
        paused = true;
        mPlaying = false;
        TimeOut.clearTimeOuts(play);
    }

    public function resume():void {
        if (!mPlaying && paused) play();
    }

    protected var objPropertiesToIgnore:IDisplayObject;
    protected var propertiesToIgnore:Vector.<Object>;

    protected function update(passedTime:Number = -1, newFrame:Boolean = true):void {
        var frame:AnimationFrame = _frames[mCurrentFrame];

        if (DEBUG) trace("AnimationPlayer.update(passedTime, newFrame)", mCurrentFrame + "/" + numFrames, frame);

        if (!frame) return;

        //if(!isNaN(frame.fps)) fps = frame.fps;

        var _numChildren:int = frame.displayObjects.length;
        var obj:IDisplayObject;
        var objProps:DisplayObjectProps;
        var movieClipChildren:int = _movieClip.numChildren;

        for (var i:int = 0; i < _numChildren; i++) {
            objProps = frame.displayObjects[i];

            obj = i < movieClipChildren ? _movieClip.getAChildAt(i) : null;

            if (obj && objProps) DisplayListParser.setDisplayObjectProperties(obj, objProps, obj == objPropertiesToIgnore ? propertiesToIgnore : null);
        }
    }

    public function getTotalTimeAt(frame:int):int {
        if (frame < 0 || frame > numFrames - 1) return 0;

        return mStartTimes[frame] + mDurations[frame]
    }

    private var reversePlaying:Boolean = false;

    public function advanceTime(passedTime:Number):void {
        if (!mPlaying || passedTime <= 0.0) return;

        var finalFrame:int;
        var previousFrame:int = mCurrentFrame;
        var restTime:Number = 0.0;
        var breakAfterFrame:Boolean = false;
        var hasCompleteListener:Boolean = hasEventListener(Event.COMPLETE);
        var dispatchCompleteEvent:Boolean = false;
        var totalTime:Number = this.totalTime;

        if (reversePlaying) {
            if (playMode == PLAY_MODE_RANGE) passedTime = totalTime - getTotalTimeAt(playRange.to) - passedTime;
            else passedTime = totalTime - passedTime;
        }

        if (mLoop && mCurrentTime >= totalTime) {
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
        }

        if (mCurrentTime < totalTime) {
            mCurrentTime += passedTime;
            finalFrame = numFrames - 1;

            while (mCurrentTime > mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame]) {
                if (mCurrentFrame == finalFrame) {
                    if (mLoop && !hasCompleteListener) {
                        mCurrentTime -= totalTime;
                        mCurrentFrame = 0;
                    }
                    else {
                        breakAfterFrame = true;
                        restTime = mCurrentTime - totalTime;
                        dispatchCompleteEvent = hasCompleteListener;
                        mCurrentFrame = finalFrame;
                        mCurrentTime = totalTime;
                    }
                }
                else {
                    mCurrentFrame++;
                }

                var sound:Object = mSounds[mCurrentFrame];
                if (sound) playSound(sound);
                if (breakAfterFrame) break;

                if (breakAfterFrame) break;
            }

            // special case when we reach *exactly* the total time.
            if (mCurrentFrame == finalFrame && mCurrentTime == totalTime)
                dispatchCompleteEvent = hasCompleteListener;
        }

        if (dispatchCompleteEvent)
            dispatchEvent(new Event(Event.COMPLETE));

        if (mLoop && restTime > 0.0)
            advanceTime(restTime);

        update(passedTime, mCurrentFrame != previousFrame);

        //playTill
        if (mCurrentFrame == _playTill) {
            pause();
            _playTill = -1;
            return;
        }

        //playMode
        if (_playMode == PLAY_MODE_RANGE) _complete = mCurrentFrame == playRange.to || (reversePlaying && mCurrentFrame == 0);
        else _complete = mCurrentFrame == numFrames - 1 || (reversePlaying && mCurrentFrame == 0);

        if (_complete) onComplete();

    }

    public var zigzagPlayMode:Boolean = false;
    public var randomRepeatDelay:Boolean = true;
    public var repeatDelayRandomRange:Number = 3000;
    public var repeatDelay:Number = 0;
    public var randomLooping:Boolean = false;

    private var _complete:Boolean
    public var stopToFirstFrameOnComplete:Boolean = false;

    protected function onComplete():void {
        reversePlaying = zigzagPlayMode ? !reversePlaying : false;

        if (!reversePlaying || !zigzagPlayMode) {
            onLoopComplete();

            if (stopToFirstFrameOnComplete) stop();
            else {
                pause();

                if (mLoop) {
                    repeatDelay = randomRepeatDelay ? randRange(repeatDelayRandomRange / 4, repeatDelayRandomRange) : repeatDelay;

                    if (randomLooping) randomizeCurentFrame();
                    playWithDelay(reversePlaying ? 0 : repeatDelay);
                }
            }
        }
    }

    private function randomizeCurentFrame():void {
        currentFrame = randRange(0, numFrames - 1);
    }

    /** Indicates if the clip is still playing. Returns <code>false</code> when the end
     *  is reached. */
    public function get isPlaying():Boolean {
        if (mPlaying)
            return mLoop || mCurrentTime < totalTime;
        else
            return false;
    }

    /** Indicates if a (non-looping) movie has come to its end. */
    public function get isComplete():Boolean {
        return !mLoop && mCurrentTime >= totalTime;
    }

    // properties

    /** The total duration of the clip in seconds. */
    public function get totalTime():Number {
        var _numFrames:int = numFrames;
        if (_numFrames == 0) return 0;
        return mStartTimes[int(_numFrames - 1)] + mDurations[int(_numFrames - 1)];
    }

    /** The time that has passed since the clip was started (each loop starts at zero). */
    public function get currentTime():Number {
        return mCurrentTime;
    }

    /** The total number of frames. */
    public function get numFrames():int {
        return _frames.length;
    }

    /** Indicates if the clip should loop. */
    public function get loop():Boolean {
        return mLoop;
    }

    public function set loop(value:Boolean):void {
        mLoop = value;
    }

    public function get frames():Vector.<AnimationFrame> {
        return _frames;
    }

    public function set frames(value:Vector.<AnimationFrame>):void {
        if(value) {
            this._frames = value;
        }
    }

    /** The index of the frame that is currently displayed. */
    public function get currentFrame():int {
        return mCurrentFrame;
    }

    public function set currentFrame(value:int):void {
        mCurrentFrame = value;
        mCurrentTime = 0.0;

        for (var i:int = 0; i < value; ++i)
            mCurrentTime += getFrameDuration(i);

        if (mSounds[mCurrentFrame]) playSound(mSounds[mCurrentFrame]);
        update();
    }

    /** Returns the sound of a certain frame. */
    public function getFrameSound(frameID:int):Object {
        if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
        return mSounds[frameID];
    }

    /** Returns the duration of a certain frame (in seconds). */
    public function getFrameDuration(frameID:int):Number {
        if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
        return mDurations[frameID];
    }

    /** The default number of frames per second. Individual frames can have different
     *  durations. If you change the fps, the durations of all frames will be scaled
     *  relatively to the previous value. */
    public function get fps():Number {
        return 1.0 / mDefaultFrameDuration;
    }

    public function set fps(value:Number):void {
        if (value <= 0) throw new ArgumentError("Invalid fps: " + value);

        var newFrameDuration:Number = 1.0 / value;
        var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
        mCurrentTime *= acceleration;
        mDefaultFrameDuration = newFrameDuration;

        for (var i:int = 0; i < numFrames; ++i) {
            var duration:Number = mDurations[i] * acceleration;
            mDurations[i] = duration;
        }

        updateStartTimes();
    }

    public static function randRange(minNum:Number, maxNum:Number, offset:Number = 1):Number {
        return (Math.floor(Math.random() * (maxNum - minNum + offset)) + minNum);
    }

    public function playSound(s:Object):void {
        throw new Error("Any extension on AnimationPlayer class should implement playSound method");
    }

    protected function onLoopComplete() {

    }
}
}

import flash.utils.Dictionary;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

class TimeOut
{
    public function TimeOut()
    {
    }

    private static var timeOuts:Dictionary = new Dictionary();

    public static function setTimeOutFunc(func:Function,delay:Number,clearAllTimeOuts:Boolean=true,...parameters):void
    {
        var tuid:uint = setTimeout.apply(null,[func,delay].concat(parameters));

        if(clearAllTimeOuts) clearTimeOuts(func);

        var _timeOuts:Vector.<uint> = timeOuts[func];
        if(!_timeOuts)
        {
            _timeOuts = new Vector.<uint>();
            timeOuts[func] = _timeOuts;
        }
        _timeOuts.push(tuid);
    }
    public static function clearTimeOuts(func:Function):void
    {
        var _timeOuts:Vector.<uint> = timeOuts[func];
        if(!_timeOuts) return;

        for each(var tuid:uint in _timeOuts)
        {
            clearTimeout(tuid);
        }
        _timeOuts.length = 0;
    }
    public static function getTimeouts(func:Function):Vector.<uint>
    {
        var _timeOuts:Vector.<uint> = timeOuts[func];
        return _timeOuts;
    }
    public static function haveTimeouts(func:Function):Boolean
    {
        var _timeOuts:Vector.<uint> = timeOuts[func];
        return _timeOuts ? _timeOuts.length>0 : false;
    }
}

dynamic class Range extends Array
{
    public var from:int;
    public var to:int;

    public function Range(from:int,to:int,_fillMassive:Boolean=true)
    {
        super();
        update(from,to,_fillMassive);
    }
    public static function fromString(value:String):Range
    {
        var from:int = parseInt(value.split("..")[0]);
        var to:int = parseInt(value.split("..")[1]);

        return new Range(from,to);
    }
    public function update(from:int,to:int,_fillMassive:Boolean=true):void
    {
        this.from = from;
        this.to = to;
        length = 0;

        if(_fillMassive) fillMassive(this as Array,from,to);
    }
    public static function fillMassive(massive:Array,from:int,to:int):Array
    {
        if(!massive) massive = [];

        for (var i:int=from;i<to;i++)
        {
            massive.push(i);
        }
        return massive;
    }
    public function getRandomValue():int
    {
        return (Math.floor(Math.random() * (to - from + 1)) + from);
    }
    public function toString():String
    {
        return from+".."+to;
    }
}