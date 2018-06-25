package flixel.addons.effects;

import flixel.math.FlxAngle;
import flixel.FlxSprite;

typedef OrbitOptions = {
    distance:Float,
    startAngle:Float,
    speed:Float,
    ?parametric:FlxParametric,
}

/**
 * Binds orbital `FlxSprite` to another `FlxSprite`.
 * Trajectory is determined by `FlxParametric` equation.
 *
 * @author Jed Cua
**/
class FlxOrbit extends FlxBasic
{
    /**
     * Parametric equation.
    **/
    private var _parametric:FlxParametric;

    /**
     * `FlxSprite` that orbits.
    **/
    private var _orbitSprite:FlxSprite;

    /**
     * `FlxSprite` to track.
    **/
    private var _trackSprite:FlxSprite;

    /**
     * Radial distance from `orbitSprite` to `spriteTrack`.
    **/
    private var _distance:Float;

    /**
     * Current orbit angle (in degrees).
    **/
    public var orbitAngle:Float;

    /**
     * Orbiting speed, in clockwise direction.
     * Use negative values for counterclockwise direction.
    **/
    public var orbitSpeed:Float;

    public function new(OrbitSprite:FlxSprite, TrackSprite:FlxSprite, OrbitOptions:OrbitOptions)
    {
        super();

        this._orbitSprite = OrbitSprite;
        this._trackSprite = TrackSprite;

        this._distance = OrbitOptions.distance;
        this.orbitAngle = OrbitOptions.startAngle;
        this.orbitSpeed = OrbitOptions.speed;

        if (OrbitOptions.parametric == null)
            this._parametric = new FlxParametric();
        else
            this._parametric = OrbitOptions.parametric;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        updateOrbit();

        this.orbitAngle += this.orbitSpeed * elapsed;
        this.orbitAngle = this.orbitAngle % 360;
    }

    private inline function updateOrbit()
    {
        var xOffset = this._parametric.xValue(this.orbitAngle, this._distance);
        var yOffset = this._parametric.yValue(this.orbitAngle, this._distance);

        this._orbitSprite.x = this._trackSprite.getMidpoint().x - (this._orbitSprite.width / 2) + xOffset;
        this._orbitSprite.y = this._trackSprite.getMidpoint().y - (this._orbitSprite.height / 2) + yOffset;
    }
}

/**
 * Parametric equation used to express `x` and `y` coordinates.
 * The methods `xValue()` and `yValue()` can be overriden.
 *
 * @author Jed Cua
**/
class FlxParametric
{
    private var _xOffset:Float;
    private var _xCoefficient:Float;
    private var _yOffset:Float;
    private var _yCoefficient:Float;

    public function new(xOffset:Float=0, xCoefficient:Float=1, yOffset:Float=0, yCoefficient:Float=1)
    {
        this._xOffset = xOffset;
        this._xCoefficient = xCoefficient;
        this._yOffset = yOffset;
        this._yCoefficient = yCoefficient;
    }

    /**
     * Parametric equation for x.
     * @param   angle      Angle in degrees
     * @param   distance   Distance parameter
     * @return  X coordinate
    **/
    public function xValue(angle:Float, distance:Float)
    {
        return this._xCoefficient * distance * Math.cos(FlxAngle.asRadians(angle + this._xOffset));
    }

    /**
     * Parametric equation for y.
     * @param   angle      Angle in degrees
     * @param   distance   Distance parameter
     * @return  Y coordinate
    **/
    public function yValue(angle:Float, distance:Float)
    {
        return this._yCoefficient * distance * Math.sin(FlxAngle.asRadians(angle + this._yOffset));
    }
}
