package flixel.addons.effects;
import openfl.display.BitmapData;

interface IFlxEffect
{
	public var active:Bool;
	public var offsetDraw:openfl.geom.Point;
	public function destroy():Void;
	public function update(elapsed:Float):Void;
	public function apply(bitmapData:BitmapData):BitmapData;
}