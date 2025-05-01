package flixel.addons.api.gamejolt;

/**
 * This is how GameJolt API responses are formatted like.
 */
typedef FlxGameJoltResponse =
{
	// General
	success:Bool,
	?message:String,
	// User Fetching
	?users:Array<FlxGameJoltUser>,
	// Trophies Fetching
	?trophies:Array<FlxGameJoltTrophy>,
	// Scores Fetching
	?scores:Array<FlxGameJoltScore>,
	?tables:Array<FlxGameJoltScoreTable>,
	?rank:Int,
	// Friends Fetching
	?friends:Array<{friend_id:Int}>,
	// Data Store Fetching
	?keys:Array<{key:String}>,
	?data:String,
	// Time Fetching
	?timestamp:Int,
	?timezone:String,
	?year:Int,
	?month:Int,
	?day:Int,
	?hour:Int,
	?minute:Int,
	?second:Int,
	// Batch Reception
	?responses:Array<FlxGameJoltResponse>
}
