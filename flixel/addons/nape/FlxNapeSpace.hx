package flixel.addons.nape;

import flash.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.system.ui.FlxSystemButton;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.space.Space;
#if FLX_DEBUG
import nape.util.ShapeDebug;

@:bitmap("assets/images/napeDebug.png")
private class GraphicNapeDebug extends BitmapData {}
#end

/**
 * FlxNapeSpace is a flixel plugin that integrates nape.space.Space
 * to provide Nape physics simulation in Flixel.
 */
class FlxNapeSpace extends FlxBasic
{
	public static var space:Space;

	/**
	 * The number of iterations used by nape in resolving errors in the velocities of objects.
	 * This is together with collision detection the most expensive phase of a simulation update,
	 * as well as the most important for stable results. (default 10)
	 */
	public static var velocityIterations:Int = 10;

	/**
	 * The number of iterations used by nape in resolving errors in the positions of objects.
	 * This is far more lightweight than velocity iterations, as well as being less important
	 * for the stability of results. (default 10)
	 */
	public static var positionIterations:Int = 10;

	/**
	 * Whether or not the nape debug graphics are enabled.
	 */
	public static var drawDebug(default, set):Bool;

	#if FLX_DEBUG
	/**
	 * A useful "canvas" which can be used to draw debug information on.
	 * To get a better idea of its use, see the official Nape demo 'SpatialQueries'
	 * (http://napephys.com/samples.html#swf-SpatialQueries)
	 * where this is used to draw lines emitted from Rays.
	 * A sensible place to use this would be the state's draw() method.
	 * Note that shapeDebug is null if drawDebug is false.
	 */
	public static var shapeDebug(default, null):ShapeDebug;

	static var drawDebugButton:FlxSystemButton;
	#end

	/**
	 * Needs to be called before creating any FlxNapeSprites
	 * / FlxNapeTilemaps to initialize the space.
	 */
	public static function init():Void
	{
		FlxG.plugins.add(new FlxNapeSpace());

		if (space == null)
			space = new Space(new Vec2());

		FlxG.signals.preStateSwitch.add(onStateSwitch);

		#if FLX_DEBUG
		// Add a button to toggle Nape debug shapes to the debugger
		drawDebugButton = FlxG.debugger.addButton(RIGHT, new GraphicNapeDebug(0, 0), function()
		{
			drawDebug = !drawDebug;
		}, true, true);
		drawDebug = false;
		#end
	}

	/**
	 * Creates simple walls around the game area - useful for prototying.
	 *
	 * @param   minX        The smallest X value of your level (usually 0).
	 * @param   minY        The smallest Y value of your level (usually 0).
	 * @param   maxX        The largest X value of your level - 0 means FlxG.width (usually the level width).
	 * @param   maxY        The largest Y value of your level - 0 means FlxG.height (usually the level height).
	 * @param   thickness   How thick the walls are. 10 by default.
	 * @param   material    The Material to use for the physics body of the walls.
	 */
	public static function createWalls(minX:Float = 0, minY:Float = 0, maxX:Float = 0, maxY:Float = 0, thickness:Float = 10, ?material:Material):Body
	{
		if (maxX == 0)
			maxX = FlxG.width;

		if (maxY == 0)
			maxY = FlxG.height;

		if (material == null)
			material = new Material(0.4, 0.2, 0.38, 0.7);

		var walls:Body = new Body(BodyType.STATIC);

		// Left wall
		walls.shapes.add(new Polygon(Polygon.rect(minX - thickness, minY, thickness, maxY + Math.abs(minY))));
		// Right wall
		walls.shapes.add(new Polygon(Polygon.rect(maxX, minY, thickness, maxY + Math.abs(minY))));
		// Upper wall
		walls.shapes.add(new Polygon(Polygon.rect(minX, minY - thickness, maxX + Math.abs(minX), thickness)));
		// Bottom wall
		walls.shapes.add(new Polygon(Polygon.rect(minX, maxY, maxX + Math.abs(minX), thickness)));

		walls.space = space;
		walls.setShapeMaterials(material);

		return walls;
	}

	static function set_drawDebug(drawDebug:Bool):Bool
	{
		#if FLX_DEBUG
		if (drawDebugButton != null)
			drawDebugButton.toggled = !drawDebug;

		if (drawDebug)
		{
			if (shapeDebug == null)
			{
				shapeDebug = new ShapeDebug(FlxG.width, FlxG.height);
				shapeDebug.drawConstraints = true;
				shapeDebug.display.scrollRect = null;
				shapeDebug.thickness = 1;
				FlxG.addChildBelowMouse(shapeDebug.display);
			}
		}
		else if (shapeDebug != null)
		{
			FlxG.removeChild(shapeDebug.display);
			shapeDebug = null;
		}
		#end

		return FlxNapeSpace.drawDebug = drawDebug;
	}

	static function onStateSwitch():Void
	{
		if (space != null)
		{
			space.clear();
			space = null; // resets atributes like gravity.
		}

		#if FLX_DEBUG
		drawDebug = false;

		if (drawDebugButton != null)
		{
			FlxG.debugger.removeButton(drawDebugButton);
			drawDebugButton = null;
		}
		#end
	}

	override public function update(elapsed:Float):Void
	{
		if (space != null && elapsed > 0)
			space.step(elapsed, velocityIterations, positionIterations);
	}

	/**
	 * Draws debug graphics.
	 */
	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		#if FLX_DEBUG
		if (shapeDebug == null || space == null)
			return;

		shapeDebug.clear();
		shapeDebug.draw(space);

		var sprite = shapeDebug.display;
		sprite.x = 0;
		sprite.y = 0;
		sprite.scaleX = 1;
		sprite.scaleY = 1;
		FlxG.camera.transformObject(sprite);
		#end
	}
}
