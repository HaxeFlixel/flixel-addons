package flixel.addons.display;

#if (openfl >= "8.0.0")
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.Graphics;
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
 *
 * @since 2.9.0
 */
class FlxShaderMaskCamera extends FlxCamera
{
	/**
	 * Internal sprite, duplicate of `_scrollRect` to which we apply a shader and mask.
	 * It is a child of `flashSprite`.
	 * Its position is also modified by the `updateScrollRect()` method.
	 */
	var _shadedScrollRect:Sprite = new Sprite();

	/**
	 * All tile rendering is duplicated to this canvas, so that we have
	 * another copy of the scene to which to apply the effect shader.
	 * It is a child of `_shadedScrollRect`
	 * Its position is modified by `updateInternalSpritePositions()`
	 */
	var shaderCanvas:Sprite;

	/**
	 * Only the mask objects are rendered to this sprite,
	 * which is both a child of and used as a mask for `_shadedScrollRect`.
	 */
	var maskCanvas:Sprite;

	/**
	 * This filter is applied to the area masked by maskCanvas
	 */
	var shaderFilter:ShaderFilter;

	/**
	 *  Collection of objects that will be rendered to the mask buffer rather than the main camera.
	 */
	var _maskGroup:FlxGroup;

	/**
	 * Instantiates a new camera at the specified location, with the specified size and zoom level,
	 * which will be shaded in areas by the specified shader.
	 *
	 * @param   effectShader  Shader to be applied to the masked area.
	 * @param   X             X location of the camera's display in pixels. Uses native, 1:1 resolution, ignores zoom.
	 * @param   Y             Y location of the camera's display in pixels. Uses native, 1:1 resolution, ignores zoom.
	 * @param   Width         The width of the camera display in pixels.
	 * @param   Height        The height of the camera display in pixels.
	 * @param   Zoom          The initial zoom level of the camera.
	 *                        A zoom level of 2 will make all pixels display at 2x resolution.
	 */
	public function new(effectShader:Shader, X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0)
	{
		if (FlxG.renderBlit)
		{
			throw "FlxShaderMaskCamera is not supported in blit render mode";
		}

		// Create display objects and set mask
		shaderCanvas = new Sprite();
		maskCanvas = new Sprite();
		_shadedScrollRect.mask = maskCanvas;
		// Call super, which will call overriden functions to position our new objects
		super(X, Y, Width, Height, Zoom);
		// Add display objects to hierarchy
		flashSprite.addChild(_shadedScrollRect);
		_shadedScrollRect.addChild(shaderCanvas);
		_shadedScrollRect.addChild(maskCanvas);

		_maskGroup = new FlxGroup();

		// Apply the provided shader using a ShaderFilter
		shaderFilter = new ShaderFilter(effectShader);
		_shadedScrollRect.filters = [shaderFilter];
	}

	override function update(elapsed:Float):Void
	{
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
		var oldCanvas:Sprite = canvas;
		while (currItem != null)
		{
			// render to main canvas
			currItem.render(this);
			// render to shader canvas
			canvas = shaderCanvas;
			currItem.render(this);
			// revert canvas
			canvas = oldCanvas;
			currItem = currItem.next;
		}
		// reset these to avoid re-drawing all other draw items to the mask canvas
		// this is safe, since draw items are disposed by iterating over _headTiles and _headTriangles
		_currentDrawItem = null;
		_headOfDrawStack = null;
		// populate the draw stack with mask items
		_maskGroup.draw();
		// render draw stack to mask canvas
		maskCanvas.graphics.clear();
		canvas = maskCanvas;
		currItem = _headOfDrawStack;
		while (currItem != null)
		{
			currItem.render(this);
			currItem = currItem.next;
		}
		canvas = oldCanvas;
	}

	/**
	 * Add objects and groups to the mask.
	 * The effect shader is applied to the area covered by objects added in this way.
	 * The camera will `update()` objects added here, so you probably want to avoid
	 * adding them to your scene as well.
	 *
	 * @return  The same `FlxBasic` object that was passed in.
	 */
	public function addMaskObject(object:FlxBasic):FlxBasic
	{
		object.camera = this;
		return _maskGroup.add(object);
	}

	/**
	 * Remove objects and groups from the mask.
	 *
	 * @return  The removed object.
	 */
	public function removeMaskObject(object:FlxBasic):FlxBasic
	{
		return _maskGroup.remove(object);
	}

	override function destroy():Void
	{
		FlxDestroyUtil.removeChild(flashSprite, _shadedScrollRect);
		FlxDestroyUtil.removeChild(_shadedScrollRect, shaderCanvas);
		if (shaderCanvas != null)
		{
			for (i in 0...shaderCanvas.numChildren)
			{
				shaderCanvas.removeChildAt(0);
			}
			shaderCanvas = null;
		}
		if (maskCanvas != null)
		{
			for (i in 0...maskCanvas.numChildren)
			{
				maskCanvas.removeChildAt(0);
			}
			maskCanvas = null;
		}

		if (_maskGroup != null)
		{
			_maskGroup.destroy();
			_maskGroup = null;
		}

		_shadedScrollRect = null;
		shaderFilter = null;

		super.destroy();
	}

	// Apply position/size changes to our duplicate and mask canvases
	override function updateInternalSpritePositions():Void
	{
		super.updateInternalSpritePositions();
		for (canvas in [shaderCanvas, maskCanvas])
		{
			if (canvas != null)
			{
				canvas.x = -0.5 * width * (scaleX - initialZoom) * FlxG.scaleMode.scale.x;
				canvas.y = -0.5 * height * (scaleY - initialZoom) * FlxG.scaleMode.scale.y;

				canvas.scaleX = totalScaleX;
				canvas.scaleY = totalScaleY;
			}
		}
	}

	// Apply non-directed fills to both the canvas and duplicate canvas
	override public function fill(Color:FlxColor, BlendAlpha:Bool = true, FxAlpha:Float = 1.0, ?graphics:Graphics):Void
	{
		if (graphics != null)
		{
			super.fill(Color, BlendAlpha, FxAlpha, graphics);
		}
		else
		{
			super.fill(Color, BlendAlpha, FxAlpha, canvas.graphics);
			super.fill(Color, BlendAlpha, FxAlpha, shaderCanvas.graphics);
		}
	}

	// Apply effects to our duplicate canvas
	override function drawFX():Void
	{
		super.drawFX();

		// Draw the "flash" special effect onto the buffer
		if (_fxFlashAlpha > 0.0)
		{
			var alphaComponent = _fxFlashColor.alpha;
			super.fill((_fxFlashColor & 0x00ffffff), true, ((alphaComponent <= 0) ? 0xff : alphaComponent) * _fxFlashAlpha / 255, shaderCanvas.graphics);
		}
		// Draw the "fade" special effect onto the buffer
		if (_fxFadeAlpha > 0.0)
		{
			var alphaComponent = _fxFadeColor.alpha;
			super.fill((_fxFadeColor & 0x00ffffff), true, ((alphaComponent <= 0) ? 0xff : alphaComponent) * _fxFadeAlpha / 255, shaderCanvas.graphics);
		}
	}

	// Apply alpha changes to our duplicate canvas
	override function set_alpha(Alpha:Float):Float
	{
		super.set_alpha(Alpha);
		shaderCanvas.alpha = canvas.alpha;
		return Alpha;
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
}
#end
