import Toybox.AntPlus;
import Toybox.System;
import Toybox.Lang;

class ABikePowerListener extends AntPlus.BikePowerListener {
  private var _callbackTargetRef as Lang.WeakReference?;
  private var _onPedalPowerBalanceUpdate as Symbol?;
  private var _onBatteryStatusUpdate as Symbol?;

  function initialize(
    powerBalance as PowerBalance,
    cbOnPedalPowerBalanceUpdate as Symbol,
    cbOnBatteryStatusUpdate as Symbol
  ) {
    BikePowerListener.initialize();

    _callbackTargetRef = powerBalance.weak();
    _onPedalPowerBalanceUpdate = cbOnPedalPowerBalanceUpdate;
    _onBatteryStatusUpdate = cbOnBatteryStatusUpdate;
  }

  function onPedalPowerBalanceUpdate(
    data as AntPlus.PedalPowerBalance
  ) as Void {
    if (data.rightPedalIndicator == null) {
      return;
    }
    if (data.pedalPowerPercent == null) {
      return;
    }

    if (_callbackTargetRef != null && _callbackTargetRef.stillAlive()) {
      var target = _callbackTargetRef.get();

      if (target != null && _onPedalPowerBalanceUpdate != null) {
        var callback = target.method(_onPedalPowerBalanceUpdate);

        callback.invoke(
          data.pedalPowerPercent as Lang.Number or null,
          data.rightPedalIndicator as Lang.Boolean or null
        );
      }
    }
  }

  function onBatteryStatusUpdate(data as AntPlus.BatteryStatus) as Void {
    // if (data == null) { return; }
    if (_callbackTargetRef != null && _callbackTargetRef.stillAlive()) {
      var target = _callbackTargetRef.get();

      if (target != null && _onBatteryStatusUpdate != null) {
        var callback = target.method(_onBatteryStatusUpdate);

        callback.invoke(
          data.batteryStatus as BatteryStatusValue or null,
          data.operatingTime as Lang.Number or null,
          data.batteryVoltage as Lang.Float or null
        );
      }
    }
  }
}
