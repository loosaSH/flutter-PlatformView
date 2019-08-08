package net.loosash.share_platform_plugin

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class SharePlatformViewFactory(private val messenger: BinaryMessenger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val params = args?.let { args as Map<String, Any> }
        return AndroidTextView(context, messenger, id, params)

    }
}