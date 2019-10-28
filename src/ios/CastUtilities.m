//
//  CastUtilities.m
//  ChromeCast
//
//  Created by mac on 2019/9/30.
//

#import "CastUtilities.h"

@implementation CastUtilities

+ (GCKMediaInformation *)buildMediaInformation:(NSString *)contentUrl customData:(id )customData contentType:(NSString *)contentType duration:(double)duration streamType:(NSString *)streamType textTrackStyle:(NSDictionary *)textTrackStyle metaData:(NSDictionary *)metaData {
    NSURL* url = [NSURL URLWithString:contentUrl];
    GCKMediaInformationBuilder* mediaInfoBuilder = [[GCKMediaInformationBuilder alloc] initWithContentURL:url];
    mediaInfoBuilder.customData = customData;
    mediaInfoBuilder.contentType = contentType;
    mediaInfoBuilder.streamDuration = round(duration);
    if ([streamType isEqualToString:@"buffered"]) {
        mediaInfoBuilder.streamType = GCKMediaStreamTypeBuffered;
    } else if ([streamType isEqualToString:@"live"]) {
        mediaInfoBuilder.streamType = GCKMediaStreamTypeLive;
    } else {
        mediaInfoBuilder.streamType = GCKMediaStreamTypeNone;
    }
    
    mediaInfoBuilder.textTrackStyle = [CastUtilities buildTextTrackStyle:textTrackStyle];
    mediaInfoBuilder.metadata = [CastUtilities buildMediaMetadata:metaData];
    return [mediaInfoBuilder build];
}

+ (GCKMediaTextTrackStyle *)buildTextTrackStyle:(NSDictionary *)data {
    NSError *error = nil;
    GCKMediaTextTrackStyle* mediaTextTrackStyle = [GCKMediaTextTrackStyle createDefault];
    
    if (error == nil) {
        NSString* bkgColor = data[@"backgroundColor"];
        if (bkgColor != nil) {
            mediaTextTrackStyle.backgroundColor = [[GCKColor alloc] initWithCSSString:bkgColor];
            
        }
        
        NSObject* customData = data[@"customData"];
        if (bkgColor != nil) {
            mediaTextTrackStyle.customData = customData;
            
        }
        
        NSString* edgeColor = data[@"edgeColor"];
        if (edgeColor != nil) {
            mediaTextTrackStyle.edgeColor = [[GCKColor alloc] initWithCSSString:edgeColor];
            
        }
        
        NSString* edgeType = data[@"edgeType"];
        if (edgeType != nil) {
            mediaTextTrackStyle.edgeType = [CastUtilities parseEdgeType:edgeType];
        }

        NSString* fontFamily = data[@"fontFamily"];
        if (fontFamily != nil) {
            mediaTextTrackStyle.fontFamily = fontFamily;
        }
        
        NSString* fontGenericFamily = data[@"fontGenericFamily"];
        if (fontGenericFamily != nil) {
            mediaTextTrackStyle.fontGenericFamily = [CastUtilities parseFontGenericFamily:fontGenericFamily];
        }
        
        CGFloat fontScale = (CGFloat)[data[@"fontScale"] floatValue];
        if (fontScale != 0) {
            mediaTextTrackStyle.fontScale = fontScale;
        }

        NSString* fontStyle = data[@"fontStyle"];
        if (fontFamily != nil) {
            mediaTextTrackStyle.fontStyle = [CastUtilities parseFontStyle:fontStyle];
        }
        NSString* foregroundColor = data[@"foregroundColor"];
        if (fontFamily != nil) {
            mediaTextTrackStyle.foregroundColor = [[GCKColor alloc] initWithCSSString:foregroundColor];
        }
        
        NSString* windowColor = data[@"windowColor"];
        if (windowColor != nil) {
            mediaTextTrackStyle.windowColor = [[GCKColor alloc] initWithCSSString:windowColor];
        }
        
        CGFloat wRoundedCorner = (CGFloat)[data[@"windowRoundedCornerRadius"] floatValue];
        if (wRoundedCorner != 0) {
            mediaTextTrackStyle.windowRoundedCornerRadius = wRoundedCorner;
        }
        
        NSString* windowType = data[@"windowType"];
        if (windowType != nil) {
            mediaTextTrackStyle.windowType = [CastUtilities parseWindowType:windowType];
        }
    }
    return mediaTextTrackStyle;
}

+(GCKMediaMetadata*)buildMediaMetadata:(NSDictionary*)data {
    GCKMediaMetadata* mediaMetaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeGeneric];
    
    if (data[@"metadataType"]) {
        int metadataType = [data[@"metadataType"] intValue];
        mediaMetaData = [[GCKMediaMetadata alloc] initWithMetadataType:metadataType];
    }
    NSData* imagesRaw = data[@"images"];
    if (imagesRaw != nil) {
        NSArray<GCKImage*>* images = [CastUtilities getMetadataImages:imagesRaw];
        for (GCKImage* image in images) {
            [mediaMetaData addImage:image];
        }
    }
    
    NSArray* keys = data.allKeys;
    for (NSString* key in keys) {
        if ([key isEqualToString:@"metadataType"] || [key isEqualToString:@"images"] || [key isEqualToString:@"type"]) {
            continue;
        }
        NSString* convertedKey = [CastUtilities getiOSMetadataName:key];
        NSString* dataType = [CastUtilities getMetadataType:convertedKey];
        if ([dataType isEqualToString:@"string"]) {
            if (data[key]) {
                [mediaMetaData setString:data[key] forKey:convertedKey];
            }
        }
        if ([dataType isEqualToString:@"int"]) {
            if (data[key]) {
                [mediaMetaData setInteger:[data[key] intValue] forKey:convertedKey];
            }
        }
        if ([dataType isEqualToString:@"double"]) {
            if (data[key]) {
                [mediaMetaData setDouble:[data[key] doubleValue] forKey:convertedKey];
            }
        }
        if ([dataType isEqualToString:@"date"]) {
            if (![data[key] isKindOfClass:[NSString class]]) {
                NSDate* date = [NSDate dateWithTimeIntervalSince1970:[data[key] longValue] / 1000];
                [mediaMetaData setDate:date forKey:convertedKey];
            }
        }
        if ([dataType isEqualToString:@"ms"]) {
            if (data[key]) {
                [mediaMetaData setDouble:[data[key] longValue] forKey:convertedKey];
            }
        }
        if (![key isEqualToString:convertedKey]) {
            convertedKey = [NSString stringWithFormat:@"cordova-plugin-chromecast_metadata_key=%@",key];
        }
        if ([data[key] doubleValue] != 0 && floor([data[key] doubleValue]) != [data[key] doubleValue]) {
            [mediaMetaData setString:[NSString stringWithFormat:@"%@",data[key]]  forKey:convertedKey];
        } else {
            [mediaMetaData setString:data[key] forKey:convertedKey];
        }
    }
    
    return mediaMetaData;
}

+(NSString*)getMetadataType:(NSString*)iOSName {
    if ([iOSName isEqualToString:kGCKMetadataKeyAlbumArtist]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyAlbumTitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyArtist]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyBookTitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyBroadcastDate]) {
        return @"date";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyChapterNumber]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyChapterTitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyComposer]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyCreationDate]) {
        return @"date";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyDiscNumber]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyEpisodeNumber]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyHeight]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationLatitude]) {
        return @"double";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationLongitude]) {
        return @"double";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationName]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyQueueItemID]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyReleaseDate]) {
        return @"date";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySeasonNumber]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionDuration]) {
        return @"ms";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartAbsoluteTime]) {
        return @"ms";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartTimeInContainer]) {
        return @"ms";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartTimeInMedia]) {
        return @"ms";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySeriesTitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyStudio]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySubtitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyTitle]) {
        return @"string";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyTrackNumber]) {
        return @"int";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyWidth]) {
        return @"int";
    }
    return iOSName;
}
+(NSString*)getiOSMetadataName:(NSString*)clientName {
    if ([clientName isEqualToString:@"albumArtist"]) {
        return kGCKMetadataKeyAlbumArtist;
    }
    if ([clientName isEqualToString:@"albumName"]) {
        return kGCKMetadataKeyAlbumTitle;
    }
    if ([clientName isEqualToString:@"artist"]) {
        return kGCKMetadataKeyArtist;
    }
    if ([clientName isEqualToString:@"bookTitle"]) {
        return kGCKMetadataKeyBookTitle;
    }
    if ([clientName isEqualToString:@"broadcastDate"]) {
        return kGCKMetadataKeyBroadcastDate;
    }
    if ([clientName isEqualToString:@"chapterNumber"]) {
        return kGCKMetadataKeyChapterNumber;
    }
    if ([clientName isEqualToString:@"chapterTitle"]) {
        return kGCKMetadataKeyChapterTitle;
    }
    if ([clientName isEqualToString:@"composer"]) {
        return kGCKMetadataKeyComposer;
    }
    if ([clientName isEqualToString:@"creationDate"]) {
        return kGCKMetadataKeyCreationDate;
    }
    if ([clientName isEqualToString:@"creationDateTime"]) {
        return kGCKMetadataKeyCreationDate;
    }
    if ([clientName isEqualToString:@"discNumber"]) {
        return kGCKMetadataKeyDiscNumber;
    }
    if ([clientName isEqualToString:@"episode"]) {
        return kGCKMetadataKeyEpisodeNumber;
    }
    if ([clientName isEqualToString:@"height"]) {
        return kGCKMetadataKeyHeight;
    }
    if ([clientName isEqualToString:@"latitude"]) {
        return kGCKMetadataKeyLocationLatitude;
    }
    if ([clientName isEqualToString:@"longitude"]) {
        return kGCKMetadataKeyLocationLongitude;
    }
    if ([clientName isEqualToString:@"locationName"]) {
        return kGCKMetadataKeyLocationName;
    }
    if ([clientName isEqualToString:@"queueItemId"]) {
        return kGCKMetadataKeyQueueItemID;
    }
    if ([clientName isEqualToString:@"releaseDate"]) {
        return kGCKMetadataKeyReleaseDate;
    }
    if ([clientName isEqualToString:@"originalAirDate"]) {
        return kGCKMetadataKeyReleaseDate;
    }
    if ([clientName isEqualToString:@"season"]) {
        return kGCKMetadataKeySeasonNumber;
    }
    if ([clientName isEqualToString:@"sectionDuration"]) {
        return kGCKMetadataKeySectionDuration;
    }
    if ([clientName isEqualToString:@"sectionStartAbsoluteTime"]) {
        return kGCKMetadataKeySectionStartAbsoluteTime;
    }
    if ([clientName isEqualToString:@"sectionStartTimeInContainer"]) {
        return kGCKMetadataKeySectionStartTimeInContainer;
    }
    if ([clientName isEqualToString:@"sectionStartTimeInMedia"]) {
        return kGCKMetadataKeySectionStartTimeInMedia;
    }
    if ([clientName isEqualToString:@"seriesTitle"]) {
        return kGCKMetadataKeySeriesTitle;
    }
    if ([clientName isEqualToString:@"studio"]) {
        return kGCKMetadataKeyStudio;
    }
    if ([clientName isEqualToString:@"subtitle"]) {
        return kGCKMetadataKeySubtitle;
    }
    if ([clientName isEqualToString:@"title"]) {
        return kGCKMetadataKeyTitle;
    }
    if ([clientName isEqualToString:@"trackNumber"]) {
        return kGCKMetadataKeyTrackNumber;
    }
    if ([clientName isEqualToString:@"width"]) {
        return kGCKMetadataKeyWidth;
    }
    return clientName;
}

+(NSString*)getClientMetadataName:(NSString*)iOSName {
    if ([iOSName isEqualToString:kGCKMetadataKeyAlbumArtist]) {
        return @"albumArtist";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyAlbumTitle]) {
        return @"albumName";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyArtist]) {
        return @"artist";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyBookTitle]) {
        return @"bookTitle";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyBroadcastDate]) {
        return @"broadcastDate";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyChapterNumber]) {
        return @"chapterNumber";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyChapterTitle]) {
        return @"chapterTitle";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyComposer]) {
        return @"composer";
    }
    
    if ([iOSName isEqualToString:kGCKMetadataKeyCreationDate]) {
        return @"creationDate";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyDiscNumber]) {
        return @"discNumber";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyEpisodeNumber]) {
        return @"episode";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyHeight]) {
        return @"height";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationLatitude]) {
        return @"latitude";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationLongitude]) {
        return @"longitude";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyLocationName]) {
        return @"locationName";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyQueueItemID]) {
        return @"queueItemId";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyReleaseDate]) {
        return @"releaseDate";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySeasonNumber]) {
        return @"season";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionDuration]) {
        return @"sectionDuration";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartAbsoluteTime]) {
        return @"sectionStartAbsoluteTime";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartTimeInContainer]) {
        return @"sectionStartTimeInContainer";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySectionStartTimeInMedia]) {
        return @"sectionStartTimeInMedia";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySeriesTitle]) {
        return @"seriesTitle";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyStudio]) {
        return @"studio";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeySubtitle]) {
        return @"subtitle";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyTitle]) {
        return @"title";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyTrackNumber]) {
        return @"trackNumber";
    }
    if ([iOSName isEqualToString:kGCKMetadataKeyWidth]) {
        return @"width";
    }
    return iOSName;
}
+ (NSArray<GCKImage *> *)getMetadataImages:(NSArray *)imagesRaw {
    NSMutableArray<GCKImage*>* images = [NSMutableArray new];
    
    for (NSDictionary* dict in imagesRaw) {
        NSString* urlString = dict[@"url"];
        NSURL* url = [NSURL URLWithString:urlString];
        int width = 100;
        int height = 100;
        if (dict[@"width"] == nil) {
            width = [dict[@"width"] intValue];
        }
        if (dict[@"height"] == nil) {
            height = [dict[@"height"] intValue];
        }
        [images addObject:[[GCKImage alloc] initWithURL:url width:width height:height]];
    }
    
    return images;
}

+ (NSDictionary *)createSessionObject:(GCKCastSession *)session {
    return @{
        @"appId" : session.applicationMetadata.applicationID? session.applicationMetadata.applicationID : @"",
        @"media" : [CastUtilities createMediaObject:session],
        @"appImages" : @{},
        @"sessionId" : session.sessionID? session.sessionID : @"",
        @"displayName" : session.applicationMetadata.applicationName? session.applicationMetadata.applicationName : @"",
        @"receiver" : @{
                @"friendlyName" : session.device.friendlyName? session.device.friendlyName : @"",
                @"label" : session.device.uniqueID,
                @"volume" : @{
                        @"level" : @(session.currentDeviceVolume),
                        @"muted" : @(session.currentDeviceMuted)
                }
        },
        
    };
}

+ (NSDictionary*)createSessionObject:(GCKCastSession *)session status:(NSString*)status {
    return @{
        @"appId" : session.applicationMetadata.applicationID? session.applicationMetadata.applicationID : @"",
        @"media" : [CastUtilities createMediaObject:session],
        @"appImages" : @{},
        @"sessionId" : session.sessionID? session.sessionID : @"",
        @"displayName" : session.applicationMetadata.applicationName? session.applicationMetadata.applicationName : @"",
        @"receiver" : @{
                @"friendlyName" : session.device.friendlyName? session.device.friendlyName : @"",
                @"label" : session.device.uniqueID,
                @"volume" : @{
                        @"level" : @(session.currentDeviceVolume),
                        @"muted" : @(session.currentDeviceMuted)
                }
        },
        @"status":status
    };
}
+ (NSDictionary *)createMediaObject:(GCKCastSession *)session {
    if (session.remoteMediaClient == nil) {
        return @{};
    }
    
    GCKMediaStatus* mediaStatus = session.remoteMediaClient.mediaStatus;
    if (mediaStatus == nil) {
        return @{};
    }
    if ([CastUtilities getIdleReason:mediaStatus.idleReason]) {
        return @{
            @"currentItemId" : @(mediaStatus.currentItemID),
            @"currentTime" : @(mediaStatus.streamPosition),
            @"customData" : (mediaStatus.customData == nil)? @{} : mediaStatus.customData,
            @"idleReason" : [CastUtilities getIdleReason:mediaStatus.idleReason],
            @"loadingItemId" : @(mediaStatus.loadingItemID),
            @"isAlive" : mediaStatus.playerState != GCKMediaPlayerStateIdle? @(YES) : @(NO),
            @"media" : [CastUtilities createMediaInfoObject:mediaStatus.mediaInformation],
            @"mediaSessionId" : @(mediaStatus.mediaSessionID),
            @"playbackRate" : @(mediaStatus.playbackRate),
            @"playerState" : [CastUtilities getPlayerState:mediaStatus.playerState],
            @"repeatMode" : [CastUtilities getRepeatMode:mediaStatus.queueRepeatMode],
            @"preloadedItemId" : @(mediaStatus.preloadedItemID),
//            @"queueData" : [CastUtilities createQueueData:mediaStatus],
            @"sessionId" : session.sessionID,
            @"volume" : @{
                    @"level" : @(mediaStatus.volume),
                    @"muted" : @(mediaStatus.isMuted),
            },
            @"activeTrackIds" : mediaStatus.activeTrackIDs? mediaStatus.activeTrackIDs : @[]
        };
    } else {
        return @{
            @"currentItemId" : @(mediaStatus.currentItemID),
            @"currentTime" : @(mediaStatus.streamPosition),
            @"customData" : (mediaStatus.customData == nil)? @{} : mediaStatus.customData,
            @"loadingItemId" : @(mediaStatus.loadingItemID),
            @"isAlive" : mediaStatus.playerState != GCKMediaPlayerStateIdle? @(YES) : @(NO),
            @"media" : [CastUtilities createMediaInfoObject:mediaStatus.mediaInformation],
            @"mediaSessionId" : @(mediaStatus.mediaSessionID),
            @"playbackRate" : @(mediaStatus.playbackRate),
            @"playerState" : [CastUtilities getPlayerState:mediaStatus.playerState],
            @"preloadedItemId" : @(mediaStatus.preloadedItemID),
            @"repeatMode" : [CastUtilities getRepeatMode:mediaStatus.queueRepeatMode],
            @"sessionId" : session.sessionID,
//            @"queueData" : [CastUtilities createQueueData:mediaStatus] == nil ? NULL : [CastUtilities createQueueData:mediaStatus],
            @"volume" : @{
                    @"level" : @(mediaStatus.volume),
                    @"muted" : @(mediaStatus.isMuted),
            },
            @"activeTrackIds" : mediaStatus.activeTrackIDs? mediaStatus.activeTrackIDs : @[]
        };
    }
    
}

+ (NSDictionary*)createQueueData:(GCKMediaStatus*)mediaStatus {
    GCKMediaQueueData* queueData = mediaStatus.queueData;
    if (!queueData) {
        return nil;
    }
    NSMutableDictionary* returnDict = [[NSMutableDictionary alloc] init];
    returnDict[@"repeatMode"] = [CastUtilities getRepeatMode:queueData.repeatMode];
    returnDict[@"shuffle"] = queueData.repeatMode == GCKMediaRepeatModeAllAndShuffle? @(YES) : @(NO);
    returnDict[@"startIndex"] = @(queueData.startIndex);
    
    return returnDict;
}

+ (NSDictionary *)createMediaInfoObject:(GCKMediaInformation *)mediaInfo {
    if (mediaInfo == nil) {
        return @{};
    }
    
    return @{
        @"contentId": mediaInfo.contentID == nil ? @"" : mediaInfo.contentID,
        @"contentType": mediaInfo.contentType,
        @"customData": mediaInfo.customData == nil ? @{} : mediaInfo.customData,
        @"duration": @(mediaInfo.streamDuration),
        @"metadata" : [CastUtilities createMetadataObject:mediaInfo.metadata],
        @"streamType": [CastUtilities getStreamType:mediaInfo.streamType],
        @"tracks": [CastUtilities getMediaTracks:mediaInfo.mediaTracks],
        @"textTrackSytle": [CastUtilities getTextTrackStyle:mediaInfo.textTrackStyle],
    };
}

+ (NSDictionary*)createMetadataObject:(GCKMediaMetadata*)metadata {
    
    NSMutableDictionary* outputDict = [NSMutableDictionary new];
    if (!metadata) {
        return [NSDictionary dictionaryWithDictionary:outputDict];
    }
    outputDict[@"images"] = [CastUtilities createImagesArray:metadata.images];
    outputDict[@"metadataType"] = @(metadata.metadataType);
    outputDict[@"type"] = @(metadata.metadataType);
    
    NSArray* keys = metadata.allKeys;
    for (NSString* key in keys) {
        NSString* outKey = [CastUtilities getClientMetadataName:key];
        if ([outKey isEqualToString:key] || [outKey isEqualToString:@"type"]) {
            continue;
        }
        NSString* dataType = [CastUtilities getMetadataType:key];
        if ([dataType isEqualToString:@"string"]) {
            outputDict[outKey] = [metadata stringForKey:key];
        }
        if ([dataType isEqualToString:@"int"]) {
            outputDict[outKey] = @([metadata integerForKey:key]);
        }
        if ([dataType isEqualToString:@"double"]) {
            outputDict[outKey] = @([metadata doubleForKey:key]);
        }
        if ([dataType isEqualToString:@"date"]) {
            outputDict[outKey] = @((long long)[[metadata dateForKey:key] timeIntervalSince1970] * 1000);
        }
        if ([dataType isEqualToString:@"ms"]) {
            outputDict[outKey] = @([metadata doubleForKey:key]);
        }
    }
    for (NSString* key in keys) {
        NSString* outKey = [CastUtilities getClientMetadataName:key];
        if (![outKey isEqualToString:key] || [outputDict.allKeys containsObject:outKey] || [outKey isEqualToString:@"type"]) {
            continue;
        }
        if ([outKey hasPrefix:@"cordova-plugin-chromecast_metadata_key="]) {
            outKey = [outKey substringFromIndex:[@"cordova-plugin-chromecast_metadata_key=" length]];
        }
        outputDict[outKey] = [metadata objectForKey:key];
    }
    return outputDict;
}

+ (NSArray*)createImagesArray:(NSArray<GCKImage*>*) images {
    NSMutableArray* appImages = [NSMutableArray new];
    
    for (GCKImage* image in images) {
        NSMutableDictionary* imgDict = [NSMutableDictionary new];
        imgDict[@"url"] = image.URL.absoluteString;
        [appImages addObject:imgDict];
    }
    return appImages;
}

+(NSArray*)createDeviceObject:(NSArray<GCKDevice*>*)devices
{
    NSMutableArray* deviceArray = [[NSMutableArray alloc] init];
    for (int i=0; i < devices.count; i++) {
        GCKDevice* device = devices[i];
        NSString* deviceName = @"";
        if (device.friendlyName != nil) {
            deviceName = device.friendlyName;
        } else {
            deviceName = device.deviceID;
        }
        NSMutableDictionary* deviceDict = [[NSMutableDictionary alloc] initWithDictionary:@{@"id":device.uniqueID,@"name":deviceName}];
        deviceDict[@"isNearbyDevice"] = [NSNumber numberWithBool:!device.isOnLocalNetwork];
        deviceDict[@"isCastGroup"] = [NSNumber numberWithBool:NO];
        [deviceArray addObject:[NSDictionary dictionaryWithDictionary:deviceDict]];
    }
    return [NSArray arrayWithArray:deviceArray];
}

+ (NSArray<NSDictionary *> *)getMediaTracks:(NSArray<GCKMediaTrack *> *)mediaTracks {
    NSMutableArray<NSDictionary*>* tracks = [NSMutableArray new];
    
    if (mediaTracks == nil) {
        return tracks;
    }
    
    for (GCKMediaTrack* mediaTrack in mediaTracks) {
        NSDictionary* track = @{
            @"trackId": @(mediaTrack.identifier),
            @"customData": mediaTrack.customData == nil? @{} : mediaTrack.customData,
            @"language": mediaTrack.languageCode == nil? @"" : mediaTrack.languageCode,
            @"name": mediaTrack.name == nil? @"" : mediaTrack.name,
            @"subtype": [CastUtilities getTextTrackSubtype:mediaTrack.textSubtype],
            @"trackContentId": mediaTrack.contentIdentifier,
            @"trackContentType": mediaTrack.contentType,
            @"type": [CastUtilities getTrackType:mediaTrack.type],
        };
        [tracks addObject:track];
    }
    return tracks;
}

+ (NSDictionary *)getTextTrackStyle:(GCKMediaTextTrackStyle *)textTrackStyle {
    if (textTrackStyle == nil) {
        return @{};
    }
    return @{
        @"backgroundColor": textTrackStyle.backgroundColor.CSSString,
        @"customData": textTrackStyle.customData == nil? @{} : textTrackStyle.customData,
        @"edgeColor": textTrackStyle.edgeColor.CSSString == nil? @"" : textTrackStyle.edgeColor.CSSString,
        @"edgeType": [CastUtilities getEdgeType:textTrackStyle.edgeType],
        @"fontFamily": textTrackStyle.fontFamily,
        @"fontGenericFamily": [CastUtilities getFontGenericFamily:textTrackStyle.fontGenericFamily],
        @"fontScale": @(textTrackStyle.fontScale),
        @"fontStyle": [CastUtilities getFontStyle:textTrackStyle.fontStyle],
        @"foregroundColor": textTrackStyle.foregroundColor.CSSString,
        @"windowColor": textTrackStyle.windowColor.CSSString,
        @"windowRoundedCornerRadius": @(textTrackStyle.windowRoundedCornerRadius),
        @"windowType": [CastUtilities getWindowType:textTrackStyle.windowType]
    };
}

+ (NSString *)getEdgeType:(GCKMediaTextTrackStyleEdgeType)edgeType {
    switch (edgeType) {
        case GCKMediaTextTrackStyleEdgeTypeDepressed:
            return @"DEPRESSED";
        case GCKMediaTextTrackStyleEdgeTypeDropShadow:
            return @"DROP_SHADOW";
        case GCKMediaTextTrackStyleEdgeTypeOutline:
            return @"OUTLINE";
        case GCKMediaTextTrackStyleEdgeTypeRaised:
            return @"RAISED";
        default:
            return @"NONE";
    }
}

+ (NSString *)getFontGenericFamily:(GCKMediaTextTrackStyleFontGenericFamily)fontGenericFamily {
    switch (fontGenericFamily) {
        case GCKMediaTextTrackStyleFontGenericFamilyCursive:
            return @"CURSIVE";
        case GCKMediaTextTrackStyleFontGenericFamilyMonospacedSansSerif:
            return @"MONOSPACED_SANS_SERIF";
        case GCKMediaTextTrackStyleFontGenericFamilyMonospacedSerif:
            return @"MONOSPACED_SERIF";
        case GCKMediaTextTrackStyleFontGenericFamilySansSerif:
            return @"SANS_SERIF";
        case GCKMediaTextTrackStyleFontGenericFamilySerif:
            return @"SERIF";
        case GCKMediaTextTrackStyleFontGenericFamilySmallCapitals:
            return @"SMALL_CAPITALS";
        default:
            return @"SERIF";
    }
}

+ (NSString *)getFontStyle:(GCKMediaTextTrackStyleFontStyle)fontStyle {
    switch (fontStyle) {
        case GCKMediaTextTrackStyleFontStyleNormal:
            return @"NORMAL";
        case GCKMediaTextTrackStyleFontStyleBold:
            return @"BOLD";
        case GCKMediaTextTrackStyleFontStyleBoldItalic:
            return @"BOLD_ITALIC";
        case GCKMediaTextTrackStyleFontStyleItalic:
            return @"ITALIC";
        default:
            return @"NORMAL";
    }
}

+ (NSString *)getWindowType:(GCKMediaTextTrackStyleWindowType)windowType {
    switch (windowType) {
        case GCKMediaTextTrackStyleWindowTypeNormal:
            return @"NORMAL";
        case GCKMediaTextTrackStyleWindowTypeRoundedCorners:
            return @"ROUNDED_CORNERS";
        default:
            return @"NONE";
    }
}

+ (NSString *)getTrackType:(GCKMediaTrackType)trackType {
    switch (trackType) {
        case GCKMediaTrackTypeAudio:
            return @"AUDIO";
        case GCKMediaTrackTypeText:
            return @"TEXT";
        case GCKMediaTrackTypeVideo:
            return @"VIDEO";
        default:
            return nil;
    }
}

+ (NSString *)getTextTrackSubtype:(GCKMediaTextTrackSubtype)textSubtype {
    switch (textSubtype) {
        case GCKMediaTextTrackSubtypeCaptions:
            return @"CAPTIONS";
        case GCKMediaTextTrackSubtypeChapters:
            return @"CHAPTERS";
        case GCKMediaTextTrackSubtypeDescriptions:
            return @"DESCRIPTIONS";
        case GCKMediaTextTrackSubtypeMetadata:
            return @"METADATA";
        case GCKMediaTextTrackSubtypeSubtitles:
            return @"SUBTITLES";
        default:
            return nil;
    }
}

+ (NSString *)getIdleReason:(GCKMediaPlayerIdleReason)reason {
    switch (reason) {
        case GCKMediaPlayerIdleReasonCancelled:
            return @"CANCELLED";
        case GCKMediaPlayerIdleReasonError:
            return @"ERROR";
        case GCKMediaPlayerIdleReasonFinished:
            return @"FINISHED";
        case GCKMediaPlayerIdleReasonInterrupted:
            return @"INTERRUPTED";
        default:
            return nil;
    }
}

+ (NSString *)getRepeatMode:(GCKMediaRepeatMode)repeatMode {
    switch (repeatMode) {
        case GCKMediaRepeatModeOff:
            return @"REPEAT_OFF";
        case GCKMediaRepeatModeAll:
            return @"REPEAT_ALL";
        case GCKMediaRepeatModeAllAndShuffle:
            return @"REPEAT_ALL_AND_SHUFFLE";
        case GCKMediaRepeatModeSingle:
            return @"REPEAT_SINGLE";
        default:
            return @"REPEAT_OFF";
    }
}
+ (NSString *)getPlayerState:(GCKMediaPlayerState)playerState {
    switch (playerState) {
        case GCKMediaPlayerStateBuffering:
            return @"BUFFERING";
        case GCKMediaPlayerStateIdle:
            return @"IDLE";
        case GCKMediaPlayerStatePaused:
            return @"PAUSED";
        case GCKMediaPlayerStatePlaying:
            return @"PLAYING";
        default:
            return @"BUFFERING";
    }
}

+ (NSString *)getStreamType:(GCKMediaStreamType)streamType {
    switch (streamType) {
        case GCKMediaStreamTypeBuffered:
            return @"buffered";
        case GCKMediaStreamTypeLive:
            return @"live";
        case GCKMediaStreamTypeNone:
            return @"other";
        default:
            return @"unknown";
    }
}

+ (GCKMediaTextTrackStyleEdgeType)parseEdgeType:(NSString *)edgeType {
    if ([edgeType isEqualToString:@"DEPRESSED"]) {
        return GCKMediaTextTrackStyleEdgeTypeDepressed;
    }
    if ([edgeType isEqualToString:@"DROP_SHADOW"]) {
        return GCKMediaTextTrackStyleEdgeTypeDropShadow;
    }
    if ([edgeType isEqualToString:@"OUTLINE"]) {
        return GCKMediaTextTrackStyleEdgeTypeOutline;
    }
    if ([edgeType isEqualToString:@"RAISED"]) {
        return GCKMediaTextTrackStyleEdgeTypeRaised;
    }
    return GCKMediaTextTrackStyleEdgeTypeNone;
}

+ (GCKMediaTextTrackStyleFontGenericFamily)parseFontGenericFamily:(NSString *)fontGenericFamily {
    if ([fontGenericFamily isEqualToString:@"CURSIVE"]) {
        return GCKMediaTextTrackStyleFontGenericFamilyCursive;
    }
    if ([fontGenericFamily isEqualToString:@"MONOSPACED_SANS_SERIF"]) {
        return GCKMediaTextTrackStyleFontGenericFamilyMonospacedSansSerif;
    }
    if ([fontGenericFamily isEqualToString:@"MONOSPACED_SERIF"]) {
        return GCKMediaTextTrackStyleFontGenericFamilyMonospacedSerif;
    }
    if ([fontGenericFamily isEqualToString:@"SANS_SERIF"]) {
        return GCKMediaTextTrackStyleFontGenericFamilySansSerif;
    }
    if ([fontGenericFamily isEqualToString:@"SERIF"]) {
        return GCKMediaTextTrackStyleFontGenericFamilySerif;
    }
    if ([fontGenericFamily isEqualToString:@"SMALL_CAPITALS"]) {
        return GCKMediaTextTrackStyleFontGenericFamilySmallCapitals;
    }
    return GCKMediaTextTrackStyleFontGenericFamilySerif;
}

+ (GCKMediaTextTrackStyleFontStyle)parseFontStyle:(NSString *)fontStyle {
    if ([fontStyle isEqualToString:@"NORMAL"]) {
        return GCKMediaTextTrackStyleFontStyleNormal;
    }
    if ([fontStyle isEqualToString:@"BOLD"]) {
        return GCKMediaTextTrackStyleFontStyleBold;
    }
    if ([fontStyle isEqualToString:@"BOLD_ITALIC"]) {
        return GCKMediaTextTrackStyleFontStyleBoldItalic;
    }
    if ([fontStyle isEqualToString:@"ITALIC"]) {
        return GCKMediaTextTrackStyleFontStyleItalic;
    }
    return GCKMediaTextTrackStyleFontStyleNormal;
}

+ (GCKMediaTextTrackStyleWindowType)parseWindowType:(NSString *)windowType {
    if ([windowType isEqualToString:@"NORMAL"]) {
        return GCKMediaTextTrackStyleWindowTypeNormal;
    }
    if ([windowType isEqualToString:@"ROUNDED_CORNERS"]) {
        return GCKMediaTextTrackStyleWindowTypeRoundedCorners;
    }
    return GCKMediaTextTrackStyleWindowTypeUnknown;
}

+ (GCKMediaResumeState)parseResumeState:(NSString *)resumeState {
    if ([resumeState isEqualToString:@"PLAYBACK_PAUSE"]) {
        return GCKMediaResumeStatePause;
    }
    if ([resumeState isEqualToString:@"PLAYBACK_START"]) {
        return GCKMediaResumeStatePlay;
    }
    
    return GCKMediaResumeStateUnchanged;
}

+ (GCKMediaMetadataType)parseMediaMetadataType:(NSInteger)metadataType {
    switch (metadataType) {
        case 0:
            return GCKMediaMetadataTypeGeneric;
        case 1:
            return GCKMediaMetadataTypeTVShow;
        case 2:
            return GCKMediaMetadataTypeMovie;
        case 3:
            return GCKMediaMetadataTypeMusicTrack;
        case 4:
            return GCKMediaMetadataTypePhoto;
        default:
            return GCKMediaMetadataTypeGeneric;
    }
}

+ (NSString *)convertDictToJsonString:(NSDictionary *)dict {
    NSError *error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

+ (NSDictionary*)createError:(NSString*)code message:(NSString*)message {
    return @{@"code":code,@"description":message};
}
@end
