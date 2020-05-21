package flixel.addons.display;

#if (openfl >= "8.0.0")

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import openfl.display.Shader;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;

/**
 * An extension of FLxCamera that supports applying a shader to arbitrary sections of the game world.
 * Only available in blit render mode.
 * Does NOT currently support alpha blending; the effect will be applied to all pixels where the mask is not fully
 * transparent. This is due to an open issue with OpenFL masks (https://github.com/openfl/openfl/issues/1086).
 *
 * It extends the base camera display list to following:
 * `flashSprite:Sprite` (which is a container for everything else in the camera, it's added to FlxG.game sprite)
 *     |-> `_scrollRect:Sprite` (which is used for cropping camera's graphic, mostly in tile render mode)
 *         |-> `canvas:Sprite`        (its graphics is used for rendering objects in tile render mode)
 *         |-> `debugLayer:Sprite`    (this sprite is used in tile render mode for rendering debug info, like bounding boxes)
 *     |-> `_shadedScrollRect:Sprite` (the effect shader is applied to this sprite, which holds a copy of the scene and is masked by `maskCanvas`)
 *         |-> `shaderCanvas:Sprite` (everything rendered to `canvas` will simultaneously render to this canvas)
 *         |-> `maskCanvas:Sprite` (all mask objects are rendered to this sprite, which is then used to mask `_shadedScrollRect`)
 */
class FlxShaderMaskCamera extends FlxCamera {

    /**
     * Internal sprite, duplicate of `_scrollRect` to which we apply a shader and mask.
     * It is a child of `flashSprite`.
     * Its position is also modified by the `updateScrollRect()` method.
     */
    var _shadedScrollRect:Sprite;
    
    /**
     * All tile rendering is duplicated to this canvas, so that we have
     * another copy of the scene to which to apply the effect shader.
     * It is a child of `_shadedScrollRect`
     * Its position is modified by `updateInternalSpritePositions()`
     */
    public var shaderCanvas:Sprite;
    /**
     * Only the mask objects are rendered to this sprite,
     * which is both a child of and used as a mask for `_shadedScrollRect`.
     */
    public var maskCanvas:Sprite;
    /**
     * This filter is applied to the area masked by maskCanvas 
     */
    public var shaderFilter:ShaderFilter;

    /**
     *  Collection of objects that will be rendered to the mask buffer rather than the main camera.
    */
    var _maskGroup:FlxGroup;

    public function new(effectShader:Shader, X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0) {
        
        if (FlxG.renderBlit)
        {
            throw "FlxShaderMaskCamera is not supported in blit render mode";
        }

        // Create display objects
        shaderCanvas = new Sprite();
        maskCanvas = new Sprite();
        _shadedScrollRect = new Sprite();
        _shadedScrollRect.mask = maskCanvas;
        // Call super, which will call overriden functions to position our new objects
        super(X, Y, Width, Height, Zoom);
        // Add display objecst to hierarchy
        flashSprite.addChild(_shadedScrollRect);
        _shadedScrollRect.addChild(shaderCanvas);
        _shadedScrollRect.addChild(maskCanvas);
        
        _maskGroup = new FlxGroup();
        
        // apply the provided shader using a ShaderFilter
        shaderFilter = new ShaderFilter(effectShader);
        _shadedScrollRect.filters = [shaderFilter];
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        _maskGroup.update(elapsed);
    }

    override function render():Void
    {
        // clear our duplicate canvas 
        shaderCanvas.graphics.clear();
        super.fill(bgColor.to24Bit(), useBgAlphaBlending, bgColor.alphaFloat, shaderCanvas.graphics);
        // iterate over draw items, but draw them to both canvases
        var currItem:FlxDrawBaseItem<Dynamic> = _headOfDrawStack;
        var oldCanvas:Sprite = this.canvas;
        while (currItem != null)
        {
            // render to main canvas
            currItem.render(this);
            // render to shader canvas
            this.canvas = this.shaderCanvas;
            currItem.render(this);
            // revert canvas
            this.canvas = oldCanvas;
            currItem = currItem.next;
        }
        // reset these to avoid re-drawing all other draw items to the mask canvas
        // this is safe, since draw items are disposed by iterating over _headTiles and _headTriangles
        _currentDrawItem = null;
        _headOfDrawStack = null;
        // populate the draw stack with mask items
        this._maskGroup.draw();
        // render draw stack to mask canvas
        maskCanvas.graphics.clear();
        this.canvas = maskCanvas;
        currItem = _headOfDrawStack;
        while (currItem != null)
        {
            currItem.render(this);
            currItem = currItem.next;
        }
        this.canvas = oldCanvas;
    }
    
    /**
     * Add objects and groups to the mask.
     * The effect shader is applied to the area covered by objects added in this way.
     * The camera will `update()` objects added here, so you probably want to avoid
     * adding them to your scene as well.
     */
    public function addMaskObject(object:FlxBasic) {
        _maskGroup.add(object);
        object.camera = this;
    }
    
    /**
     * Remove objects and groups from the mask.
     */
    public function removeMaskObject(object:FlxBasic) {
        _maskGroup.remove(object);
    }

    // Apply color changes to our duplicate canvas
    override function set_color(Color:FlxColor):FlxColor
    {
        super.set_color(Color);

        var colorTransform = shaderCanvas.transform.colorTransform;
            
        colorTransform.redMultiplier = color.redFloat;
        colorTransform.greenMultiplier = color.greenFloat;
        colorTransform.blueMultiplier = color.blueFloat;
        
        shaderCanvas.transform.colorTransform = colorTransform;
        
        return Color;
    }

    // Apply position/size changes to our duplicate scroll rect
    override function updateScrollRect():Void
    {
        super.updateScrollRect();
        var rect:Rectangle = (_scrollRect != null) ? _scrollRect.scrollRect : null;

        if (rect != null)
        {
            _shadedScrollRect.scrollRect = rect;

            _shadedScrollRect.x = -0.5 * rect.width;
            _shadedScrollRect.y = -0.5 * rect.height;
        }
    }

    // Apply position/size changes to our duplicate and mask canvases
    override function updateInternalSpritePositions():Void
    {
        super.updateInternalSpritePositions();
        for (iCanvas in [shaderCanvas, maskCanvas])
        {
            if (iCanvas != null)
            {
                iCanvas.x = -0.5 * width * (scaleX - initialZoom) * FlxG.scaleMode.scale.x;
                iCanvas.y = -0.5 * height * (scaleY - initialZoom) * FlxG.scaleMode.scale.y;
                
                iCanvas.scaleX = totalScaleX;
                iCanvas.scaleY = totalScaleY;
            }
        }
    }
}

#end // (openfl >= "8.0.0")