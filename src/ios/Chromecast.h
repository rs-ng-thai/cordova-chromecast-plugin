//
//  Chromecast.h
//  ChromeCast
//
//  Created by mac on 2019/9/30.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>
#import <Cordova/CDV.h>
#import "ChromecastSession.h"
#import "CastUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface Chromecast : CDVPlugin<GCKDiscoveryManagerListener,GCKLoggerDelegate,CastSessionListener>

@property (nonatomic, strong) NSMutableArray* devicesAvailable;
@property (nonatomic, strong) ChromecastSession* currentSession;
@property (nonatomic, strong) CDVInvokedUrlCommand* eventCommand;
@property (nonatomic, strong) CDVInvokedUrlCommand* scanCommand;

- (void)setup:(CDVInvokedUrlCommand*) command;
- (void)emitAllRoutes:(CDVInvokedUrlCommand*) command;
- (void)initialize:(CDVInvokedUrlCommand*)command;
- (BOOL)startRouteScan:(CDVInvokedUrlCommand*)command;
- (BOOL)stopRouteScan:(CDVInvokedUrlCommand*)command;
- (void)checkReceiverAvailable;
- (void)requestSession:(CDVInvokedUrlCommand*) command;
- (void)setReceiverVolumeLevel:(CDVInvokedUrlCommand*) command;
- (void)setReceiverMuted:(CDVInvokedUrlCommand*) command;
- (void)sessionStop:(CDVInvokedUrlCommand*)command;
- (void)sessionLeave:(CDVInvokedUrlCommand*) command;
- (void)loadMedia:(CDVInvokedUrlCommand*) command;
- (void)addMessageListener:(CDVInvokedUrlCommand*)command;
- (void)sendMessage:(CDVInvokedUrlCommand*) command;
- (void)mediaPlay:(CDVInvokedUrlCommand*)command;
- (void)mediaPause:(CDVInvokedUrlCommand*)command;
- (void)mediaSeek:(CDVInvokedUrlCommand*)command;
- (void)mediaStop:(CDVInvokedUrlCommand*)command;
- (void)mediaEditTracksInfo:(CDVInvokedUrlCommand*)command;
- (void)selectRoute:(CDVInvokedUrlCommand*)command;
- (void)sendEvent:(NSString*)eventName args:(NSArray*)args;

@end

NS_ASSUME_NONNULL_END
