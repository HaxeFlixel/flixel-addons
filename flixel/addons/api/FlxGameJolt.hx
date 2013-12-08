package flixel.addons.api;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;

#if flash
import flash.Lib;
#end

/**
 * Similar to FlxKongregate, this allows access to the GameJolt API. Based on the AS3 version by SumYungGai. Will always return Map<String,String> to callback functions.
 * 
 * @see 	http://gamejolt.com/community/forums/topics/as3-trophy-api/305/
 * @see 	http://gamejolt.com/api/doc/game/
 * @author 	SumYungGai
 * @author 	Steve Richey (STVR)
 */
class FlxGameJolt
{
	/**
	 * The hash type to be used. Set to FlxGameJolt.HASH_MD5 or FlxGameJolt.HASH_SHA1. Default is MD5.
	 */
	public static var hashType:Int = HASH_MD5;
	
	/**
	 * Hash types for the cryptography function. Either one works per the API, and MD5 is used by default.
	 */
	inline public static var HASH_MD5:Int = 0;
	inline public static var HASH_SHA1:Int = 1;
	
	/**
	 * Trophy data return types. As an alternative to these, can just pass in the ID of the trophy to see if it's unlocked.
	 */
	inline static public var TROPHIES_MISSING:Int = -1;
	inline static public var TROPHIES_ACHIEVED:Int = -2;
	
	/**
	 * Internal storage for a callback function, used when _apiLoader is complete.
	 */
	private static var _callBack:Dynamic;
	
	/**
	 * Internal storage for this game's ID.
	 */
	private static var _gameID:Int;
	
	/**
	 * Internal storage for this game's private key.
	 */
	private static var _privateKey:String;
	
	/**
	 * Internal storage for this user's username. Can be retrieved automatically if Flash or QuickPlay.
	 */
	private static var _userName:String;
	
	/**
	 * Internal storage for this user's token. Can be retrieved automatically if Flash or QuickPlay.
	 */
	private static var _userToken:String;
	
	/**
	 * Internal storage for the most common URL elements, the gameID, user name, and user token.
	 */
	private static var _idURL:String;
	
	/**
	 * Set to true once game ID, user name, user token have been set and user name and token has been verified.
	 */
	private static var _initialized:Bool;
	
	public static var initialized(get, null):Bool;
	
	private static function get_initialized():Bool
	{
		return _initialized;
	}
	
	/**
	 * Various strings required by the API's HTTP values.
	 */
	inline private static var URL_ACHIEVED:String = "&achieved=";
	inline private static var URL_ACTIVE:String = "&active=";
	inline private static var URL_ADD:String = "add/";
	inline private static var URL_API:String = "http://gamejolt.com/api/game/v1/";
	inline private static var URL_CLOSE:String = "close/";
	inline private static var URL_DATA_STORE:String = "data-store/";
	inline private static var URL_DATA:String = "&data=";
	inline private static var URL_EXTRA_DATA:String = "&extra_data=";
	inline private static var URL_GAME:String = "&game_id=";
	inline private static var URL_GET_KEYS:String = "get-keys/";
	inline private static var URL_GUEST:String = "&guest=";
	inline private static var URL_KEY:String = "&key=";
	inline private static var URL_LIMIT:String = "&limit=";
	inline private static var URL_OPEN:String = "open/";
	inline private static var URL_PING:String = "ping/";
	inline private static var URL_REMOVE:String = "remove/";
	inline private static var URL_RETURN_TYPE:String = "?format=keypair";
	inline private static var URL_SCORE:String = "&score=";
	inline private static var URL_SCORES:String = "scores/";
	inline private static var URL_SESSIONS:String = "sessions/";
	inline private static var URL_SET:String = "set/";
	inline private static var URL_SIGNATURE:String = "&signature=";
	inline private static var URL_SORT:String = "&sort=";
	inline private static var URL_TABLE_ID:String = "&table_id=";
	inline private static var URL_TIME:String = "&time=";
	inline private static var URL_TROPHY:String = "trophies/";
	inline private static var URL_TROPHY_ADD:String = "add-achieved/";
	inline private static var URL_TROPHY_ID:String = "&trophy_id=";
	inline private static var URL_USERS:String = "users/";
	inline private static var URL_USER_AUTH:String = "auth/";
	inline private static var URL_USER_NAME:String = "&username=";
	inline private static var URL_USER_TOKEN:String = "&user_token=";
	
	/**
	 * Initialize this class to enable API usage. MUST be called before anything else! Automatically attempts to pull user info and authorize it.
	 * 
	 * @param	GameID		The unique game ID associated with this game on GameJolt. You must create a game profile on GameJolt to get this number.
	 * @param	PrivateKey	Your private key. You must have a developer account on GameJolt to have this number. Do NOT store this as plaintext in your game!
	 * @param 	UserName	This user's name. Not needed for GameJolt-embedded Flash or desktop targets run through QuickPlay. Otherwise, you'll need to set these manually.
	 * @param 	UserToken	This user's token. Each user's token is a unique string similar to a password, that is used for trophies and achievements.
	 * @return 	Whether or not user authorization was successful.
	 */
	public static function init( GameID:Int, PrivateKey:String, ?UserName:String, ?UserToken:String ):Void
	{
		_gameID = GameID;
		_privateKey = PrivateKey;
		
		if ( UserName == null ) {
			#if desktop
			for ( arg in Sys.args() ) {
				var argArray = arg.split( "=" );
				
				if ( argArray[0] == "gjapi_username" ) {
					_userName = argArray[1];
				}
				
				if ( argArray[0] == "gjapi_token" ) {
					_userToken = argArray[1];
				}
			}
			#elseif flash
			var parameters = Lib.current.loaderInfo.parameters;
			
			if ( parameters.gjapi_username != null ) {
				_userName = parameters.gjapi_username;
			}
			
			if ( parameters.gjapi_token != null ) {
				_userToken = parameters.gjapi_token;
			}
			#end
		} else {
			_userName = UserName;
			_userToken = UserToken;
		}
		
		_idURL = URL_GAME + _gameID + URL_USER_NAME + _userName + URL_USER_TOKEN + _userToken;
		
		authorizeUser();
	}
	
	/**
	 * Unlock a trophy for this user.
	 * 
	 * @param	TrophyID	The unique ID number for this trophy. Can be seen at http://gamejolt.com/dashboard/developer/games/achievements/<Your Game ID>/ in the right-hand column.
	 * @param 	?Callback	An optional callback function.
	 */
	public static function addTrophyAchieved( TrophyID:Int, ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + URL_TROPHY + URL_TROPHY_ADD + URL_RETURN_TYPE + _idURL + URL_TROPHY_ID + TrophyID, Callback );
	}
	
	/**
	 * Retrieve trophy data.
	 * 
	 * @param	DataType	Pass either FlxGameJolt.TROPHIES_MISSING or FlxGameJolt.TROPHIES_ACHIEVED to get the trophies this user is missing or already has, respectively.  Or, pass in a trophy ID # to see if this user has that trophy or not.  If unused, will return all trophies.
	 * @param	?Callback	An optional callback function.
	 */
	public static function getTrophyData( DataType:Int = 0, ?Callback:Dynamic ):Void
	{
		var tempURL:String = URL_API + URL_TROPHY + URL_RETURN_TYPE + _idURL;
		
		switch( DataType ) {
			case 0:
				// do nothing, will load all trophies
			case TROPHIES_MISSING:
				tempURL += URL_ACHIEVED + "false";
			case TROPHIES_ACHIEVED:
				tempURL += URL_ACHIEVED + "true";
			default:
				tempURL += URL_TROPHY_ID + Std.string( DataType );
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Retrieve the high scores from this game's remote data.
	 * 
	 * @param	Limit		The maximum number of scores to retrieve. Leave null to retrieve only this user's scores.
	 * @param	?CallBack	An optional callback function.
	 */
	public static function getHighscores( ?Limit:Int, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_SCORES + URL_RETURN_TYPE;
		
		if ( Limit != null ) {
			tempURL += URL_GAME + _gameID + URL_LIMIT + Limit;
		} else {
			tempURL += _idURL;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Set a new high score.
	 * 
	 * @param	Score		A string representation of the score, such as "234 Jumps".
	 * @param	Sort		A numerical representation of the score as a numerical value, such as "234".
	 * @param 	AllowGuest	Whether or not to allow guest scores. If true, will enable storing the high score via a guest name, if user data has not been retrieved.
	 * @param	?GuestName	The guest name to use, if AllowGuest is true.
	 * @param	?ExtraData	Optional extra data associated with the score, which will NOT be visible on the site but can be retrieved by the API.
	 * @param 	?TableID	Optional: the ID of the table you'd lke to send data to. If null, score will be sent to the primary high score table.
	 * @param 	Callback 	An optional callback function.
	 */
	public static function setHighscore( Score:String, Sort:Float, AllowGuest:Bool, ?GuestName:String, ?ExtraData:String, ?TableID:Int, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_SCORES + URL_ADD + URL_RETURN_TYPE;
		
		// Will still post data if we have a valid game ID but not user data, if AllowGuest is true.
		
		if ( AllowGuest && !_initialized && _gameID != 0 && GuestName != null ) {
			tempURL += URL_GAME + _gameID + URL_SCORE + Score + URL_SORT + Sort + URL_GUEST + GuestName;
		} else {
			tempURL += _idURL + URL_SCORE + Score + URL_SORT + Sort;
			
			if ( ExtraData != null ) {
				tempURL += URL_EXTRA_DATA + ExtraData;
			}
			
			if ( TableID != null ) {
				tempURL += URL_TABLE_ID + TableID;
			}
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Set data in the remote data store.
	 * 
	 * @param	Key			The key for this data.
	 * @param	Data		The key value.
	 * @param	User		Whether or not to associate this with this user. True by default.
	 * @param	?Callback	An optional callback function.
	 */
	public static function setKeyData( Key:String, Data:String, User:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_DATA + URL_SET + URL_RETURN_TYPE;
		
		if ( User ) {
			tempURL += _idURL + URL_KEY + Key + URL_DATA + Data;
		} else {
			tempURL += URL_GAME + _gameID + URL_KEY + Key + URL_DATA + Data;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Get data from the remote data store.
	 * 
	 * @param	Key			The key for the data to retrieve.
	 * @param	User		Whether or not to get the data associated with this user. True by default.
	 * @param	?Callback	An optional callback function.
	 */
	public static function getKeyData( Key:String, User:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_DATA + URL_RETURN_TYPE;
		
		if ( User ) {
			tempURL += _idURL + URL_KEY + Key;
		} else {
			tempURL += URL_GAME + _gameID + URL_KEY + Key;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Remove data from the remote data store.
	 * 
	 * @param	Key			The key for the data to remove.
	 * @param	User		Whether or not to remove the data associated with this user. True by default.
	 * @param	?Callback	An optional callback function.
	 */
	public static function removeKeyData( Key:String, User:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_DATA + URL_REMOVE + URL_RETURN_TYPE;
		
		if ( User ) {
			tempURL += _idURL + URL_KEY + Key;
		} else {
			tempURL += URL_GAME + _gameID + URL_KEY + Key;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Get all keys in the data store.
	 * 
	 * @param	User		Whether or not to get the keys associated with this user. True by default.
	 * @param	?Callback	An optional callback function.
	 */
	public static function getAllKeys( User:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_DATA + URL_REMOVE + URL_GET_KEYS;
		
		if ( User ) {
			tempURL += _idURL;
		} else {
			tempURL += URL_GAME + _gameID;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Begin a new session.
	 * 
	 * ?Callback 	An optional callback function.
	 */
	public static function openSession( ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + URL_SESSIONS + URL_OPEN + URL_RETURN_TYPE + _idURL, Callback );
	}
	
	/**
	 * Ping the current session. The API states that a session will be closed after 120 seconds without a ping, and recommends pinging every 30 seconds or so.
	 * 
	 * @param	Active		Leave true to set the session to active, or set to false to set the session to idle.
	 * @param	?Callback	An optional callback function.
	 */
	public function pingSession( Active:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + URL_SESSIONS + URL_PING + URL_RETURN_TYPE + _idURL + URL_ACTIVE;
		
		if ( Active ) {
			tempURL += "active";
		} else {
			tempURL += "idle";
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Close the current session.
	 * 
	 * @param	?Callback	An optional callback function.
	 */
	public function sessionClose( ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + URL_SESSIONS + URL_CLOSE + URL_RETURN_TYPE + _idURL, Callback );
	}
	
	/**
	 * A generic function to setup and send a URLRequest via _apiLoader.
	 * 
	 * @param	URLString	The URL to send to. Usually formatted as the API url, section of the API (e.g. "trophies/") and then variables to pass (e.g. user name, trophy ID).
	 * @param	?Callback	A function to call when loading is done. If null, no function is called when loading is done.
	 */
	private static function sendLoaderRequest( URLString:String, ?Callback:Dynamic -> Void ):Void
	{
		if ( !_initialized && URLString != URL_API + URL_USERS + URL_USER_AUTH + URL_RETURN_TYPE + _idURL ) {
			#if debug
			trace( "FlxGameJolt is not initialized!" );
			#end
			return;
		}
		
		var request:URLRequest = new URLRequest( URLString + URL_SIGNATURE + encryptURL( URLString ) );
		request.method = URLRequestMethod.POST;
		
		if ( Callback != null ) {
			_callBack = Callback;
		}
		
		var loader = new URLLoader();
		
		if ( !_initialized ) {
			loader.addEventListener( Event.COMPLETE, authorizationCheck );
		} else {
			loader.addEventListener( Event.COMPLETE, parseData );
		}
		
		#if debug
		trace( "FlxGameJolt is about to contact " + request.url );
		#end
		loader.load( request );
	}
	
	private static function parseData( e:Event ):Void
	{
		_callBack( keypairToMap( e.currentTarget.data ) );
	}
	
	/**
	 * Internal method to split a keypair string into a map of <String,String>. Removes double quotes from values.
	 */
	private static function keypairToMap( s:String ):Map<String,String>
	{
		var array = s.split( "/r" );
		var returnMap = new Map<String,String>();
		
		for ( e in array ) {
			var tempArray = e.split( ":" );
			returnMap.set( tempArray[0], tempArray[1].substring( 1, tempArray[1].indexOf( String.fromCharCode( 34 ), 1 ) ) );
		}
		
		return returnMap;
	}
	
	/**
	 * Internal function to verify that this user's user name and token are valid.
	 * 
	 * @return	Whether or not this user's name and token are valid.
	 */
	private static function authorizeUser():Void  
	{
		sendLoaderRequest( URL_API + URL_USERS + URL_USER_AUTH + URL_RETURN_TYPE + _idURL, authorizationCheck );
	}
	
	/**
	 * Internal function to evaluate whether or not a user was successfully authorized and store the result in _initialized.
	 */
	private static function authorizationCheck( e:Event ):Void
	{
		var data = keypairToMap( Std.string( e.currentTarget.data ) );
		
		if ( data.exists( "success" ) ) {
			if ( data.get( "success" ) == "true" ) {
				_initialized = true;
				
				#if debug
				trace( "FlxGameJolt was successfully initialized for user " + _userName + ", with token " + _userToken + "!" );
				#end
			} else {
				#if debug
				trace( "FlxGameJolt initialization not successful for user " + _userName + ", with token " + _userToken );
				#end
			}
		}
	}
	
	/**
	 * Generate a valid MD5 hash signature, required by the API to verify game data is valid.
	 * 
	 * @param	Url			The URL to encrypt. This, along with the private key, form the string which is encoded.
	 * @return	An encoded MD5 or SHA1 hash.
	 */
	private static function encryptURL( Url:String ):String
	{
		if ( hashType == HASH_SHA1 ) {
			return Sha1.encode( Url + _privateKey );
		} else {
			return Md5.encode( Url + _privateKey );
		}
	}
}