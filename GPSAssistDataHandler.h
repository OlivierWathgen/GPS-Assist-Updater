//
//  GPSAssistDataHandler.h
//  DSC-HX5V GPSAssist Update
//
//	Handles the gpsassist-data. Get new data from server if needed.
//

#import <Cocoa/Cocoa.h>
#import "GPSAssistDataHandlerDelegate.h"

typedef enum{
	DOWNLOAD_IDLE,
	DOWNLOAD_DATA,
	DOWNLOAD_MD5
} DOWNLOAD_STEP;

@interface GPSAssistDataHandler : NSObject {
	NSMutableSet *delegates;
	NSData *gpsAssistData;
	NSDate *downloadDate;
	NSURLConnection *urlConnection;
	DOWNLOAD_STEP downloadStep;
	NSMutableData *receivedData;
}

-(void)stop;
-(void)getGpsAssistData:(id<GPSAssistDataHandlerDelegate>)delegate;
-(void)cancelGetGpsAssistData:(id<GPSAssistDataHandlerDelegate>)delegate;

@end
