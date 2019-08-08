import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_platform_plugin/widget/platform_text_widget.dart';

class TextPage extends StatelessWidget {
  Widget _buildNative() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      print("defaultTargetPlatform$defaultTargetPlatform");
      return AndroidView(
        viewType: "platform_text_view",
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print("defaultTargetPlatform$defaultTargetPlatform");
      return UiKitView(
        viewType: "platform_text_view",
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      return Text("不支持的平台");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("native text"),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Text("这里是flutter的Text"),
            Expanded(
              child: PlatformTextWidget(text:"123"),
            ),
            Text("这里是flutter的Text"),
          ],
        ),
      ),
    );
  }
}
