//
//  IOSTextView.h
//  Pods
//
//  Created by 孙昊 on 2019/8/7.
//

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
