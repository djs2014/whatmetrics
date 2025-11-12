// 2024-05-26 setLocation lat/lon toDouble
// 2025-11-10 location changed fix
// 2025-11-11 do not cache sunrise/set
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

class CurrentLocation {
  hidden var mLat as Lang.Double = 0.0d;
  hidden var mLon as Lang.Double = 0.0d;
  hidden var mLocation as Location?;
  hidden var mStorageLatestLocation as String = "latest_latlng";

  hidden function setLocation(location as Location?) as Void {
    if (location == null) {
      return;
    }
    mLocation = location;
    var degrees = (mLocation as Location).toDegrees();
    if (degrees.size() < 2) {
      return;
    }
    var lat = degrees[0].toDouble();
    var lon = degrees[1].toDouble();
    if (lat == null || lon == null) {
      return;
    }
    if (lat != 0 && lon != 0 && mLat != lat && mLon != lon) {
      Storage.setValue(mStorageLatestLocation, degrees); // [lat,lng]
      System.println("Update cached location lat/lon: " + degrees);
    }
    mLat = lat;
    mLon = lon;
  }

  hidden var mAccuracy as Quality? = Position.QUALITY_NOT_AVAILABLE;

  hidden var methodLocationChanged as Method?;
  function setOnLocationChanged(
    objInstance as Object?,
    callback as Symbol
  ) as Void {
    methodLocationChanged = new Lang.Method(objInstance, callback) as Method;
  }

  // Sunrise sunset changed @@TODO
  // var methodSunEventChanged as Method?;
  // function setOnSunEventChanged(
  //   objInstance as Object?,
  //   callback as Symbol
  // ) as Void {
  //   methodSunEventChanged = new Lang.Method(objInstance, callback) as Method;
  // }

  function initialize() {}

  function hasLocation() as Boolean {
    if (
      (mLat == 0.0 || mLat >= 179.99 || mLat <= -179.99) &&
      (mLon == 0.0 || mLon >= 179.99 || mLon <= -179.99)
    ) {
      var degrees = Storage.getValue(mStorageLatestLocation);
      if (degrees != null) {
        mLat = (degrees as Array)[0] as Double;
        mLon = (degrees as Array)[1] as Double;
        mAccuracy = Position.QUALITY_LAST_KNOWN;
        System.println(
          "Using cached location lat/lon: " +
            [mLat, mLon] +
            " accuracy: " +
            mAccuracy
        );
      }
    }

    if (
      (mLat == 0.0 || mLat >= 179.99 || mLat <= -179.99) &&
      (mLon == 0.0 || mLon >= 179.99 || mLon <= -179.99)
    ) {
      //System.println("Invalid location lat/lon: " + [mLat, mLon] + " accuracy: " + mAccuracy);
      return false;
    }

    return true; //mLat != 0.0 && mLon != 0.0;
  }

  function getCurrentDegrees() as Array<Double> {
    if (!hasLocation()) {
      return [0.0d, 0.0d] as Array<Double>;
    }
    return [mLat, mLon] as Array<Double>;
  }

  function infoLocation() as String {
    if (!hasLocation()) {
      return "No location";
    }
    return mLat.format("%2.4f") + "," + mLon.format("%2.4f");
  }

  function getAccuracy() as Quality {
    if (mAccuracy == null) {
      return Position.QUALITY_NOT_AVAILABLE;
    }
    return mAccuracy as Quality;
  }

  function infoAccuracy() as String {
    if (mAccuracy == null) {
      return "Not available";
    }

    switch (mAccuracy as Quality) {
      case 0:
        return "Not available";
      case 1:
        return "Last known";
      case 2:
        return "Poor";
      case 3:
        return "Usable";
      case 4:
        return "Good";
      default:
        return "Not available";
    }
  }

  function onCompute(info as Activity.Info) as Void {
    try {
      var location = null;
      mAccuracy = Position.QUALITY_NOT_AVAILABLE;

      if (info has :currentLocation && info.currentLocation != null) {
        location = info.currentLocation as Location;
        if (
          info has :currentLocationAccuracy &&
          info.currentLocationAccuracy != null
        ) {
          mAccuracy = info.currentLocationAccuracy;
        }
        if (locationChanged(location)) {
          System.println(
            "Activity location lat/lon: " +
              location.toDegrees() +
              " accuracy: " +
              mAccuracy
          );
          // setSunRiseAndSunSet(location);
          onLocationChanged();
        }
      }

      if (location == null) {
        var posnInfo = Position.getInfo();
        if (posnInfo has :position && posnInfo.position != null) {
          location = posnInfo.position as Location;
          if (posnInfo has :accuracy && posnInfo.accuracy != null) {
            mAccuracy = posnInfo.accuracy;
          }
          if (locationChanged(location)) {
            System.println(
              "Position location lat/lon: " +
                location.toDegrees() +
                " accuracy: " +
                mAccuracy
            );
            // setSunRiseAndSunSet(location);
            onLocationChanged();
          }
        }
      }
      if (location != null && validLocation(location)) {
        setLocation(location);
      } else if (mLocation != null) {
        mAccuracy = Position.QUALITY_LAST_KNOWN;
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  hidden function onLocationChanged() as Void {
    if (methodLocationChanged == null) {
      return;
    }
    (methodLocationChanged as Method).invoke(
      getCurrentDegrees() as Array<Double>
    );
  }

  hidden function locationChanged(location as Location?) as Boolean {
    // Ignore invalid locations
    if (location == null) {
      return false;
    }

    var newLocation = location as Location;
    if (!validLocation(newLocation)) {
      // System.println(["New location is invalid", newLocation.toDegrees()]);
      return false;
    }

    // This will crash the compiler when on strict level
    // if (mLocation == null && location == null ){ return false; }
    // if ( (mLocation != null && location == null) || (mLocation == null && location != null) ){ return true; }

    // No current location, so new is better.
    if (mLocation == null) {
      return true;
    }
    var currentLocation = mLocation as Location;
    var currentDegrees = currentLocation.toDegrees();

    var newDegrees = newLocation.toDegrees();
    return (
      newDegrees[0] != currentDegrees[0] && newDegrees[1] != currentDegrees[1]
    );
  }

  hidden function validLocation(location as Location?) as Boolean {
    if (location == null) {
      return false;
    }
    var degrees = (location as Location).toDegrees();

    if (
      (degrees[0] >= 179.99 || degrees[0] <= -179.99) &&
      (degrees[1] >= 179.99 || degrees[1] <= -179.99)
    ) {
      System.println(
        "Invalid location lat/lon: " + degrees + " accuracy: " + mAccuracy
      );
      return false;
    }
    return true;
  }

  // Gives sunrise and sunset for current day.
  // hidden function setSunRiseAndSunSet(location as Location?) as Void {
  //   if (location == null) {
  //     return;
  //   }

  //   // Note: is sunrise of current day. So will return date before now() if the sun has rised already. Same for sunset.
  //   mSunrise = Weather.getSunrise(location as Location, Time.now()); // ex: 13-6-2022 05:20:43
  //   mSunset = Weather.getSunset(location as Location, Time.now()); // ex: 13-6-2022 22:02:25

  //   // Sunrise tomorrow
  //   var today = new Time.Moment(Time.today().value());
  //   var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
  //   var tomorrow = today.add(oneDay);
  //   mSunriseTomorrow = Weather.getSunrise(location as Location, tomorrow); // ex: 14-6-2022 05:20:43
  //   mSunsetTomorrow = Weather.getSunset(location as Location, tomorrow); // ex: 14-6-2022 05:20:43
  //   System.println(
  //     "Sunrise: " +
  //       $.getLongTimeString(mSunrise) +
  //       " Sunset: " +
  //       $.getLongTimeString(mSunset) +
  //       "Sunrise Tomorrow: " +
  //       $.getLongTimeString(mSunriseTomorrow)
  //   );
  // }

  function isAtDaylightTime(time as Moment?, defValue as Boolean) as Boolean {
    if (!validLocation(mLocation)) {
      return defValue;
    }

    if (time == null) {
      return defValue;
    }

    // Note: is sunrise of current day (from time parameter).
    var sunrise = Weather.getSunrise(mLocation as Location, time); // ex: 13-6-2022 05:20:43
    var sunset = Weather.getSunset(mLocation as Location, time); // ex: 13-6-2022 22:02:25

    var dayLightTime =
      (sunrise as Moment).value() <= (time as Moment).value() &&
      (time as Moment).value() <= (sunset as Moment).value();
    System.println([
      "IsDayLight:",
      dayLightTime.toString(),
      "Sunrise:",
      $.getLongTimeString(sunrise),
      " sunset:",
      $.getLongTimeString(sunset),
      " when:",
      $.getLongTimeString(time),
    ]);

    return dayLightTime;
  }

  function isAtNightTime(time as Moment?, defValue as Boolean) as Boolean {
    if (!validLocation(mLocation)) {
      return defValue;
    }

    if (time == null) {
      return defValue;
    }

    // Note: is sunrise of current day (from time parameter).
    var sunrise = Weather.getSunrise(mLocation as Location, time); // ex: 13-6-2022 05:20:43
    var sunset = Weather.getSunset(mLocation as Location, time); // ex: 13-6-2022 22:02:25

var nightTime =
      (time as Moment).value() < (sunrise as Moment).value() ||
      (sunset as Moment).value() <= (time as Moment).value();

    System.println([
      "IsAtNight:",
      nightTime.toString(),
      "Sunrise:",
      $.getLongTimeString(sunrise),
      " sunset:",
      $.getLongTimeString(sunset),
      " when:",
      $.getLongTimeString(time),
    ]);

    return nightTime;
  }

  // Note: is sunrise of current day. So will return date before now() if the sun has rised already.
  function getSunrise() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    return Weather.getSunrise(mLocation as Location, Time.now());
  }
  // Note: is sunrise of current day. So will return date before now() if the sun has rised already.
  function getSunset() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    return Weather.getSunset(mLocation as Location, Time.now());
  }

  function getSunriseTomorrow() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    var today = new Time.Moment(Time.today().value());
    var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
    var tomorrow = today.add(oneDay);
    return Weather.getSunrise(mLocation as Location, tomorrow); // ex: 14-6-2022 05:20:43
  }
  function getSunsetTomorrow() as Moment? {
    if (!validLocation(mLocation)) {
      return null;
    }
    var today = new Time.Moment(Time.today().value());
    var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
    var tomorrow = today.add(oneDay);
    return Weather.getSunset(mLocation as Location, tomorrow); // ex: 14-6-2022 05:20:43
  }

  function getRelativeToObservation(
    latObservation as Double,
    lonObservation as Double
  ) as String {
    if (!hasLocation() || latObservation == 0.0 || lonObservation == 0.0) {
      return "";
    }

    var currentLocation = mLocation as Location;
    var degrees = currentLocation.toDegrees();
    var latCurrent = degrees[0];
    var lonCurrent = degrees[1];

    var distanceMetric = "km";
    var distance = $.getDistanceFromLatLonInKm(
      latCurrent,
      lonCurrent,
      latObservation,
      lonObservation
    );

    var deviceSettings = System.getDeviceSettings();
    if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
      distance = $.kilometerToMile(distance);
      distanceMetric = "m";
    }
    var bearing = $.getRhumbLineBearing(
      latCurrent,
      lonCurrent,
      latObservation,
      lonObservation
    );
    var compassDirection = $.getCompassDirection(bearing);

    return format("$1$ $2$ ($3$)", [
      distance.format("%.2f"),
      distanceMetric,
      compassDirection,
    ]);
  }
}
