//
//  GPSAssistDataHandlerDelegate.h
//  GPS Assist Updater
//

@protocol GPSAssistDataHandlerDelegate
- (void)gpsAssistDataAvailable:(NSData*)gpsAssistData date:(NSDate*)downloadDate;
- (void)gpsAssistDataFailed;
@end
