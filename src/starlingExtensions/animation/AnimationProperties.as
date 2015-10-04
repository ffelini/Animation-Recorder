/**
 * Created by valera on 29.09.2015.
 */
package starlingExtensions.animation {
import flash.display.MovieClip;

import starlingExtensions.abstract.IDisplayObject;
import starlingExtensions.abstract.IPlayerMovieClip;
import starlingExtensions.abstract.IQuad;
import starlingExtensions.abstract.ISmartImage;

public class AnimationProperties {

    public static function getAnimObjProperties(animationObject:IDisplayObject, _animObjProperties:Array = null):Array {
        if (!animationObject) return null;

        if (!_animObjProperties) _animObjProperties = new Array();
        _animObjProperties.length = 0;

        if (animationObject is IPlayerMovieClip) {
            _animObjProperties.push("currentFrame", "fps");
        }
        if (animationObject is IQuad) {
            _animObjProperties.push("color");
        }
        if (animationObject is ISmartImage) {
            _animObjProperties.push("topColor", "bottomColor", "leftColor", "rightColor", "topAlpha", "bottomAlpha", "leftAlpha", "rightAlpha");
        }
        _animObjProperties.push("x", "y", "width", "height", "scaleX", "scaleY", "rotation", "alpha", "pivotX", "pivotY", "skewX", "skewY");

        return _animObjProperties;
    }
}
}
