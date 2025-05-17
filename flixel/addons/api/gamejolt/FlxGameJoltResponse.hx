package flixel.addons.api.gamejolt;

/**
 * The GameJolt API responses format.
 */
typedef FlxGameJoltResponse =
{
	/**
	 * Whether if the request ended successfully or not. \
	 * This is also the holder of the response from `SESSION_CHECK` request.
	 */
	var success:Bool;
	
	/**
	 * If the request fails, the error message will be put here.
	 */
	@:optional var message:String;
	
	/**
	 * Holder of the response from `USER_FETCH` request, if such request finish with success.
	 */
	@:optional var users:Array<FlxGameJoltUser>;
	
	/**
	 * Holder of the response from `TROPHIES_FETCH` request, if such request finish with success.
	 */
	@:optional var trophies:Array<FlxGameJoltTrophy>;
	
	/**
	 * Holder of the response from `SCORES_FETCH` request, if such request finish with success.
	 */
	@:optional var scores:Array<FlxGameJoltScore>;
	
	/**
	 * Holder of the response from `SCORES_TABLE` request, if such request finish with success.
	 */
	@:optional var tables:Array<FlxGameJoltScoreTable>;
	
	/**
	 * Holder of the response from `SCORES_GETRANK` request, if such request finish with success.
	 */
	@:optional var rank:Int;
	
	/**
	 * Holder of the response from `FRIENDS` request, if such request finish with success.
	 */
	@:optional var friends:Array<{friend_id:Int}>;
	
	/**
	 * Holder of the response from `DATA_GETKEYS` request, if such request finish with success.
	 */
	@:optional var keys:Array<{key:String}>;
	
	/**
	 * Holder of the response from `DATA_FETCH` request, if such request finish with success.
	 */
	@:optional var data:String;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var timestamp:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var timezone:String;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var year:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var month:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var day:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var hour:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var minute:Int;
	
	/**
	 * Holder of one of the response parameters from `TIME` request, if such request finish with success.
	 */
	@:optional var second:Int;
	
	/**
	 * Holder of the response from `BATCH` request, if such request finish with success.
	 */
	@:optional var responses:Array<FlxGameJoltResponse>;
}
