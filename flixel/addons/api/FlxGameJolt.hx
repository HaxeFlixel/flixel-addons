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
 * 
 * Usage:
 * Note: Do NOT store you private key as an unobfuscated string! One method is to save it as a text file called "myKey.privatekey" and add "*.privatekey" to your ignore list for version control (.gitignore for git, global-ignores in your config file for svn, .hgignore for Mercurial). Then:
	 * Below your import statements, add @:file("myKey.privatekey") class MyKey extends ByteArray { } to embed that file's data as a ByteArray.
	 * If your game is embedded as Flash on GameJolt's site, or run via Quick Play, you do not need to get the user name and token; this will be done automatically.
	 * Otherwise, you will need to retrieve the user name and token (possibly via an input box prompt).
	 * Then, verify this data via the following method:
		 * var bytearray = new MyKey(); // This will load your private key data as a ByteArray.
		 * var keystring = bytearray..readUTFBytes( bytearray.length ); // This converts the ByteArray to a string.
		 * var gameid = 1; // Replace "1" with your game ID, visible if you go to http://gamejolt.com/dashboard/ -> Click on your game under "Manage Games" -> Click on "Achievements" in the menu.
		 * FlxGameJolt.init( gameid, keystring ); // Use this if your game is embedded as Flash on GameJolt's site, or run via Quick Play. If 
 */
class FlxGameJolt
{
	/**
	 * The hash type to be used for private key encryption. Set to FlxGameJolt.HASH_MD5 or FlxGameJolt.HASH_SHA1. Default is MD5. See http://gamejolt.com/api/doc/game/ section "Signature".
	 */
	public static var hashType:Int = HASH_MD5;
	
	/**
	 * Whether or not the API has been initialized by passing game id, private key, and verifying user name and token.
	 */
	public static var initialized(get, null):Bool;
	
	private static function get_initialized():Bool
	{
		return _initialized;
	}
	
	/**
	 * Hash types for the cryptography function. Use this or HASH_SHA1 for encryptURL(). MD5 is used by default.
	 */
	inline public static var HASH_MD5:Int = 0;
	
	/**
	 * Hash types for the cryptography function. Use this or HASH_MD5 for encryptURL(). MD5 is used by default.
	 */
	inline public static var HASH_SHA1:Int = 1;
	
	/**
	 * Trophy data return type, will return only non-unlocked trophies. As an alternative, can just pass in the ID of the trophy to see if it's unlocked.
	 */
	inline public static var TROPHIES_MISSING:Int = -1;
	
	/**
	 * Trophy data return type, will return only unlocked trophies. As an alternative, can just pass in the ID of the trophy to see if it's unlocked.
	 */
	inline public static var TROPHIES_ACHIEVED:Int = -2;
	
	/**
	 * Internal storage for a callback function, used when the URLLoader is complete.
	 */
	private static var _callBack:Dynamic;
	
	/**
	 * Internal storage for this game's ID.
	 */
	private static var _gameID:Int;
	
	/**
	 * Internal storage for this game's private key. Do NOT store your private key as a string literal in your game! This can be found at http://gamejolt.com/dashboard/developer/games/achievements/GAME_ID/ where GAME_ID is your unique game ID number.
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
	 * Internal storage for the most common URL elements: the gameID, user name, and user token.
	 */
	private static var _idURL:String;
	
	/**
	 * Set to true once game ID, user name, user token have been set and user name and token has been verified.
	 */
	private static var _initialized:Bool;
	
	/**
	 * Various strings required by the API's HTTP values.
	 */
	inline private static var URL_API:String = "http://gamejolt.com/api/game/v1/";
	inline private static var RETURN_TYPE:String = "?format=keypair";
	inline private static var URL_GAME_ID:String = "&game_id=";
	inline private static var URL_USER_NAME:String = "&username=";
	inline private static var URL_USER_TOKEN:String = "&user_token=";
	
	
	inline private static var URL_ACHIEVED:String = "&achieved=";
	inline private static var URL_ACTIVE:String = "&active=";
	inline private static var URL_ADD:String = "add/";
	inline private static var URL_CLOSE:String = "close/";
	inline private static var URL_DATA_STORE:String = "data-store/";
	inline private static var URL_DATA:String = "&data=";
	inline private static var URL_EXTRA_DATA:String = "&extra_data=";
	inline private static var URL_GET_KEYS:String = "get-keys/";
	inline private static var URL_GUEST:String = "&guest=";
	inline private static var URL_KEY:String = "&key=";
	inline private static var URL_LIMIT:String = "&limit=";
	inline private static var URL_OPEN:String = "open/";
	inline private static var URL_PING:String = "ping/";
	inline private static var URL_REMOVE:String = "remove/";
	inline private static var URL_SCORE:String = "&score=";
	inline private static var URL_SCORES:String = "scores/";
	inline private static var URL_SESSIONS:String = "sessions/";
	inline private static var URL_SET:String = "set/";
	inline private static var URL_SIGNATURE:String = "&signature=";
	inline private static var URL_SORT:String = "&sort=";
	inline private static var URL_TABLE_ID:String = "&table_id=";
	inline private static var URL_TIME:String = "&time=";
	inline private static var URL_USERS:String = "users/";
	inline private static var URL_USER_AUTH:String = "auth/";
	
	/**
	 * Initialize this class to verify user name and token. MUST be called before anything else! Automatically attempts to pull user info and authorize it.
	 * 
	 * @param	GameID		The unique game ID associated with this game on GameJolt. You must create a game profile on GameJolt to get this number.
	 * @param	PrivateKey	Your private key. You must have a developer account on GameJolt to have this number. Do NOT store this as plaintext in your game!
	 * @param 	?UserName	This user's name. Not needed for GameJolt-embedded Flash or desktop targets run through QuickPlay. Otherwise, you'll need to set these manually.
	 * @param 	?UserToken	This user's token. Each user's token is a unique string similar to a password that is used for trophies and achievements.
	 * @param	?Callback	An optional callback function. Will be called with false if initialization failed, or true if successful.
	 */
	public static function init( GameID:Int, PrivateKey:String, ?UserName:String, ?UserToken:String, ?Callback:Bool -> Void ):Void
	{
		_gameID = GameID;
		_privateKey = PrivateKey;
		
		// Attempt to pull user name and token data from command line arguments (desktop only) or flashvars (flash only).
		
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
		
		// Only send initialization request to GameJolt if user name and token were found or passed.
		
		if ( _userName != null && _userToken != null ) {
			_idURL = URL_GAME_ID + _gameID + URL_USER_NAME + _userName + URL_USER_TOKEN + _userToken;
			authUser( _userName, _userToken, Callback );
		} else {
			Callback( false );
		}
	}
	
	/**
	 * Fetch user data. Pass UserID to get user name, pass UserName to get UserID, or pass multiple UserIDs to get multiple usernames.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/users/fetch/
	 * @param	?UserID		An integer user ID value. If this is passed, UserName and UserIDs are ignored.
	 * @param	?UserName	A string user name. If this is passed, UserIDs is ignored.
	 * @param	?UserIDs	An array of integers representing user IDs.
	 * @param	?Callback	An optional callback function.
	 */
	public static function fetchUser( ?UserID:Int, ?UserName:String, ?UserIDs:Array<Int>, ?Callback:Dynamic ):Void
	{
		var tempURL:String = URL_API + "users/" + RETURN_TYPE;
		
		if ( UserID != null ) {
			tempURL += "&user_id=" + Std.string( UserID );
		} else if ( UserName != null ) {
			tempURL += "&username=" + UserName;
		} else if ( UserIDs != null ) {
			tempURL += "&user_id="
			
			for ( id in UserIDs ) {
				tempURL += Std.string( id );
			}
			
			tempURL = tempURL.substr(0, tempURL.length - 1);
		} else {
			return;
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Verify user data. Used by init(), you can do it manually if you want but this won't set the initialized variable.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/users/auth/
	 * @param	UserName	A user name.
	 * @param	UserToken	A user token. Players can enter this instead of a password to enable highscores, trophies, etc.
	 * @param	?Callback	An optional callback function.
	 */
	public static function authUser( UserName:String, UserToken:String, ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + RETURN_TYPE + URL_GAME_ID + _gameID + URL_USER_NAME + UserName + URL_USER_TOKEN + UserToken, Callback );
	}
	
	/**
	 * Begin a new session. Sessions that are not pinged at most every 120 seconds will be closed.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/sessions/open/
	 * @param 	?Callback 	An optional callback function.
	 */
	public static function openSession( ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + "sessions/open/" + RETURN_TYPE + _idURL, Callback );
	}
	
	/**
	 * Ping the current session. The API states that a session will be closed after 120 seconds without a ping, and recommends pinging every 30 seconds or so.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/sessions/ping/
	 * @param	Active		Leave true to set the session to active, or set to false to set the session to idle.
	 * @param	?Callback	An optional callback function.
	 */
	public function pingSession( Active:Bool = true, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + "sessions/ping/" + RETURN_TYPE + _idURL + "&active=";
		
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
	 * @see 	http://gamejolt.com/api/doc/game/sessions/close/
	 * @param	?Callback	An optional callback function.
	 */
	public function closeSession( ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + "sessions/close/" + RETURN_TYPE + _idURL, Callback );
	}
	
	/**
	 * Retrieve trophy data.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/trophies/fetch/
	 * @param	DataType	Pass FlxGameJolt.TROPHIES_MISSING or FlxGameJolt.TROPHIES_ACHIEVED to get the trophies this user is missing or already has, respectively.  Or, pass in a trophy ID # to see if this user has that trophy or not.  If unused, will return all trophies.
	 * @param	?Callback	An optional callback function.
	 */
	public static function fetchTrophies( DataType:Int = 0, ?Callback:Dynamic ):Void
	{
		var tempURL:String = URL_API + "trophies/" + RETURN_TYPE + _idURL;
		
		switch( DataType ) {
			case 0:
				// do nothing, will load all trophies
			case TROPHIES_MISSING:
				tempURL += "&achieved=false";
			case TROPHIES_ACHIEVED:
				tempURL += "&achieved=true";
			default:
				tempURL += "&trophy_id=" + Std.string( DataType );
		}
		
		sendLoaderRequest( tempURL, Callback );
	}
	
	/**
	 * Unlock a trophy for this user.
	 * 
	 * @see 	http://gamejolt.com/api/doc/game/trophies/add-achieved/
	 * @param	TrophyID	The unique ID number for this trophy. Can be seen at http://gamejolt.com/dashboard/developer/games/achievements/<Your Game ID>/ in the right-hand column.
	 * @param 	?Callback	An optional callback function.
	 */
	public static function addAchievedTrophy( TrophyID:Int, ?Callback:Dynamic ):Void
	{
		sendLoaderRequest( URL_API + "trophies/add-achieved/" + RETURN_TYPE + _idURL + "&trophy_id=" + TrophyID, Callback );
	}
	
	/**
	 * Retrieve the high scores from this game's remote data.
	 * 
	 * @param	Limit		The maximum number of scores to retrieve. Leave null to retrieve only this user's scores.
	 * @param	?CallBack	An optional callback function.
	 */
	public static function getHighscores( ?Limit:Int, ?Callback:Dynamic ):Void
	{
		var tempURL = URL_API + "scores/" + URL_RETURN_TYPE;
		
		if ( Limit != null ) {
			tempURL += URL_GAME_ID + _gameID + "&limit=" + Limit;
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
		
		if ( Callback != null && _callBack == null ) {
			_callBack = Callback;
		}
		
		var loader = new URLLoader();
		
		loader.addEventListener( Event.COMPLETE, parseData );
		
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
	private static function authorizeUser( Callback:Bool -> Void ):Void  
	{
		_callBack = Callback;
		sendLoaderRequest( URL_API + URL_USERS + URL_USER_AUTH + URL_RETURN_TYPE + _idURL, authorizationCheck );
	}
	
	/**
	 * Internal function to evaluate whether or not a user was successfully authorized and store the result in _initialized.
	 */
	private static function authorizationCheck( map:Map<String,String> ):Void
	{
		if ( map.exists( "success" ) ) {
			if ( data.get( "success" ) == "true" ) {
				_initialized = true;
				_callBack( true );
			} else {
				_callBack( false );
			}
		}
	}
	
	/**
	 * Generate a valid MD5 hash signature, required by the API to verify game data is valid.
	 * 
	 * @param	Url		The URL to encrypt. This, along with the private key, form the string which is encoded.
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
	
	/**
	 * An alternative to running init() and hoping for the best; this will tell you if your game was run via Quick Play, and user name and token is available. Does NOT verify the user data!
	 *
	 * @return	True if this was run via Quick Play with user name and token available, false otherwise.
	 */
	public static function isQuickPlay():Bool
	{
		#if !desktop
		return false;
		#else
		var argmap:Map < String, String > = new Map < String, String > { };
		
		for ( arg in Sys.args() ) {
			var argArray = arg.split( "=" );
			argmap.set( argArray[0], argArray[1] );
		}
		
		if ( argmap.exists( "gjapi_username" ) && argmap.exists( "gjapi_token" ) ) {
			return true;
		} else {
			return false;
		}
		#end
	}
	
	/**
	 * An alternative to running init() and hoping for the best; this will tell you if your game was run as an embedded Flash on GameJolt that has user name and token data already. Does NOT verify the user data!
	 *
	 * @return	True if it's an embedded flash with user name and token available, false otherwise.
	 */
	public static function isEmbeddedFlash():Bool
	{
		#if !flash
		return false;
		#else
		var parameters = Lib.current.loaderInfo.parameters;
		
		if ( parameters.gjapi_username != null && parameters.gjapi_token != null ) {
			return true;
		} else {
			return false;
		}
		#end
	}
}