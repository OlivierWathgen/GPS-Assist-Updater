//
//  GPSAssistDataHandlerDelegate.h
//  DSC-HX5V GPSAssist Update
//

@protocol GPSAssistDataHandlerDelegate
-(void)gpsAssistDataAvailable:(NSData*)gpsAssistData date:(NSDate*)downloadDate;
-(void)gpsAssistDataFailed;
@end
