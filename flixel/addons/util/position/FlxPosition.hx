package flixel.addons.util.position;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;

using flixel.addons.util.position.FlxPosition;

/**
 * @author DleanJeans
 * @link https://twitter.com/DleanJeans
 * 
 * An util class for positioning FlxObjects through static extension
 * For Dynamic objects, use FlxDynamicPosition
 * Import:
 * 
 * using flixel.addons.util.position.FlxPosition;
 * 
 * To import both FlxPosition and FlxDynamicPosition,
 * import FlxDynamicPosition first and then FlxPosition:
 * 
 * using flixel.addons.util.position.FlxDynamicPosition;
 * using flixel.addons.util.position.FlxPosition;
 */

class FlxPosition {
	public static var screenCenter(get, null):FlxPoint;
	public static var screenTopLeft(get, null):FlxPoint;
	public static var screenMidTop(get, null):FlxPoint;
	public static var screenTopRight(get, null):FlxPoint;
	public static var screenMidRight(get, null):FlxPoint;
	public static var screenBottomRight(get, null):FlxPoint;
	public static var screenMidBottom(get, null):FlxPoint;
	public static var screenBottomLeft(get, null):FlxPoint;
	public static var screenMidLeft(get, null):FlxPoint;
	
	public static inline function getTopLeft(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.x, object.y);
	}
	
	public static inline function setTopLeft(object:FlxObject, point:FlxPoint) {
		object.setPosition(point.x, point.y);
		point.putWeak();
	}
	
	public static inline function getMidTop(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getTop());
	}
	
	public static inline function setMidTop(object:FlxObject, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setTop(point.y);
		point.putWeak();
	}
	
	public static inline function getTopRight(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.y);
	}
	
	public static inline function setTopRight(object:FlxObject, point:FlxPoint) {
		object.setRight(point.x);
		object.y = point.y;
		point.putWeak();
	}
	
	public static inline function getMidLeft(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.x, object.getCenterY());
	}
	
	public static inline function setMidLeft(object:FlxObject, point:FlxPoint) {
		object.x = point.x;
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getCenter(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getCenterY());
	}
	
	public static inline function setCenter(object:FlxObject, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getMidRight(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.getCenterY());
	}
	
	public static inline function setMidRight(object:FlxObject, point:FlxPoint) {
		object.setRight(point.x);
		object.setCenterY(point.y);
		point.putWeak();
	}
	
	public static inline function getBottomLeft(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.x, object.getBottom());
	}
	
	public static inline function setBottomLeft(object:FlxObject, point:FlxPoint) {
		object.x = point.x;
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getMidBottom(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getCenterX(), object.getBottom());
	}
	
	public static inline function setMidBottom(object:FlxObject, point:FlxPoint) {
		object.setCenterX(point.x);
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getBottomRight(object:FlxObject):FlxPoint {
		return FlxPoint.weak(object.getRight(), object.getBottom());
	}
	
	public static inline function setBottomRight(object:FlxObject, point:FlxPoint) {
		object.setRight(point.x);
		object.setBottom(point.y);
		point.putWeak();
	}
	
	public static inline function getTop(object:FlxObject):Float {
		return object.y;
	}
	
	public static inline function setTop(object:FlxObject, y:Float):Float {
		return object.y = y;
	}
	
	public static inline function getBottom(object:FlxObject):Float {
		return object.y + object.height;
	}
	
	public static inline function setBottom(object:FlxObject, y:Float):Float {
		object.y = y - object.height;
		return y;
	}
	
	public static inline function getLeft(object:FlxObject):Float {
		return object.x;
	}
	
	public static inline function setLeft(object:FlxObject, x:Float):Float {
		return object.x = x;
	}
	
	public static inline function getRight(object:FlxObject):Float {
		return object.x + object.width;
	}
	
	public static inline function setRight(object:FlxObject, x:Float):Float {
		object.x = x - object.width;
		return x;
	}
	
	public static inline function getCenterX(object:FlxObject):Float {
		return object.x + object.width / 2;
	}
	
	public static inline function setCenterX(object:FlxObject, x:Float):Float {
		object.x = x - object.width / 2;
		return x;
	}
	
	public static inline function getCenterY(object:FlxObject):Float {
		return object.y + object.height / 2;
	}
	
	public static inline function setCenterY(object:FlxObject, y:Float):Float {
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