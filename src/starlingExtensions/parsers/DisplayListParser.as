package starlingExtensions.parsers {

import flash.geom.Rectangle;
import flash.net.registerClassAlias;
import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.MovieClip;
import starling.display.Quad;
import starling.events.EventDispatcher;
import starling.text.TextField;
import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

import starlingExtensions.abstract.IDisplayObject;
import starlingExtensions.abstract.IDisplayObjectContainer;
import starlingExtensions.abstract.IOptimizedDisplayObject;
import starlingExtensions.abstract.IQuad;
import starlingExtensions.abstract.ISmartImage;
import starlingExtensions.abstract.ITextField;
import starlingExtensions.animation.TweenSequence;
import starlingExtensions.animation.player.Animation;
import starlingExtensions.animation.player.AnimationFrame;
import starlingExtensions.parsers.model.AnimationProps;
import starlingExtensions.parsers.model.ColorMatrixProps;
import starlingExtensions.parsers.model.DisplayListProps;
import starlingExtensions.parsers.model.DisplayObjectProps;
import starlingExtensions.parsers.model.FlashDisplayMirrorProps;
import starlingExtensions.parsers.model.ImageProps;
import starlingExtensions.parsers.model.MovieClipProps;
import starlingExtensions.parsers.model.TextProps;
import starlingExtensions.parsers.model.TweenProps;
import starlingExtensions.parsers.model.TweenSequenceProps;

import utils.ClassUtils;
import utils.ObjUtil;

public class DisplayListParser extends EventDispatcher {
    /**
     * used to indicate that animation parsing is required
     */
    public static const PARSE_ANIMATIONS:String = "parseAnimations";
    /**
     * used to indicate that hierarchy parsing is required on an existing object. If object doesn't exist then config is converted in to required object because it may be used for animation.
     */
    public static const PARSE_HIERARCHY:String = "parseHierarchy";
    /**
     * used to indicate that tween sequences parsing is required
     */
    public static const PARSE_TWEENS:String = "parseTweens";

    protected var atlasXmls:Vector.<XML> = new Vector.<XML>();
    protected var textureAtlases:Vector.<TextureAtlas> = new Vector.<TextureAtlas>();
    protected var defaultTextureColor = 0xCCCCCC;

    public function DisplayListParser() {
        super();

        registerClassAlias("starlingExtensions.parsers.model.TweenProps", TweenProps);
        registerClassAlias("starlingExtensions.parsers.model.TweenSequenceProps", TweenSequenceProps);
        registerClassAlias("starlingExtensions.animation.player.AnimationFrame", AnimationFrame);
        registerClassAlias("starlingExtensions.parsers.model.AnimationProps", AnimationProps);
        registerClassAlias("starlingExtensions.parsers.model.ColorMatrixProps", ColorMatrixProps);
        registerClassAlias("starlingExtensions.parsers.model.DisplayListProps", DisplayListProps);
        registerClassAlias("starlingExtensions.parsers.model.DisplayObjectProps", DisplayObjectProps);
        registerClassAlias("starlingExtensions.parsers.model.FlashDisplayMirrorProps", FlashDisplayMirrorProps);
        registerClassAlias("starlingExtensions.parsers.model.ImageProps", ImageProps);
        registerClassAlias("starlingExtensions.parsers.model.MovieClipProps", MovieClipProps);
        registerClassAlias("starlingExtensions.parsers.model.TextProps", TextProps);
    }

    protected static const configsByObject:Dictionary = new Dictionary();

    public function getObjConf(obj:IDisplayObject):DisplayObjectProps {
        if (!obj) return null;

        if (configsByObject[obj]) return configsByObject[obj];

        var conf:DisplayObjectProps = initObjConf(obj);

        configsByObject[obj] = conf;

        return conf;
    }

    public static function initObjConf(obj:IDisplayObject):DisplayObjectProps {
        var props:DisplayObjectProps;

        if (obj is TextField) props = new TextProps();
        else if (obj is IDisplayObjectContainer) props = new DisplayListProps();
        else if (obj is MovieClip) props = new MovieClipProps();
        else if (obj is IQuad) props = new ImageProps();
        else props = new DisplayObjectProps();

        return props;
    }

    public function export(list:IDisplayObjectContainer, conf:DisplayListProps = null, index:int = 0, hierarchyID:String = ""):DisplayListProps {
        if (ignoreExporting(list)) return null;

        if (!conf) conf = getObjConf(list) as DisplayListProps;

        conf = exportCommonConf(list, conf, index) as DisplayListProps;

        conf.animation = Animation.getAnimation(list) ? Animation.getAnimation(list).conf : null;
        conf.tweenSequence = TweenSequence.getSequence(list) ? TweenSequence.getSequence(list).conf : null;
        conf.hierarchyID = hierarchyID;
        conf.children.length = 0;

        var numChildren:int = list.numChildren;
        var child:IDisplayObject;
        var childConf:DisplayObjectProps;

        for (var i:int = 0; i < numChildren; i++) {
            child = list.getAChildAt(i);
            childConf = getObjConf(child);

            if (!ignoreExporting(child)) {
                if (child is IDisplayObjectContainer && !(child is TextField)) {
                    childConf = export(child as IDisplayObjectContainer, childConf as DisplayListProps, i, conf.hierarchyID + "," + i);
                }
                else {
                    childConf = exportCommonConf(child, childConf, i);
                }
            }

            if (childConf) childConf.hierarchyID = conf.hierarchyID + "," + i;

            conf.children.push(childConf);
        }

        return conf;
    }

    protected function ignoreExporting(obj:IDisplayObject):Boolean {
        if (!obj) return true;

        if (obj is IParsingConfigurable) {
            if ((obj as IParsingConfigurable).ignoreExporting) return true;
        }
        return false;
    }

    protected function exportCommonConf(obj:IDisplayObject, conf:DisplayObjectProps, index:int = 0):DisplayObjectProps {
        conf = recordDisplayObjectProperties(obj, conf);
        conf.name = obj.name;
        conf.index = index;
        conf.aliasName = getQualifiedClassName(obj);
        return conf;
    }

    /**
     *
     * @param hierarchyConfig
     * @param hierarchy
     * @param parseStuff an array of what should be considered while parsing [PARSE_ANIMATIONS,PARSE_HIERARCHY]
     * @return
     *
     */
    public function convertToHierarchy(hierarchyConfig:DisplayListProps, hierarchy:IDisplayObjectContainer = null, parseStuff:Array = null):IDisplayObjectContainer {
        var objProps:DisplayObjectProps;

        hierarchy = hierarchy ? hierarchy : convertToDisplayObject(hierarchyConfig) as IDisplayObjectContainer;
        if (!hierarchy) return null;

        var numChildren:int = hierarchyConfig.children.length;
        var child:IDisplayObject;

        var parseAnimations:Boolean = parseStuff ? parseStuff.indexOf(PARSE_ANIMATIONS) >= 0 : true;
        var parseHierarchy:Boolean = parseStuff ? parseStuff.indexOf(PARSE_HIERARCHY) >= 0 : true;
        var parseTweens:Boolean = parseStuff ? parseStuff.indexOf(PARSE_TWEENS) : true;

        var ignoreProperties:Vector.<Object> = new Vector.<Object>();

        for (var i:int = 0; i < numChildren; i++) {
            objProps = hierarchyConfig.children[i];
            child = i < hierarchy.numChildren ? hierarchy.getAChildAt(i) : null;

            ignoreProperties.length = 0;
            if (child is MovieClip || objProps is MovieClipProps) ignoreProperties.push("width", "height", "pivotX", "pivotY", "skewX", "skewY", "scaleX", "scaleY");

            if (!child) {
                if (objProps is DisplayListProps) child = convertToHierarchy(objProps as DisplayListProps, null, parseStuff);
                else child = convertToDisplayObject(objProps);

                if (child) hierarchy.addAChild(child);
            }
            else {
                if (objProps is DisplayListProps) convertToHierarchy(objProps as DisplayListProps, child as IDisplayObjectContainer, parseStuff);
                if (parseHierarchy) {
                    setDisplayObjectProperties(child, objProps, ignoreProperties);
                    ObjUtil.cloneFields(objProps.subclassProps, child);
                }

                if (child is IDisplayObjectContainer && objProps is DisplayListProps) {
                    if (parseAnimations)    Animation.addAnimation((objProps as DisplayListProps).animation, child as IDisplayObjectContainer);
                    if (parseTweens) TweenSequence.addSequence((objProps as DisplayListProps).tweenSequence, child as IDisplayObjectContainer);
                }
            }

            configsByObject[child] = objProps;
        }

        if (parseAnimations) Animation.addAnimation(hierarchyConfig.animation, hierarchy);
        if (parseTweens) TweenSequence.addSequence(hierarchyConfig.tweenSequence, hierarchy);

        return hierarchy;
    }

    protected function convertToDisplayObject(props:DisplayObjectProps):IDisplayObject {
        var childClass:Class = ClassUtils.getClassByName(props.aliasName);
        if (!childClass) return null;

        var resultObj:IDisplayObject;
        var downSubtext:XML;
        var upSubtext:XML;
        var t:Texture;
        var downT:Texture;
        var upT:Texture;
        var subTextureXml:XML;
        var subTexturesXML:Vector.<XML>;

        var imgProps:ImageProps = props as ImageProps;
        var mcProps:MovieClipProps = props as MovieClipProps;
        var txtProps:TextProps = props as TextProps;

        if (imgProps) {
            subTexturesXML = getXmlSubtextures(imgProps.textureName);
            subTextureXml = subTexturesXML ? subTexturesXML[0] : getSubtextureXML(imgProps.textureName);
            var atlas:XML = subTextureXml.parent();
        }

        // checking if subtextures frameLabels matches to an button
        if (subTexturesXML && subTexturesXML.length == 2) {
            downSubtext = subTextureXml.@frameLabel + "" == DisplayObjectProps.BUTTON_KEYFRAME_DOWN ? subTextureXml : (subTexturesXML[1].@frameLabel + "" == DisplayObjectProps.BUTTON_KEYFRAME_DOWN ? subTexturesXML[1] : null);
            upSubtext = subTextureXml.@frameLabel + "" == DisplayObjectProps.BUTTON_KEYFRAME_UP ? subTextureXml : (subTexturesXML[1].@frameLabel + "" == DisplayObjectProps.BUTTON_KEYFRAME_UP ? subTexturesXML[1] : null);
        }

        t = subTextureXml ? getSubtextureByName(subTextureXml.@name + "", subTextureXml.@symbolName + "") : null;
        downT = downSubtext ? getSubtextureByName(downSubtext.@name, downSubtext.@symbolName + "") : null;
        upT = upSubtext ? getSubtextureByName(upSubtext.@name + "", upSubtext.@symbolName + "") : null;

        if ((downT && upT) || ObjUtil.isExtensionOf(childClass, Button)) {
            upT = upT ? upT : t;
            downT = downT ? downT : t;

            resultObj = childClass ? new childClass(upT, "", downT) : new Button(upT, "", downT);
        }
        else if (childClass is MovieClip) {
            var _subtextures:Vector.<Texture> = getSubtextures(subTextureXml.@name + "", subTextureXml.@symbolName + "");
            resultObj = getMovieClip(childClass, atlas, subTextureXml, _subtextures, mcProps);
        }
        else if (childClass is TextField) {
            resultObj = getTextField(childClass, props as TextProps);
            (resultObj as ITextField).autoScale = true;
            (resultObj as ITextField).hAlign = txtProps.hAlign;
            (resultObj as ITextField).vAlign = txtProps.vAlign;
            resultObj.touchable = false;
        }
        else {
            if (imgProps.type == DisplayObjectProps.TYPE_PRIMITIVE) {
                var extrusion:Number = imgProps.textureExtrusion;
                extrusion = !isNaN(extrusion) || extrusion < 100 ? extrusion : 100;
                t = getTextureFromColor(defaultTextureColor, extrusion);
            }
            t = t ? t : getTextureFromColor(defaultTextureColor);

            if (!resultObj) {
                if (imgProps.type == DisplayObjectProps.TYPE_SCALE3_IMAGE) {
                    resultObj = getScale3Image(t, imgProps.scale3TextureDirection);
                }
                else if (imgProps.type == DisplayObjectProps.TYPE_SCALE9_IMAGE) {
                    resultObj = getScale9Image(t);
                }
            }

            if (!resultObj) {
                if (imgProps.type == DisplayObjectProps.TYPE_QUAD) {
                    var _color:uint = imgProps.color;
                    if (isNaN(_color)) _color = defaultTextureColor;
                    resultObj = getQuad(_color);
                }
                else {
                    resultObj = getImage(childClass, t);
                    (resultObj as Image).readjustSize();
                }
            }
        }
        if (!resultObj) return resultObj;

        setDisplayObjectProperties(resultObj, props, null);
        ObjUtil.cloneFields(props.subclassProps, resultObj);

        return resultObj;
    }

    protected function getScale9Image(t:Texture):DisplayObject {
        return new Image(t);
    }

    protected function getScale3Image(t:Texture, direction:String):DisplayObject {
        return new Image(t);
    }

    protected function getMovieClip(clazz:Class, atlas:XML, subTexturesXML:XML,_subtextures:Vector.<Texture>, mcProps:MovieClipProps):MovieClip {
        return clazz ? new clazz(_subtextures, mcProps.fps) : new MovieClip(_subtextures, mcProps.fps);
    }

    protected function getTextField(clazz:Class, txtProps:TextProps):TextField {
        return clazz ? new clazz(txtProps.width, txtProps.height, txtProps.text, txtProps.fontName, txtProps.fontSize, txtProps.color, txtProps.bold) : null;
    }

    protected function getQuad(color:uint):IQuad {
        return new Quad(100, 100, color);
    }

    protected function getImage(clazz:Class, t:Texture):Image {
        clazz = ObjUtil.isExtensionOf(clazz, Image) ? clazz : null;
        return new clazz(t);
    }

    protected function getTextureFromColor(color:uint, extrusion = 100):Texture {
        return Texture.fromColor(2, 2, color, true, 1);
    }

    protected function getSubtextureByName(name:String, symbolName:String):SubTexture {
        var st:SubTexture

        for each(var atlas:TextureAtlas in textureAtlases) {
            st = atlas.getTexture(name) as SubTexture;
        }
        return st;
    }

    protected function getSubtextures(name:String, symbolName:String):Vector.<Texture> {
        var st:Vector.<Texture>;

        var _st:Vector.<Texture>;
        for each(var atlas:TextureAtlas in textureAtlases) {
            _st = atlas.getTextures(symbolName);
            st = st ? st.concat(_st) : _st;
        }

        return st;
    }

    protected function getSubtextureXML(regionName:String):XML {
        var numXmls:int = atlasXmls.length;
        var xmls:XMLList;
        var atlasXml:XML;

        for (var i:int = 0; i < numXmls; i++) {
            atlasXml = atlasXmls[i];
            xmls = atlasXml.children().(@name == regionName);
            if (xmls && xmls.length() > 0) return xmls[0];
        }
        return null;
    }

    protected function getXmlSubtextures(regionName:String):Vector.<XML> {
        var numXmls:int = atlasXmls.length;
        var subtextures:Vector.<XML> = new Vector.<XML>();
        var atlasXml:XML;

        for (var i:int = 0; i < numXmls; i++) {
            atlasXml = atlasXmls[i];
            for each(var subtexture:XML in atlasXml) {
                if (subtexture.@name == regionName) subtextures.push(subtexture);
            }
        }
        return subtextures;
    }

    [Inline]
    public static function recordDisplayObjectProperties(obj:IDisplayObject, props:DisplayObjectProps):DisplayObjectProps {
        if (!props) props = initObjConf(obj);
        if (!props) return props;

        props.x = obj.x;
        props.y = obj.y;
        props.pivotX = obj.pivotX;
        props.pivotY = obj.pivotY;
        props.skewX = obj.skewX;
        props.skewY = obj.skewY;

        props.alpha = obj.alpha;
        props.rotation = obj.rotation;

        props.scaleX = obj.scaleX;
        props.scaleY = obj.scaleY;

        var objBounds:Rectangle = obj.bounds;
        props.width = objBounds.width;
        props.height = objBounds.height;

        if (props is TextProps) {
            var txtProps:TextProps = props as TextProps;
            if (obj is ITextField) {
                var txtField:ITextField = obj as ITextField;

                txtProps.text = txtField.text;
                txtProps.fontName = txtField.fontName;
                txtProps.bold = txtField.bold;
                txtProps.hAlign = txtField.hAlign;
                txtProps.vAlign = txtField.vAlign;
                if (!isNaN(txtField.color)) txtProps.color = txtField.color;
                if (!isNaN(txtField.fontSize)) txtProps.fontSize = txtField.fontSize;
            }
        }
        else if (props is ImageProps) {
            var imgProps:ImageProps = props as ImageProps;
            if (!isNaN((obj as IQuad).color)) imgProps.color = (obj as IQuad).color;

            if (obj is ISmartImage) {
                var smartImg:ISmartImage = obj as ISmartImage;
                if (!isNaN(smartImg.topColor)) imgProps.topColor = smartImg.topColor;
                if (!isNaN(smartImg.bottomColor)) imgProps.bottomColor = smartImg.bottomColor;
                if (!isNaN(smartImg.leftColor)) imgProps.leftColor = smartImg.leftColor;
                if (!isNaN(smartImg.rightColor)) imgProps.rightColor = smartImg.rightColor;
            }
        }
        else if (props is MovieClipProps && obj is MovieClip) {
            var mcProps:MovieClipProps = props as MovieClipProps;
            var mc:MovieClip = obj as MovieClip;

            mcProps.fps = mc.fps;
            mcProps.currentFrame = mc.currentFrame;
        }

        return props;
    }

    protected static var helpArray:Array = [];

    [Inline]
    public static function setDisplayObjectProperties(obj:IDisplayObject, props:DisplayObjectProps, ignoreProperties:Vector.<Object>):void {
        if (!obj || !props) return;

        for each(var p:String in ignoreProperties) {
            helpArray[p] = obj[p];
        }

        if (!isNaN(props.x)) obj.x = props.x;
        if (!isNaN(props.y)) obj.y = props.y;
        if (!isNaN(props.pivotX)) obj.pivotX = props.pivotX;
        if (!isNaN(props.pivotY)) obj.pivotY = props.pivotY;
        if (!isNaN(props.skewX)) obj.skewX = props.skewX;
        if (!isNaN(props.skewY)) obj.skewY = props.skewY;
        if (!isNaN(props.alpha)) obj.alpha = props.alpha;
        if (!isNaN(props.rotation)) obj.rotation = props.rotation;

        if (!isNaN(props.scaleX)) obj.scaleX = props.scaleX;
        if (!isNaN(props.scaleY)) obj.scaleY = props.scaleY;

        if (props is ImageProps) {
            var imgProps:ImageProps = props as ImageProps;
            if (!isNaN(imgProps.color)) if (obj is IQuad) (obj as IQuad).color = imgProps.color;

            if (obj is ISmartImage) {
                var smartImg:ISmartImage = obj as ISmartImage;
                if (!isNaN(imgProps.topColor)) smartImg.topColor = imgProps.topColor;
                if (!isNaN(imgProps.bottomColor)) smartImg.bottomColor = imgProps.bottomColor;
                if (!isNaN(imgProps.leftColor)) smartImg.leftColor = imgProps.leftColor;
                if (!isNaN(imgProps.rightColor)) smartImg.rightColor = imgProps.rightColor;
            }
        }
        if (props is MovieClipProps && obj is MovieClip) {
            var mcProps:MovieClipProps = props as MovieClipProps;
            var mc:MovieClip = obj as MovieClip;

            if (!isNaN(mcProps.fps)) mc.fps = mcProps.fps;
            if (!isNaN(mcProps.currentFrame)) mc.currentFrame = mcProps.currentFrame;
        }

        if (obj is IOptimizedDisplayObject) {
            (obj as IOptimizedDisplayObject).setSize(!isNaN(props.width) ? props.width : obj["width"], !isNaN(props.height) ? props.height : obj["height"]);
        }
        else {
            if (!isNaN(props.width)) obj.width = props.width;
            if (!isNaN(props.height)) obj.height = props.height;
        }

        for each(p in ignoreProperties) {
            obj[p] = helpArray[p];
        }
    }
}
}