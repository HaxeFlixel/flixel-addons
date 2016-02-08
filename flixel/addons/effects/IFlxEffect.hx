package flixel.addons.effects;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BitmapData;

interface IFlxEffect extends IFlxDestroyable
{
	public var active:Bool;
	public var offset:FlxPoint;
	public function update(elapsed:Float):Void;
	public function apply(bitmapData:BitmapData):BitmapData;
}