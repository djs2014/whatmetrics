import Toybox.AntPlus;
import Toybox.System;
import Toybox.Lang;
class AShiftingListener extends AntPlus.ShiftingListener {
  private var _callbackTargetRef as WeakReference?;
  private var _onBatteryStatusUpdate as Symbol?;

  function initialize(target as Object, cbOnBatteryStatusUpdate as Symbol) {
    ShiftingListener.initialize();
    _callbackTargetRef = target.weak();
    _onBatteryStatusUpdate = cbOnBatteryStatusUpdate;
  }

  // function  onShiftingUpdate(data as AntPlus.ShiftingStatus) as Void {
  //
  // }

  function onBatteryStatusUpdate(data as AntPlus.BatteryStatus) as Void {
    // if (data == null) { return; }
    if (_callbackTargetRef != null && _callbackTargetRef.stillAlive()) {
      var target = _callbackTargetRef.get();

      if (target != null && _onBatteryStatusUpdate != null) {
        // Dynamically look up the method on the live parent object
        var callback = target.method(_onBatteryStatusUpdate);

        // Invoke the method and pass your data array/primitive
        callback.invoke(
          data.batteryStatus,
          data.operatingTime,
          data.batteryVoltage
        );
      }
    }
  }
}
