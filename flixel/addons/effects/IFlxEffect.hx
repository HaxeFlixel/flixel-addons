package flixel.addons.effects;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BitmapData;
import openfl.geom.Point;

interface IFlxEffect extends IFlxDestroyable
{
	public var active:Bool;
	public var offset:Point;
	public function update(elapsed:Float):Void;
	public function apply(bitmapData:BitmapData):BitmapData;
}