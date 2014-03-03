package flixel.addons.nape;

import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxState;
import flixel.system.ui.FlxSystemButton;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.space.Space;

#if !FLX_NO_DEBUG
import nape.util.ShapeDebug;
@:bitmap("assets/images/napeDebug.png") class GraphicNapeDebug extends BitmapData {}
#end

/**
 * FlxNapeState is a FlxState that integrates nape.space.Space
 * to provide Nape physics simulation in Flixel.
 *
 * Extend this state, add some FlxNapeSprite(s) to start using flixel + nape physics.
 *
 * Note that space is a static variable, use FlxNapeState.space
 * to access it.
 *
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class FlxNapeState extends FlxState
{
	/**
	 * The space where the nape physics simulation occur.
	 */
	public static var space:Space;
	
	#if !FLX_NO_DEBUG
	/**
	 * Contains the sprite used for nape debug graphics.
	 */
	public static var debug(get, never):ShapeDebug;
	
	private static function get_debug():ShapeDebug
	{ 
		return cast(FlxG.state, FlxNapeState)._physDbgSpr; 
	}
	#end
	
	/**
	 * The number of iterations used by nape in resolving errors in the velocities of objects. This is together with collision 
	 * detection the most expensive phase of a simulation update, as well as the most important for stable results. (default 10)
	 */
	public var velocityIterations:Int = 10;
	/**
	 * The number of iterations used by nape in resolving errors in the positions of objects. This is far more lightweight than 
	 * velocity iterations, is well as being less important for the stability of results. (default 10)
	 */
	public var positionIterations:Int = 10;
	
	/**
	 * Whether the nape debug graphics are enabled or not.
	 */
	public var napeDebugEnabled(default, set):Bool;
	
	#if !FLX_NO_DEBUG
	/**
	 * Contains the sprite used for nape debug graphics.
	 */
	private var _physDbgSpr:ShapeDebug;
	
	/**
	 * Contains a reference to the Nape button in the debugger.
	 */
	private var _button:FlxSystemButton;
	#end

	/**
	 * Override this method like a normal FlxState, but add
	 * super.create() to it, so that this function is called.
	 */
	override public function create():Void
	{
		if (space == null)
		{
			space = new Space(new Vec2());
		}
		
		#if !FLX_NO_DEBUG
		// Add a button to toggle Nape debug shapes to the debugger
		_button = FlxG.debugger.addButton(RIGHT, new GraphicNapeDebug(0, 0), toggleDebug, true, true);
		napeDebugEnabled = false;
		#end
	}

	/**
	 * Creates simple walls around game area - usefull for prototying.
	 *
	 * @param 	MinX 		The smallest X value of your level (usually 0).
	 * @param 	MinY 		The smallest Y value of your level (usually 0).
	 * @param 	MaxX 		The largest X value of your level - 0 means FlxG.width (usually the level width).
	 * @param 	MaxY 		The largest Y value of your level - 0 means FlxG.height (usually the level height).
	 * @param 	Thickness 	How thick the walls are. 10 by default.
	 * @param 	_Material 	The Material to use for the physics body of the walls.
	 */
	public function createWalls(MinX:Float = 0, MinY:Float = 0, MaxX:Float = 0, MaxY:Float = 0, Thickness:Float = 10, _Material:Material = null):Body
	{
		if (MaxX == 0)
		{
			MaxX = FlxG.width;
		}
		
		if (MaxY == 0)
		{
			MaxY = FlxG.height;
		}
		
		if (_Material == null)
		{
			_Material = new Material(0.4, 0.2, 0.38, 0.7);
		}
		
		var walls:Body = new Body(BodyType.STATIC);
		
		// Left wall
		walls.shapes.add(new Polygon(Polygon.rect(MinX - Thickness, MinY, Thickness, MaxY + Math.abs(MinY))));
		// Right wall
		walls.shapes.add(new Polygon(Polygon.rect(MaxX, MinY, Thickness, MaxY + Math.abs(MinY))));
		// Upper wall
		walls.shapes.add(new Polygon(Polygon.rect(MinX, MinY - Thickness, MaxX + Math.abs(MinX), Thickness)));
		// Bottom wall
		walls.shapes.add(new Polygon(Polygon.rect(MinX, MaxY, MaxX + Math.abs(MinX), Thickness)));

		walls.space = space;
		walls.setShapeMaterials(_Material);
		
		return walls;
	}

	/**
	 * Override this method and add super.update().
	 */
	override public function update():Void
	{
		space.step(FlxG.elapsed, velocityIterations, positionIterations);
		super.update();
	}

	/**
	 * Override this method to draw debug physics shapes
	 */
	override public function draw():Void
	{
		super.draw();
		
		#if !FLX_NO_DEBUG
		drawPhysDebug();
		#end
	}

	/**
	 * Override this function to null out variables or manually call destroy() 
	 * on class members if necessary. Don't forget to call super.destroy()!
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		space.clear();
		
		FlxNapeState.space = null; // resets atributes like gravity.
		
		#if !FLX_NO_DEBUG
		napeDebugEnabled = false;
		FlxG.debugger.removeButton(_button);
		_button = null;
		#end
	}
	
	private function set_napeDebugEnabled(Value:Bool):Bool
	{
		#if !FLX_NO_DEBUG
		_button.toggled = !Value;
		
		if (Value)
		{
			if (_physDbgSpr == null)
			{
				_physDbgSpr = new ShapeDebug(FlxG.width, FlxG.height);
				_physDbgSpr.drawConstraints = true;
				_physDbgSpr.display.scrollRect = null;
				FlxG.addChildBelowMouse(_physDbgSpr.display);
			}
		}
		else if (_physDbgSpr != null)
		{
			FlxG.removeChild(_physDbgSpr.display);
			_physDbgSpr = null;
		}
		#end
		
		return napeDebugEnabled = Value;
	}

	/**
	 * Draws debug graphics.
	 */
	private function drawPhysDebug():Void
	{
		#if !FLX_NO_DEBUG
		if (_physDbgSpr == null || space == null)
		{
			return;
		}
		
		_physDbgSpr.clear();
		_physDbgSpr.draw(space);
		
		var cam = FlxG.camera;
		var zoom = cam.zoom;
		var sprite = _physDbgSpr.display;
		
		sprite.scaleX = zoom;
		sprite.scaleY = zoom;
		
		sprite.x = -cam.scroll.x * zoom;
		sprite.y = -cam.scroll.y * zoom;
		#end
	}
	
	#if !FLX_NO_DEBUG
	private function toggleDebug():Void
	{
		napeDebugEnabled = !napeDebugEnabled;
	}
	#end
}
