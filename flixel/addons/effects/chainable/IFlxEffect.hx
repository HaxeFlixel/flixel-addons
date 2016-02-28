package flixel.addons.effects.chainable;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BitmapData;

interface IFlxEffect extends IFlxDestroyable
{
	public var active:Bool;
	public var offset(default, null):FlxPoint;
	public function update(elapsed:Float):Void;
	public function apply(bitmapData:BitmapData):BitmapData;
}