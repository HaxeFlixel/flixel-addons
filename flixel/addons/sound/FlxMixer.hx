package flixel.addons.sound;

import flixel.FlxBasic;
import flixel.sound.FlxSound;
import openfl.errors.Error;

typedef FlxPlaybackSettings =
{
    var loop:Bool;
    var pitch:Float;
}

@:allow(flixel.addons.sound.FlxMixer)
private class FlxMixerChannel
{
    var volume:Float = 1;
    var pitch:Float = 1;
    var loop:Bool = false;
    
    var _tags:Array<String> = new Array<String>();
    
    var _sounds:Map<String, FlxSound> = new Map<String, FlxSound>();
    
    public function new() {}
    
    function _play() {}
}

/**
 * This is adds the Unity Mixer Component behaviour inside Flixel
 */
class FlxMixer extends FlxBasic
{
    var _soundAssets:Map<String, FlxSound>;
    
    var _channels:Map<String, FlxMixerChannel>;
    
    public var masterVolume:Float = 1;
    
    var _maxSounds:Int = 4;
    
    var _soundsCount:Int = 0;
    
    var _channelsCount:Int = 0;
    
    /**
     * Creates a new mixer object
     * @param maxSounds = 4 
     */
    public function new(?maxSounds:Int = 4)
    {
        super();
        this._maxSounds = maxSounds;
        this._soundAssets = new Map<String, FlxSound>();
        this._channels = new Map<String, FlxMixerChannel>();
    }
    
    /// This update is used only to update the channels and its behaviours ///
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        // updates and clean ups //
        
        for (channelName => channel in this._channels)
        {
            for (tag => sound in channel._sounds)
            {
                sound.volume = this.masterVolume * channel.volume;
                sound.pitch = channel.pitch;
                sound.looped = channel.loop;
                
                if (!sound.playing && !sound.looped)
                    channel._sounds.remove(tag);
            }
        }
    }
    
    public function addSound(tag:String, sound:FlxSound)
    {
        this._soundsCount++;
        
        if (this._soundsCount > this._maxSounds)
            throw new Error('The mixer reached the max allowed source count. maxSounds = ${this._maxSounds}!');
            
        if (tag == null)
            tag = "Snd_" + this._soundsCount;
            
        this._soundAssets.set(tag, sound);
    }
    
    public function addChannel(channelName:String)
    {
        if (this._channels.exists(channelName))
            return;
            
        this._channelsCount++;
        
        if (channelName == null)
            channelName = "Chn_" + this._channelsCount;
            
        var channel:FlxMixerChannel = new FlxMixerChannel();
        this._channels.set(channelName, channel);
    }
    
    public function playChannel(channelName:String, tag:String, ?playbackSettings:FlxPlaybackSettings)
    {
        if (!this._channels.exists(channelName))
            return;
            
        if (!this._soundAssets.exists(tag))
            return;
            
        var channel:FlxMixerChannel = this._channels.get(channelName);
        // add the sound to the channel //
        var sound = this._soundAssets.get(tag);
        channel._sounds.set(tag, sound);
        
        if (playbackSettings != null)
        {
            channel.pitch = playbackSettings.pitch;
            channel.loop = playbackSettings.loop;
        }
        else
        {
            channel.pitch = 1;
            channel.loop = false;
        }
        
        sound.play();
    }
    
    public function stopChannel() {}
    
    public function setChannelVolume(channelName:String, vol:Float)
    {
        var channel:FlxMixerChannel = this._channels.get(channelName);
        channel.volume = vol;
    }
    
    public function getChannelVolume(channelName:String):Float
    {
        var channel:FlxMixerChannel = this._channels.get(channelName);
        return channel.volume;
    }
}
