package net.loosash.share_platform_plugin

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewTreeObserver
import android.widget.TextView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView

class AndroidTextView(context: Context,
                      messenger: BinaryMessenger,
                      id: Int?,
                      params: Map<String, Any>?) : PlatformView {

    private val mAndroidTextView: TextView = TextView(context)

    init {
        val text = params?.get("text") as CharSequence?

        mAndroidTextView.text = if (text == null) {
            text
        } else {
            "android端TextView"
        }

        mAndroidTextView.textSize = 30f
        mAndroidTextView.setTextColor(Color.parseColor("#000000"))
        mAndroidTextView.gravity = Gravity.CENTER
        mAndroidTextView.viewTreeObserver.addOnGlobalLayoutListener{
            Log.e("xx","parent:"+mAndroidTextView.parent.javaClass.name)

        }
    }

    override fun getView(): View = mAndroidTextView

    override fun dispose() {

    }

}