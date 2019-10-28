//
//  Chromecast.m
//  ChromeCast
//
//  Created by mac on 2019/9/30.
//

#import "Chromecast.h"
#import "CastUtilities.h"

@interface Chromecast()

@end

@implementation Chromecast

- (void)pluginInitialize {
    [super pluginInitialize];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCastStateChanged:) name:kGCKCastStateDidChangeNotification object:nil];
}

- (void)sendJavascript:(NSString*)jsCommand {
    [self.webViewEngine evaluateJavaScript:jsCommand completionHandler:nil];
}

- (void)log:(NSString*)s {
    [self sendJavascript:[NSString stringWithFormat: @"console.log('Chromecast-iOS: ', %@)",s]];
}

- (void)setup:(CDVInvokedUrlCommand*) command {
    self.eventCommand = command;
    [self stopRouteScan:self.scanCommand];
    [self sendEvent:@"SETUP" args:@[]];
}

- (void)emitAllRoutes:(CDVInvokedUrlCommand*) command {
    // No arguments. It's only implemented to satisfy plugin's JS API.
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) initialize:(CDVInvokedUrlCommand*)command {
    if (self.devicesAvailable == nil) {
        self.devicesAvailable = [[NSMutableArray alloc] init];
    }
    
    NSString* appId = kGCKDefaultMediaReceiverApplicationID;
    if (command.arguments[0] != nil) {
        appId = command.arguments[0];
    }
    GCKDiscoveryCriteria* criteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:appId];
    GCKCastOptions* options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
    options.physicalVolumeButtonsWillControlDeviceVolume = YES;
    options.disableDiscoveryAutostart = NO;
    [GCKCastContext setSharedInstanceWithOptions:options];
    [GCKCastContext.sharedInstance.discoveryManager addListener:self];
    
    //For debugging purpose
    GCKLogger.sharedInstance.delegate = self;
//    [self log:[NSString stringWithFormat:@"API Initialized with appID %@", appId]];
    if ([GCKCastContext sharedInstance].sessionManager.currentCastSession != nil) {
        [self onSessionRejoin:[CastUtilities createSessionObject:[GCKCastContext sharedInstance].sessionManager.currentCastSession]];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    [self checkReceiverAvailable];
    
}

- (BOOL)stopRouteScan:(CDVInvokedUrlCommand*)command {
    
    if (self.scanCommand != nil) {
        [self sendError:@"cancel" message:@"Scan stopped." command:self.scanCommand];
        self.scanCommand = nil;
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
        [[GCKCastContext sharedInstance].discoveryManager stopDiscovery];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        [[GCKCastContext sharedInstance].discoveryManager stopDiscovery];
        if (command != nil) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]]; 
            [[GCKCastContext sharedInstance].discoveryManager stopDiscovery];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
    
    return YES;
}

-(BOOL) startRouteScan:(CDVInvokedUrlCommand*)command {
    if (self.scanCommand != nil) {
        [self sendError:@"cancel" message:@"Started a new route scan before stopping previous one." command:self.scanCommand];
    }
    self.scanCommand = command;
    [self startRotueScanWithTimer:0 completion:nil];
    return YES;
}
- (void)startRotueScanWithTimer:(NSTimeInterval)timer completion:(void(^)(void))completion {
    if (timer != 0) {
        if (completion != nil) {
            if ([GCKCastContext sharedInstance].discoveryManager.discoveryActive) {
                [[GCKCastContext sharedInstance].discoveryManager stopDiscovery];
                [self sendReceiverData];
            } else {
                [NSTimer scheduledTimerWithTimeInterval:timer repeats:NO block:^(NSTimer * _Nonnull timer) {
                    completion();
                }];

            }
        }
    } else {
        if ([GCKCastContext sharedInstance].discoveryManager.discoveryActive) {
            [[GCKCastContext sharedInstance].discoveryManager stopDiscovery];
            [self sendReceiverData];
        } else {
            [[GCKCastContext sharedInstance].discoveryManager startDiscovery];
            [self sendReceiverData];
        }
    }    
}

- (void)checkReceiverAvailable {
    if ([GCKCastContext sharedInstance].castState != GCKCastStateNoDevicesAvailable) {
        [self sendEvent:@"RECEIVER_LISTENER" args:@[@(true)]];
    } else {
        [self sendEvent:@"RECEIVER_LISTENER" args:@[@(false)]];
    }
}

- (void)sendReceiverData {
    if (self.scanCommand == nil) {
        return;
    }
    GCKSessionManager* sessionManager = GCKCastContext.sharedInstance.sessionManager;
    if (self.devicesAvailable.count > 0 || sessionManager.currentSession != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[CastUtilities createDeviceObject:self.devicesAvailable]];
        [pluginResult setKeepCallback:@(true)];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanCommand.callbackId];
    }else {
        [self stopRouteScan:self.scanCommand];
    }
}
- (void)requestSession:(CDVInvokedUrlCommand*) command {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Cast to" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (GCKDevice* device in self.devicesAvailable) {
        [alert addAction:[UIAlertAction actionWithTitle:device.friendlyName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)setReceiverVolumeLevel:(CDVInvokedUrlCommand*) command {
    double newLevel = 1.0;
    if (command.arguments[0]) {
        newLevel = [command.arguments[0] doubleValue];
    } else {
        newLevel = 1.0;
    }
    [self.currentSession setReceiverVolumeLevelWithCommand:command newLevel:newLevel];
}

- (void)setReceiverMuted:(CDVInvokedUrlCommand*) command {
    BOOL muted = NO;
    if (command.arguments[0]) {
        muted = [command.arguments[0] boolValue];
    }
    [self.currentSession setReceiverMutedWithCommand:command muted:muted];
}

- (void)sessionStop:(CDVInvokedUrlCommand*)command {
    self.currentSession.sessionStatus = @"stopped";
    BOOL result = [[GCKCastContext sharedInstance].sessionManager endSessionAndStopCasting:true];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sessionLeave:(CDVInvokedUrlCommand*) command {
    self.currentSession.sessionStatus = @"disconnected";
    BOOL result = [[GCKCastContext sharedInstance].sessionManager endSession];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)loadMedia:(CDVInvokedUrlCommand*) command {
    NSString* contentId = command.arguments[0];
    NSObject* customData = command.arguments[1];
    NSString* contentType = command.arguments[2];
    double duration = [command.arguments[3] doubleValue];
    NSString* streamType = command.arguments[4];
    BOOL autoplay = [command.arguments[5] boolValue];
    double currentTime = [command.arguments[6] doubleValue];
    NSDictionary* metadata = command.arguments[7];
    NSDictionary* textTrackStyle = command.arguments[8];
    GCKMediaInformation* mediaInfo = [CastUtilities buildMediaInformation:contentId customData:customData contentType:contentType duration:duration streamType:streamType textTrackStyle:textTrackStyle metaData:metadata];
    [self.currentSession loadMediaWithCommand:command mediaInfo:mediaInfo autoPlay:autoplay currentTime:currentTime];
}

- (void)addMessageListener:(CDVInvokedUrlCommand*)command {
    NSString* namespace = command.arguments[0];
    [self.currentSession createMessageChannelWithCommand:command namespace:namespace];
}

- (void)sendMessage:(CDVInvokedUrlCommand*) command {
    NSString* namespace = command.arguments[0];
    NSString* message = command.arguments[1];
    
    [self.currentSession sendMessageWithCommand:command namespace:namespace message:message];
}

- (void)mediaPlay:(CDVInvokedUrlCommand*)command {
    [self.currentSession mediaPlayWithCommand:command];
}

- (void)mediaPause:(CDVInvokedUrlCommand*)command {
    [self.currentSession mediaPauseWithCommand:command];
}

- (void)mediaSeek:(CDVInvokedUrlCommand*)command {
    int currentTime = [command.arguments[0] intValue];
    NSString* resumeState = command.arguments[1];
    GCKMediaResumeState resumeStateObj = [CastUtilities parseResumeState:resumeState];
    [self.currentSession mediaSeekWithCommand:command position:currentTime resumeState:resumeStateObj];
}

- (void)mediaStop:(CDVInvokedUrlCommand*)command {
    [self.currentSession mediaStopWithCommand:command];
}

- (void)mediaEditTracksInfo:(CDVInvokedUrlCommand*)command {
    NSArray<NSNumber*>* activeTrackIds = command.arguments[0];
    NSData* textTrackStyle = command.arguments[1];
    
    GCKMediaTextTrackStyle* textTrackStyleObject = [CastUtilities buildTextTrackStyle:textTrackStyle];
    [self.currentSession setActiveTracksWithCommand:command activeTrackIds:activeTrackIds textTrackStyle:textTrackStyleObject];
}

- (void)selectRoute:(CDVInvokedUrlCommand*)command {
    NSString* routeID = command.arguments[0];
    GCKDevice* device = [[GCKCastContext sharedInstance].discoveryManager deviceWithUniqueID:routeID];
    int retries = 0;
    
    //testing purpose
    if ([routeID isEqualToString:@""]) {
        if ([GCKCastContext sharedInstance].sessionManager.currentCastSession != nil || [GCKCastContext sharedInstance].sessionManager.connectionState == GCKConnectionStateConnected) {
            [self sendError:@"session_error" message:@"Leave or stop current session before attempting to join new session." command:command];
        }
    }
    if (device == nil) {
        [self startRotueScanWithTimer:1 completion:^{
            [self sendError:@"timeout" message:[NSString stringWithFormat:@"Failed to join route (%@) after 15s and %d tries.",routeID,retries + 1] command:command];
        }];
    } else {
        if ([GCKCastContext sharedInstance].sessionManager.currentCastSession != nil || [GCKCastContext sharedInstance].sessionManager.connectionState == GCKConnectionStateConnected) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: [CastUtilities createSessionObject:[GCKCastContext sharedInstance].sessionManager.currentCastSession] ];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            self.currentSession = [[ChromecastSession alloc] initWithDevice:device cordovaDelegate:self.commandDelegate initialCommand:command];
            [self.currentSession add:self];
        }
    }
    
}

#pragma GCKLoggerDelegate
- (void)logMessage:(NSString *)message atLevel:(GCKLoggerLevel)level fromFunction:(NSString *)function location:(NSString *)location {
//    [self log:[NSString stringWithFormat:@"GCKLogger = %@, %ld, %@, %@", message,(long)level,function,location]];
}

#pragma GCKDiscoveryManagerListener
- (NSString*)deviceToJson:(GCKDevice*) device {
    NSString* deviceName = @"";
    if (device.friendlyName != nil) {
        deviceName = device.friendlyName;
    } else {
        deviceName = device.deviceID;
    }
    NSDictionary* deviceJson = @{
        @"name" : deviceName,
        @"id" : device.uniqueID
    };
    return [CastUtilities convertDictToJsonString:deviceJson];
}

- (void)didInsertDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
     NSString* deviceName = @"";
    if (device.friendlyName != nil) {
        deviceName = device.friendlyName;
    } else {
        deviceName = device.deviceID;
    }

    [self.devicesAvailable insertObject:device atIndex:index];
    [self checkReceiverAvailable];
}

- (void)didUpdateDevice:(GCKDevice *)device atIndex:(NSUInteger)index andMoveToIndex:(NSUInteger)newIndex {
    if (self.devicesAvailable.count != 0) {
        [self.devicesAvailable removeObjectAtIndex:index];
    }
    [self.devicesAvailable insertObject:device atIndex:newIndex];
    [self checkReceiverAvailable];
}

- (void)didRemoveDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
    if (self.devicesAvailable.count != 0) {
        [self.devicesAvailable removeObjectAtIndex:index];
    }
    
    [self checkReceiverAvailable];
}

#pragma CastSessionListener
- (void)onMediaLoaded:(NSDictionary *)media {
    [self sendEvent:@"MEDIA_LOAD" args:@[media]];
}

- (void)onMediaUpdated:(NSDictionary *)media isAlive:(BOOL)isAlive {
    [self sendEvent:@"MEDIA_UPDATE" args:@[media]];
}

- (void)onSessionRejoin:(NSDictionary*)session {
    [self sendEvent:@"SESSION_LISTENER" args:@[session]];
}

- (void)onSessionUpdated:(NSDictionary *)session isAlive:(BOOL)isAlive {
    [self sendEvent:@"SESSION_UPDATE" args:@[session]];
}

- (void)onMessageReceived:(NSDictionary *)session namespace:(NSString *)namespace message:(NSString *)message {
    [self sendEvent:@"RECEIVER_MESSAGE" args:@[namespace,message]];
}

- (void)onSessionEnd:(NSDictionary *)session {
    
    [self sendEvent:@"SESSION_UPDATE" args:@[session]];
}
- (void)onCastStateChanged:(NSNotification*)notification {
    
    GCKCastState castState = [notification.userInfo[kGCKNotificationKeyCastState] intValue];
    if (castState == GCKCastStateNoDevicesAvailable) {
        [self sendEvent:@"RECEIVER_LISTENER" args:@[@(false)]];
    } else {
        [self sendEvent:@"RECEIVER_LISTENER" args:@[@(true)]];
    }
}

- (void)sendEvent:(NSString *)eventName args:(NSArray *)args{
    if (self.eventCommand == nil) {
        return;
    }
    NSMutableArray* argArray = [[NSMutableArray alloc] initWithArray:@[eventName]];
    [argArray addObject:args];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:argArray];
    [pluginResult setKeepCallback:@(true)];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.eventCommand.callbackId];
}

- (void)sendScan:(NSArray *)args{
    if (self.scanCommand == nil) {
        return;
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:args];
    [pluginResult setKeepCallback:@(YES)];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanCommand.callbackId];
}


- (void)sendError:(NSString *)code message:(NSString *)message command:(CDVInvokedUrlCommand*)command{
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[CastUtilities createError:code message:message]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
