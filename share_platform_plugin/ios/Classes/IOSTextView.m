//
//  IOSTextView.m
//  Pods-Runner
//
//  Created by 孙昊 on 2019/8/7.
//

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
    _uiLable.font = [UIFont systemFontOfSize:30];
    return self;
}

-(UIView *)view{
    return _uiLable;
}

@end
