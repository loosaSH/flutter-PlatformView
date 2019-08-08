package net.loosash.share_platform_plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class SharePlatformPlugin: MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "share_platform_plugin")
      channel.setMethodCallHandler(SharePlatformPlugin())
      // 添加注册我们创建的 view ，注意这里的 withId 需要和 flutter 侧的值相同
      registrar.platformViewRegistry().registerViewFactory("platform_text_view", SharePlatformViewFactory(registrar.messenger()))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }
}
