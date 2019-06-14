package flixel.addons.display;

import flixel.FlxCamera;
import flixel.math.FlxMath;

/**
 * FlxZoomCamera: A FlxCamera that centers its zoom on the target that it follows
 *
 * @link http://www.kwarp.com
 * @author greglieberman
 * @email greg@kwarp.com
 */
class FlxZoomCamera extends FlxCamera
{
	/**
	 * Tell the camera to LERP here eventually
	 */
	public var targetZoom:Float;

	/**
	 * This number is pretty arbitrary, make sure it's greater than zero!
	 */
	public var zoomSpeed:Float = 25;

	/**
	 * Determines how far to "look ahead" when the target is near the
	 * edge of the camera's bounds - 0 = no effect, 1 = huge effect
	 */
	public var zoomMargin:Float = 0.25;

	public function new(X:Int, Y:Int, Width:Int, Height:Int, Zoom:Float = 0)
	{
		super(X, Y, Width, Height, FlxCamera.defaultZoom);
		targetZoom = Zoom;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Update camera zoom
		zoom += (targetZoom - zoom) / 2 * elapsed * zoomSpeed;

		// If we are zooming in, align the camera (x, y)
		if (target != null && zoom != 1)
		{
			alignCamera();
		}
		else
		{
			x = 0;
			y = 0;
		}
	}

	/**
	 * Align the camera x and y to center on the target
	 * that it's following when zoomed in
	 *
	 * This took many guesses!
	 */
	function alignCamera():Void
	{
		// Target position in screen space
		var targetScreenX:Float = target.x - scroll.x;
		var targetScreenY:Float = target.y - scroll.y;

		// Center on the target, until the camera bumps up to its bounds
		// then gradually favor the edge of the screen based on zoomMargin
		var ratioMinX:Float = (targetScreenX / (width / 2)) - 1 - zoomMargin;
		var ratioMinY:Float = (targetScreenY / (height / 2)) - 1 - zoomMargin;
		var ratioMaxX:Float = ((-width + targetScreenX) / (width / 2)) + 1 + zoomMargin;
		var ratioMaxY:Float = ((-height + targetScreenY) / (height / 2)) + 1 + zoomMargin;

		// Offsets are numbers between [-1, 1]
		var offsetX:Float = FlxMath.bound(ratioMinX, -1, 0) + FlxMath.bound(ratioMaxX, 0, 1);
		var offsetY:Float = FlxMath.bound(ratioMinY, -1, 0) + FlxMath.bound(ratioMaxY, 0, 1);

		// Offset the screen in any direction, based on zoom level
		// Example: a zoom of 2 offsets it half the screen at most
		x = -(width / 2) * offsetX * (zoom - FlxCamera.defaultZoom);
		y = -(height / 2) * offsetY * (zoom - FlxCamera.defaultZoom);
	}
}
