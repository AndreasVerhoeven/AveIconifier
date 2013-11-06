//
//  AveAppDelegate.h
//  AveIconifier
//
//  Created by Andreas Verhoeven on 05-11-13.
//  Copyright (c) 2013 AveApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AveDragDropImageView.h"

typedef enum
{
	AveIconMode7Retina,
	AveIconMode7Normal,
	AveIconMode6Retina,
	AveIconMode6Normal,
	
} AveIconMode;

@interface AveAppDelegate : NSObject <NSApplicationDelegate, AveDragDropImageViewDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, assign) AveIconMode iosMode;
@property (nonatomic, copy) NSString* fileName;

@property (assign) IBOutlet AveDragDropImageView* fromImageWell;
@property (assign) IBOutlet AveDragDropImageView* toImageWell;

- (IBAction)imageWasDroppedOnFrom:(id)sender;

@end
