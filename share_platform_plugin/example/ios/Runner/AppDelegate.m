#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    return YES;
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

static void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"%@\n%@", exception, [exception callStackSymbols]);
}

@end
