package flixel.addons.util.position;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;

using flixel.addons.util.position.FlxDynamicPosition;

/**
 * @author DleanJeans
 * @link https://twitter.com/DleanJeans
 * 
 * An util class for positioning Dynamic objects through static extension
 * For FlxObjects, use FlxPosition
 * 
 * Import:
 * 
 * using flixel.addons.util.position.FlxDynamicPosition;
 * 
 * To import both FlxPosition and FlxDynamicPosition,
 * import FlxDynamicPosition first and then FlxPosition:
 * 
 * using flixel.addons.util.position.FlxDynamicPosition;
 * using flixel.addons.util.position.FlxPosition;
 */

class FlxDynamicPosition {
	public static var screenCenter(get, null):FlxPoint;
	public static var screenTopLeft(get, null):FlxPoint;
	public static var screenMidTop(get, null):FlxPoint;
	public static var screenTopRight(get, null):FlxPoint;
	public static var screenMidRight(get, null):FlxPoint;
	public static var screenBottomRight(get, null):FlxPoint;
	public static var screenMidBottom(get, null):FlxPoint;
	public static var screenBottomLeft(get, null):FlxPoint;
	public static var screenMidLeft(get, null):FlxPoint;
	
	public static inline function getTopLeft(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.x, object.y);
	}
	
	public static inline function setTopLeft(object:Dynamic, point:FlxPoint) {
		object.setPosition(point.x, point.y);
		point.putWeak();
	}
	
	public static inline function getMidTop(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getTop());
	}
	
	public static inline function setMidTop(object:Dynamic, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setTop(point.y);
		point.putWeak();
	}
	
	public static inline function getTopRight(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.y);
	}
	
	public static inline function setTopRight(object:Dynamic, point:FlxPoint) {
		object.setRight(point.x);
		object.y = point.y;
		point.putWeak();
	}
	
	public static inline function getMidLeft(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.x, object.getCenterY());
	}
	
	public static inline function setMidLeft(object:Dynamic, point:FlxPoint) {
		object.x = point.x;
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getCenter(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getCenterY());
	}
	
	public static inline function setCenter(object:Dynamic, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getMidRight(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.getCenterY());
	}
	
	public static inline function setMidRight(object:Dynamic, point:FlxPoint) {
		object.setRight(point.x);
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getBottomLeft(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.x, object.getBottom());
	}
	
	public static inline function setBottomLeft(object:Dynamic, point:FlxPoint) {
		object.x = point.x;
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getMidBottom(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getBottom());
	}
	
	public static inline function setMidBottom(object:Dynamic, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getBottomRight(object:Dynamic):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.getBottom());
	}
	
	public static inline function setBottomRight(object:Dynamic, point:FlxPoint) {
		object.setRight(point.x);
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getTop(object:Dynamic):Float {
		return object.y;
	}
	
	public static inline function setTop(object:Dynamic, y:Float):Float {
		return object.y = y;
	}
	
	public static inline function getBottom(object:Dynamic):Float {
		return object.y + object.height;
	}
	
	public static inline function setBottom(object:Dynamic, y:Float):Float {
		object.y = y - object.height;
		return y;
	}
	
	public static inline function getLeft(object:Dynamic):Float {
		return object.x;
	}
	
	public static inline function setLeft(object:Dynamic, x:Float):Float {
		return object.x = x;
	}
	
	public static inline function getRight(object:Dynamic):Float {
		return object.x + object.width;
	}
	
	public static inline function setRight(object:Dynamic, x:Float):Float {
		object.x = x - object.width;
		return x;
	}
	
	public static inline function getCenterX(object:Dynamic):Float {
		return object.x + object.width / 2;
	}
	
	public static inline function setCenterX(object:Dynamic, x:Float):Float {
		object.x = x - object.width / 2;
		return x;
	}
	
	public static inline function getCenterY(object:Dynamic):Float {
		return object.y + object.height / 2;
	}
	
	public static inline function setCenterY(object:Dynamic, y:Float):Float {
		object.y = y - object.height / 2;
		return y;
	}
	
	static inline function get_screenTopLeft():FlxPoint {
		return FlxPoint.weak();
	}
	
	static inline function get_screenMidTop():FlxPoint {
		return FlxPoint.weak(FlxG.width / 2);
	}
	
	static inline function get_screenTopRight():FlxPoint {
		return FlxPoint.weak(FlxG.width, 0);
	}
	
	static inline function get_screenMidLeft():FlxPoint {
		return FlxPoint.weak(0, FlxG.height / 2);
	}
	
	static inline function get_screenCenter():FlxPoint {
		return FlxPoint.weak(FlxG.width / 2, FlxG.height / 2);
	}
	
	static inline function get_screenMidRight():FlxPoint {
		return FlxPoint.weak(FlxG.width, FlxG.height / 2);
	}
	
	static inline function get_screenBottomRight():FlxPoint {
		return FlxPoint.weak(FlxG.width, FlxG.height);
	}
	
	static inline function get_screenMidBottom():FlxPoint {
		return FlxPoint.weak(FlxG.width / 2, FlxG.height);
	}
	
	static inline function get_screenBottomLeft():FlxPoint {
		return FlxPoint.weak(0, FlxG.height);
	}
	
}