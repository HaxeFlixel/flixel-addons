package flixel.addons.api.gamejolt;

/**
 * The main class for GameJolt API. Put all the respective data in this class so `FlxGameJoltRequest` instances can use them to work.
 */
@:allow(flixel.addons.api.gamejolt.FlxGameJoltRequest)
class FlxGameJolt
{
	/**
	 * The user's GameJolt user name.
	 */
	public static var username:String = "";
	
	/**
	 * The user's GameJolt user token. Can only be red by the class itself for security.
	 */
	public static var usertoken(null, default):String = "";
	
	/**
	 * Internal storage for this game's ID.
	 */
	public static var gameID:Int = 0;
	
	/**
	 * Internal storage for this game's private key. Can only be red by the class itself for security. \
	 * Do NOT store your private key as a string literal in your game code! \
	 * This can be found at https://gamejolt.com/dashboard/games/GAME_ID/api/settings where GAME_ID is your unique game ID number. \
	 * Each game has a unique private key, you cannot use one key for all of your games.
	 */
	public static var gameKey(null, default):String = "";
	
	/**
	 * If `true`, requests will use `Md5` encryptation for calls.
	 * Otherwise, they'll use `Sha1` encryptation instead.
	 */
	public static var usingMd5:Bool = true;
}
