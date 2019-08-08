# Flutter Platform View

## 什么是 platform view？

由于 Flutter 诞生于 Android 、iOS非常成熟的时代背景，为了能让一些现有的 native 控件直接引用到 Flutter app 中，Flutter 团队提供了 AndroidView 、UIKitView 两个 widget 来满足需求，比如说 Flutter 中的 Webview、MapView，暂时无需使用 Flutter 重新开发一套。

其实 platform view 就是 AndroidView 和 UIKitView 的总称，允许将 native view 嵌入到了 flutter widget 体系中，完成 Datr 代码对 native view 的控制。

## 简单使用

*此处仅是简单使用，有很多不合理的代码，目的仅是让初学者能完成展示，后面会有具体的 framework 代码分析，及官方维护的 platform view 的分析。*

先看一下效果吧

![](http://p0.qhimg.com/t013d5e6465486ce0e6.png)

![](http://p0.qhimg.com/t012a61a67eb82cab12.png)

存在与 native 交互的代码，建议用一个 plugin 来实现内部逻辑。

> Plugin: exposing an Android or iOS API for developers

### Flutter 侧

创建 Flutter plugin （建议使用 Android Studio），如果使用命令行，可以执行如下命令：

```bash
flutter create --org net.loosash --template = plugin share_platform_plugin
```

接下来在我们的插件工程里创建一个 widget 用来包裹 platform view。便于使用

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 这里使用了 statelessWidget
class PlatformTextWidget extends StatelessWidget {
  PlatformTextWidget({this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // 根据运行平台判断执行代码
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        // 在 native 中的唯一标识符，需要与 native 侧的值相同
        viewType: "platform_text_view",
        // 在创建 AndroidView 的同时，可以传递参数
        creationParams: <String, dynamic>{"text": text},
        // 用来编码 creationParams 的形式，可选 [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec]
        // 如果存在 creationParams，则该值不能为null
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: "platform_text_view",
        creationParams: <String, dynamic>{"text": text},
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return Text("不支持的平台");
    }
  }
}
```

### iOS 侧

在编辑Xcode中的iOS平台代码之前，首先确保代码至少已构建过一次。在创建的 plugin/example 目录下执行 build，如下：

```bash
cd share_platform_plugin/example
flutter build ios --no-codesign
或者执行 pod install
```

然后使用 Xcode 打开 share_platform_plugin/example/ios/Runner.xcworkspace，plugin 相关的代码目录很深，在 Pods/Development Pods/share_platform_plugin 内部，具体找到 SharePlatformPlugin.h 与 SharePlatformPlugin.m 目录即位我们操作的目录。

接下来我们先创建需要展示的 View ，这里仅以一个 UILabel 为例。

IOSTextView.h

```objective-c
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOSTextView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
                   viewIdentifier:(int64_t)viewId
                        arguments:(id _Nullable)args
                  binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

NS_ASSUME_NONNULL_END
```

IOSTextView.m

```objective-c
#import <Foundation/Foundation.h>
#import "IOSTextView.h"

@implementation IOSTextView{
    int64_t _viewId;
    FlutterMethodChannel* _channel;
    UILabel * _uiLable;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    
    _uiLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _uiLable.textAlignment = NSTextAlignmentCenter;
    _uiLable.text = @"ios端UILabel";
    _uiLable.font = [UIFont systemFontOfSize:16];
    _uiLable.textColor = [UIColor redColor];
    return self;
}

-(UIView *)view{
    return _uiLable;
}

@end
```

然后创建 FlutterPlatformViewFactory

SharePlatformViewFactory.h

```objective-c
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SharePlatformViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messager;

-(NSObject<FlutterMessageCodec> *)createArgsCodec;

-(NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args;

@end
NS_ASSUME_NONNULL_END
```

SharePlatformViewFactory.m

```objective-c
#import "SharePlatformViewFactory.h"
#import "IOSTextView.h"

@implementation SharePlatformViewFactory{
    NSObject<FlutterBinaryMessenger>*_messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager{
    self = [super init];
    if (self) {
        _messenger = messager;
    }
    return self;
}

-(NSObject<FlutterMessageCodec> *)createArgsCodec{
    return [FlutterStandardMessageCodec sharedInstance];
}

-(NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args{
    IOSTextView *iosTextView = [[IOSTextView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
    return iosTextView;
}

@end
```

接下来在 SharePlatformPlugin.m 中添加我们创建 SharePlatformViewFactory 的注册。

```objective-c
#import "SharePlatformPlugin.h"
#import "SharePlatformViewFactory.h"

@implementation SharePlatformPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"share_platform_plugin"
            binaryMessenger:[registrar messenger]];
  SharePlatformPlugin* instance = [[SharePlatformPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    // 添加注册我们创建的 view ，注意这里的 withId 需要和 flutter 侧的值相同
    [registrar registerViewFactory:[[SharePlatformViewFactory alloc] initWithMessenger:registrar.messenger] withId:@"platform_text_view"];

}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
```

最后，还需要在 Flutte 项目中的 ios/Runner/info.plist 中增加，就是运行 flutter 的项目

```
    <key>io.flutter.embedded_views_preview</key>
    <true/>
```

iOS侧就完成了。

### Android 侧

直接使用 Android Studio 打开 plugin 中的 android 目录，share_platform_plugin/android

接下来我们先创建需要展示的 View ，这里仅以一个 TextView 为例。

AndroidTextView.kt

```kotlin
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
    }
    override fun getView(): View = mAndroidTextView
    override fun dispose() {}
}
```

创建 SharePlatformViewFactory.kt

```kotlin
class SharePlatformViewFactory(private val messenger: BinaryMessenger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val params = args?.let { args as Map<String, Any> }
        return AndroidTextView(context, messenger, id, params)

    }
}
```

最后，在 SharePlatformPlugin 中添加我们创建 SharePlatformViewFactory 的注册。

```kotlin
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
```

这样 Andorid 侧的代码就完成了。

### Flutter项目中的使用

在 Flutter 工程中 pubspec.yaml 引入该 plugin 。

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^0.1.2
  # 下面是对我们新建插件的依赖
  share_platform_plugin:
    path: ../share_platform_plugin
```

执行 Packages get

```bash
flutter package get
```

在需要展示的地方和正常的 widget 一样使用我们自己创建的 PlatformTextWidget

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_platform_plugin/widget/platform_text_widget.dart';

class TextPage extends StatelessWidget {

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
```

## 发现问题

如果上面的代码你自己写一遍，你就会发现存在很多的问题。

1. id 在对应的端上没有被使用，可以用来做什么？
2. 这里的 PlatformTextWidget 被 Expanded 包裹着，如果不包裹就会出现超出边界的错误，那么这个 Widget 的大小是怎么控制的呢？
3. platform view 的绘制是在 native 侧完成的还是在 flutter 侧完成的呢？

带着问题，我们看一遍源码，看看是否能找到相关的答案。

## 源码分析

先来看看 AndroidView 吧

```dart
// 继承了 StatefulWidget
class AndroidView extends StatefulWidget {
  const AndroidView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.gestureRecognizers,
    this.creationParams,
    this.creationParamsCodec,
  }) : assert(viewType != null),
       assert(hitTestBehavior != null),
       assert(creationParams == null || creationParamsCodec != null),
       super(key: key);

  /// 嵌入Android视图类型的唯一标识符 
  final String viewType;

  /// platform view 创建完成的回调
  final PlatformViewCreatedCallback onPlatformViewCreated;

	/// hit测试期间的行为
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// 视图的文本方向
  final TextDirection layoutDirection;
  
  /// 用于处理事件冲突，对事件进行分发管理相关操作
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// 传给 Android 视图的参数，在 Android 视图构造的时候使用
  final dynamic creationParams;

  /// 对 creationParams 参数传递时进行的编码规则，如果 creationParams 不为 null，该值必须不为 null
  final MessageCodec<dynamic> creationParamsCodec;

  @override
  State<AndroidView> createState() => _AndroidViewState();
}
```

有一些需要注意的点

- AndroidView 仅支持 Android API 20 及以上；
- 在Flutter 中使用 AndroidView 对性能的开销比较大，应该尽可能的避免使用；
- 可以把它当作一个 Flutter 的 wedget 一样的使用。

接下来我们看一下这个 State 对象，关于生命周期的知识，这里给出链接：

> Flutter State的生命周期<br>[https://www.jianshu.com/p/f39cf2f7ad78](https://www.jianshu.com/p/f39cf2f7ad78)

```dart
class _AndroidViewState extends State<AndroidView> {
  // 用于区分不同的 View 来接收不同的操作指令，可以说不同的 id 代表着不同的 view
  // 在_createNewAndroidView方法中被赋值
  // 触发条件：1、在 didChangeDependencies 生命周期中第一次初始化触发
  // 2、didUpdateWidget 生命周期中 传入的viewType 发生改变时触发
  int _id;
  // AndroidView的控制器，和 _id 的赋值场景相同
  AndroidViewController _controller;
  // 布局方向，widget 传入
  TextDirection _layoutDirection;
  // 被初始化的标识，保证_createNewAndroidView()操作以及_focusNode被操作一次
  bool _initialized = false;
  // 获取键盘焦点及事件的相关类
  FocusNode _focusNode;
  // 创建一个空的set集合，如果没有传入gestureRecognizers，则使用该空集合
  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
    <Factory<OneSequenceGestureRecognizer>>{};

  // build 方法，包裹了一层 Focus 用来处理焦点的问题，内部真实使用的是 _AndroidPlatformView，后面单独分析_AndroidPlatformView
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: _AndroidPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
      ),
    );
  }

  // 保证操作仅执行一次
  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewAndroidView();
    _focusNode = FocusNode(debugLabel: 'AndroidView(id: $_id)');
  }

  // didChangeDependencies 生命周期回调
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    // 布局方向调教，是否有改变
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;
    
		// 会多次回调该生命周期，但是保证关键操作仅执行一次
    _initializeOnce();
    // 根据条件判断是否需要重制布局方向
    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  // didUpdateWidget 生命周期回调
  @override
  void didUpdateWidget(AndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    // 根据viewType是否相同来确定是否需要重新创建 AndroidView，生成新的id
    if (widget.viewType != oldWidget.viewType) {
      _controller.dispose();
      _createNewAndroidView();
      return;
    }

    // 布局方向相关
    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  // 回收资源
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 关键的方法，生成 _id 及 _controller,用于传递给_AndroidPlatformView
  void _createNewAndroidView() {
    // 每次对 _id 进行自增，保证唯一性。
    _id = platformViewsRegistry.getNextPlatformViewId();
    // initAndroidView 构造了一个 _controller，将参数端都交给 _controller 保管
    _controller = PlatformViewsService.initAndroidView(
      id: _id,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
      onFocus: () {
        _focusNode.requestFocus();
      }
    );
    // 添加回调，给开发者使用
    if (widget.onPlatformViewCreated != null) {
      _controller.addOnPlatformViewCreatedListener(widget.onPlatformViewCreated);
    }
  }

  // 焦点变更
  void _onFocusChange(bool isFocused) {
    if (!_controller.isCreated) {
      return;
    }
    if (!isFocused) {
      _controller.clearFocus().catchError((dynamic e) {
       if (e is MissingPluginException) {
         return;
       }
      });
      return;
    }
    // 通过 flutter engin 来实实现焦点变更对 native view 的处理
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      _id,
    ).catchError((dynamic e) {
      if (e is MissingPluginException) {
        return;
      }
    });
  }
}
```

**小结一下**：

**我们解决解决了如下问题**：

这里我们发现了 id 的作用，当创建的时候，分配一个 id，在 viewType 改变的时候从新分配，其实就是对应 native 侧创建 view 的时候，所以可以通过 id 来保证每个 widget 对应的 native 不是同一个 view ，解决 view 的区分处理。

**我们又遇到了新的问题**：

AndroidViewController、_AndroidPlatformView都做了什么？



我们先来分析一下 AndroidViewController 会对我们上面的问题和 _AndroidPlatformView 的分析有帮助。

这里会有 Texture 纹理相关的知识，这里不做分析，有兴趣可以查看一下相关文章

> Flutter外接纹理<br>[https://zhuanlan.zhihu.com/p/42566807](https://zhuanlan.zhihu.com/p/42566807)

```dart
// AndroidViewController 是通过 PlatformViewsService.initAndroidView 方法创建的，上面有的分析过程里有
class AndroidViewController {
  AndroidViewController._(
    this.id,
    String viewType,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
    TextDirection layoutDirection,
  ) : assert(id != null),
      assert(viewType != null),
      assert(layoutDirection != null),
      assert(creationParams == null || creationParamsCodec != null),
      _viewType = viewType,
      _creationParams = creationParams,
      _creationParamsCodec = creationParamsCodec,
      _layoutDirection = layoutDirection,
      _state = _AndroidViewState.waitingForSize;


  // 对应了很多 android 中的点击事件 MotionEvent 相关
  // [MotionEvent.ACTION_DOWN]
  static const int kActionDown =  0;
	// [MotionEvent.ACTION_UP]
  static const int kActionUp =  1;
  // [MotionEvent.ACTION_MOVE]
  static const int kActionMove = 2;
  // [MotionEvent.ACTION_CANCEL]
  static const int kActionCancel = 3;
  // [MotionEvent.ACTION_POINTER_DOWN]
  static const int kActionPointerDown =  5;
  // [MotionEvent.ACTION_POINTER_UP]
  static const int kActionPointerUp =  6;
  // 布局方向相关
  // [View.LAYOUT_DIRECTION_LTR]
  static const int kAndroidLayoutDirectionLtr = 0;
  // [View.LAYOUT_DIRECTION_RTL]
  static const int kAndroidLayoutDirectionRtl = 1;

  // 标识 id 上面已经分析过了
  final int id;

  // native 侧注册的 viewType 字段
  final String _viewType;

  // 在创建 andorid 端 view 的时候（下文 _create方法），返回_textureId。
  // 该 id 是在 native 侧渲染完成后绘图数据对应的id，可以直接在GPU中找到并直接使用
  // Flutter 的 Framework 层最后会递交给 Engine 层一个 layerTree ，包含了此处的 _textureId，最终在绘制的时候，skia 会直接在 GPU 中根据 textureId 找到相应的绘制数据，并将其绘制到屏幕上。
  int _textureId;
  // _textureId 的 get 方法
  int get textureId => _textureId;

  TextDirection _layoutDirection;

  // 枚举状态
  _AndroidViewState _state;

  // 参数
  dynamic _creationParams;

  // 编码类
  MessageCodec<dynamic> _creationParamsCodec;

  // 回调集合
  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks = <PlatformViewCreatedCallback>[];

  /// 获取 view 的 create 状态
  bool get isCreated => _state == _AndroidViewState.created;

  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(listener != null);
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  void removeOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  // Disposes the Android view.
  // 通过 engine 调用了 native 的 dispose 方法、清空回调集合、disposed 当前 widget 的 state
  Future<void> dispose() async {
    if (_state == _AndroidViewState.creating || _state == _AndroidViewState.created)
      await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
    _platformViewCreatedCallbacks.clear();
    _state = _AndroidViewState.disposed;
  }

  // 设置 Android View 的大小，通过 engine 调用了 native 的 resize 方法
  Future<void> setSize(Size size) async {
    assert(_state != _AndroidViewState.disposed, 'trying to size a disposed Android View. View id: $id');

    assert(size != null);
    assert(!size.isEmpty);

    if (_state == _AndroidViewState.waitingForSize)
      return _create(size);

    await SystemChannels.platform_views.invokeMethod<void>('resize', <String, dynamic>{
      'id': id,
      'width': size.width,
      'height': size.height,
    });
  }

  // 通过 engine 调用了 native 的 setDirection 方法，设置 Android view 方向
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(_state != _AndroidViewState.disposed,'trying to set a layout direction for a disposed UIView. View id: $id');

    if (layoutDirection == _layoutDirection)
      return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;

    if (_state == _AndroidViewState.waitingForSize)
      return;

    await SystemChannels.platform_views.invokeMethod<void>('setDirection', <String, dynamic>{
      'id': id,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  // 通过 engine 调用了 native 的 clearFocus 方法，清除焦点
  Future<void> clearFocus() {
    if (_state != _AndroidViewState.created) {
      return null;
    }
    return SystemChannels.platform_views.invokeMethod<void>('clearFocus', id);
  }

  // 获得布局方向
  static int _getAndroidDirection(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.ltr:
        return kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return kAndroidLayoutDirectionRtl;
    }
    return null;
  }

  // 通过 engine 调用 native 的 touch 方法，将事件发送给 android view 处理
  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SystemChannels.platform_views.invokeMethod<dynamic>(
        'touch',
        event._asList(id),
    );
  }

  /// Creates a masked Android MotionEvent action value for an indexed pointer.
  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  // 真正创建 view 的方法，也是通过 engine 调用 native 的 create 方法，传入了 width 和 height
  Future<void> _create(Size size) async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': _viewType,
      'width': size.width,
      'height': size.height,
      'direction': _getAndroidDirection(_layoutDirection),
    };
    if (_creationParams != null) {
      final ByteData paramsByteData = _creationParamsCodec.encodeMessage(_creationParams);
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    _textureId = await SystemChannels.platform_views.invokeMethod('create', args);
    _state = _AndroidViewState.created;
    for (PlatformViewCreatedCallback callback in _platformViewCreatedCallbacks) {
      // 遍历、回调
      callback(id);
    }
  }
}
```

我们看到了 view 的大小由 _create 方法传入，那传入的值是怎么获得的呢？我们先把还没分析的 _AndroidPlatformView 看完再下结论。

```dart
class _AndroidPlatformView extends LeafRenderObjectWidget {
  // 将 controller 传进来了，具体没做太多的操作，主要还是通过 controller 来实现的。
  const _AndroidPlatformView({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  }) : assert(controller != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       super(key: key);

  final AndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  // 需要注意的是这两个方法，这里重写了 createRenderObject 方法。
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderAndroidView(
        viewController: controller,
        hitTestBehavior: hitTestBehavior,
        gestureRecognizers: gestureRecognizers,
      );

  @override
  void updateRenderObject(BuildContext context, RenderAndroidView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}
```

我这里先假设大家都知道 Widget、Element、RenderObject之间的关系，如果不是很清晰，这篇文章里有详细的介绍。

> Flutter 从加载到显示<br>[https://mp.weixin.qq.com/s/ncViI0KGikPUIZ7BlEHGOA](https://mp.weixin.qq.com/s/ncViI0KGikPUIZ7BlEHGOA)

RenderObject 的最终大小的确定有两种情况，一个是由父节点所指定，一个是根据自己的情况确定。默认的 RenderObject 中有一个 sizedByParent 属性，默认为 false，即根据自身大小确定。这里指定了 RenderObject 为 RenderAndroidView ，我们来看一下这个类，这里就不一行一行的分析了，我们把重点提出来。

```dart
  @override
  bool get sizedByParent => true;
```

所以我们可以得出结论了。

**再小结一下**：

**我们解决解决了剩下的问题**：

1、我们了解了 AndroidViewController、_AndroidPlatformView 都做了什么。

2、AndroidView 的大小是由父节点的大小去定的所以上面使用 Expanded 包裹则可以生效，如果不进行包裹，则大小为父控件大小，在 Column 中会出现问题。当 Widget size 小于 View size，Flutter 会进行裁剪。当 Widget  size 大于 View size 时，多出来的位置会被背景填充。在 Android 侧，实现了 PlatformView 的 View 会被包裹在 FrameLayout 中，可以对 View 的绘制添加监听，打印出 View 的 parent；

3、platform view 是在 native 侧渲染的，返回给 Flutter 侧一个 _textureId ，通过这个 id Flutter 将 View 直接展示出来。这部分也说明了为什么 platform view 在 Flutter 中的性能开销比较大，整个过程数据需要从 GPU -> CPU -> GPU，这部分的代价是比较大的。

## 如何开发一个 platform view

其实 Flutter 官方维护了一些 plugin，链接如下：

> https://github.com/flutter/plugins

其中的 [webview_flutter](https://github.com/flutter/plugins/blob/master/packages/webview_flutter) 、[google_maps_flutter](https://github.com/flutter/plugins/blob/master/packages/google_maps_flutter) 就是通过 platform view，就是一个很好的 demo 。











