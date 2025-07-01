import Toybox.AntPlus;
import Toybox.System;
import Toybox.Lang;
class AShiftingListener extends AntPlus.ShiftingListener {
  private var _instance as Lang.WeakReference;
  // private var _onShiftingUpdate as Lang.Method;
  private var _onBatteryStatusUpdate as Lang.Method;

  function initialize(instance as Lang.WeakReference, cbOnBatteryStatusUpdate as Symbol) {
    ShiftingListener.initialize();
    _instance = instance;
    // _onShiftingUpdate = new Lang.Method(_instance.get(), cbOnShiftingUpdate) as Method;
    _onBatteryStatusUpdate = new Lang.Method(_instance.get(), cbOnBatteryStatusUpdate) as Method;
  }

  // function  onShiftingUpdate(data as AntPlus.ShiftingStatus) as Void {
  // 
  // }
  
  function onBatteryStatusUpdate(data as AntPlus.BatteryStatus) as Void {
      // if (data == null) { return; }
      _onBatteryStatusUpdate.invoke(data.batteryStatus, data.operatingTime, data.batteryVoltage);
  }
}
