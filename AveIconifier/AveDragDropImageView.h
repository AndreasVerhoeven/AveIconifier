//
//  AveDragDropImageView.h
//  AveIconifier
//
//  Created by Andreas Verhoeven on 05-11-13.
//  Copyright (c) 2013 AveApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AveDragDropImageViewDelegate;

@interface AveDragDropImageView : NSImageView <NSDraggingSource, NSDraggingDestination, NSPasteboardItemDataProvider>

@property (assign) BOOL allowDrag;
@property (assign) BOOL allowDrop;
@property (assign) IBOutlet id<AveDragDropImageViewDelegate> delegate;
@property (copy) NSString* droppedFileName;

- (id)initWithCoder:(NSCoder *)coder;

@end

@protocol AveDragDropImageViewDelegate <NSObject>

@optional
-(void)aveDragDropImageView:(AveDragDropImageView*)imageView dropComplete:(NSString *)filePath;
-(NSArray*)aveDragDropImageView:(AveDragDropImageView*)imageView writeImagesToPath:(NSString*)path;

@end