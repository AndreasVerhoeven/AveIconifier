//
//  AveDragDropImageView.m
//  AveIconifier
//
//  Created by Andreas Verhoeven on 05-11-13.
//  Copyright (c) 2013 AveApps. All rights reserved.
//

#import "AveDragDropImageView.h"

@implementation AveDragDropImageView

@synthesize allowDrag;
@synthesize allowDrop;
@synthesize delegate;

- (id)initWithCoder:(NSCoder *)coder
{
    /*------------------------------------------------------
	 Init method called for Interface Builder objects
	 --------------------------------------------------------*/
    self=[super initWithCoder:coder];
    if ( self ) {
		//register for all the image types we can display
        [self registerForDraggedTypes:[NSImage imagePasteboardTypes]];
        self.allowDrag = YES;
        self.allowDrop = NO;
    }
    return self;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] != self )
	{
        [self processPasteBoard:[sender draggingPasteboard]];
    }
    
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame;
{
    /*------------------------------------------------------
	 delegate operation to set the standard window frame
	 --------------------------------------------------------*/
	//get window frame size
    NSRect ContentRect=self.window.frame;
    
	//set it to the image frame size
    ContentRect.size=[[self image] size];
    
    return [NSWindow frameRectForContentRect:ContentRect styleMask: [window styleMask]];
};

#pragma mark - Source Operations
-(void)copy:(id)sender
{
	NSData *imageData = [self.image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
	
	NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSPasteboardTypePNG, NSFilenamesPboardType, nil] owner:self];
	[pasteboard setData:imageData forType:NSPasteboardTypePNG];
	
	
	NSString* appTempDir = NSTemporaryDirectory();
	appTempDir = [appTempDir stringByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier];
	NSString* guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString* tempDir = [appTempDir stringByAppendingPathComponent:guid];
	
	// clean out old files
	NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appTempDir error:nil];
	for (NSString *filename in fileArray)
	{
		[[NSFileManager defaultManager] removeItemAtPath:[appTempDir stringByAppendingPathComponent:filename] error:NULL];
	}
	

	// ensure our bundle temp dir exists
    if(![[NSFileManager defaultManager] fileExistsAtPath:tempDir])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	// create the files in our temp dir, so copying will give nice names
	NSArray* files = [self namesOfPromisedFilesDroppedAtDestination:[NSURL fileURLWithPath:tempDir isDirectory:YES]];
	NSMutableArray* fullPaths = [NSMutableArray arrayWithCapacity:[files count]];
	for(NSString* file in files)
	{
		[fullPaths addObject:[tempDir stringByAppendingPathComponent:file]];
	}
	[pasteboard setPropertyList:fullPaths forType:NSFilenamesPboardType];
}

-(void)processPasteBoard:(NSPasteboard*)pasteboard
{
	if([NSImage canInitWithPasteboard:pasteboard])
	{
		self.image = [[NSImage alloc] initWithPasteboard:pasteboard];
	}
	
	//if the drag comes from a file, set the window title to the filename
	NSURL* fileURL = [NSURL URLFromPasteboard: pasteboard];
	if ([self.delegate respondsToSelector:@selector(aveDragDropImageView:dropComplete:)])
	{
		[self.delegate aveDragDropImageView:self dropComplete:[fileURL path]];
	}
}

-(void)paste:(id)sender
{
	NSArray *classes = [NSArray arrayWithObject:[NSURL class]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSImage imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
	NSArray *imageURLs = [[NSPasteboard generalPasteboard] readObjectsForClasses:classes options:options];
	if([imageURLs count] > 0)
	{
		NSURL* url = [imageURLs objectAtIndex:0];
		self.image = [[NSImage alloc] initWithContentsOfURL:url];
		
		if ([self.delegate respondsToSelector:@selector(aveDragDropImageView:dropComplete:)])
		{
			[self.delegate aveDragDropImageView:self dropComplete:[url path]];
		}
	}
	else
	{
		[self processPasteBoard:[NSPasteboard generalPasteboard]];
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[NSApp sendAction:[self action] to:[self target] from: self];
#pragma clang diagnostic pop
}

-(void)rightMouseUp:(NSEvent *)theEvent
{
	NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
	
	[self becomeFirstResponder];
	if(self.isEditable)
	{
		NSMenuItem* pasteItem = [theMenu insertItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"" atIndex:0];
		[pasteItem setEnabled:[NSImage canInitWithPasteboard:[NSPasteboard generalPasteboard]]];
	}
	
	
    NSMenuItem* copyItem = [theMenu insertItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"" atIndex:0];
	[copyItem setTarget:self];
	[copyItem setEnabled:self.image != nil];
	
	[theMenu setAutoenablesItems:NO];
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
}

- (void)mouseDown:(NSEvent*)event
{
    if (self.allowDrag && self.image) {
        NSPoint dragPosition;
        NSRect imageLocation;
        
        dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
        dragPosition.x -= 16;
        dragPosition.y -= 16;
        imageLocation.origin = dragPosition;
        imageLocation.size = NSMakeSize(32,32);
        [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:NSPasteboardTypeTIFF] fromRect:imageLocation source:self slideBack:YES event:event];
    }
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation offset:(NSSize)initialOffset event:(NSEvent *)event pasteboard:(NSPasteboard *)pboard source:(id)sourceObj slideBack:(BOOL)slideFlag
{
    //create a new image for our semi-transparent drag image
    NSImage* dragImage=[[NSImage alloc] initWithSize:[[self image] size]];
    
    [dragImage lockFocus];//draw inside of our dragImage
						  //draw our original image as 50% transparent
    [[self image] drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, self.image.size.width, self.image.size.height) operation:NSCompositeCopy fraction:0.5];
    [dragImage unlockFocus];//finished drawing
    [dragImage setScalesWhenResized:NO];//we want the image to resize
    [dragImage setSize:[self bounds].size];//change to the size we are displaying
    
    [super dragImage:dragImage at:self.bounds.origin offset:NSZeroSize event:event pasteboard:pboard source:sourceObj slideBack:slideFlag];
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	if([self.delegate respondsToSelector:@selector(aveDragDropImageView:writeImagesToPath:)])
	{
		return [self.delegate aveDragDropImageView:self writeImagesToPath:dropDestination.path];
	}
	else
	{
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [[self image] representations];
		
		if ([[[representations objectAtIndex:0] className] isEqualToString:@"NSBitmapImageRep"]) {
			bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations
																  usingType:NSPNGFileType properties:nil];
		} else {
			NSLog(@"%@", [[[[self image] representations] objectAtIndex:0] className]);
			
			[[self image] lockFocus];
			NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [self image].size.width, self.image.size.height)];
			[[self image] unlockFocus];
			
			bitmapData = [bitmapRep TIFFRepresentation];
		}
		
		[bitmapData writeToFile:[[dropDestination path] stringByAppendingPathComponent:@"Output.png"]  atomically:YES];
		return [NSArray arrayWithObjects:@"Output.png", nil];
	}
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    /*------------------------------------------------------
     NSDraggingSource protocol method.  Returns the types of operations allowed in a certain context.
     --------------------------------------------------------*/
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
            //by using this fall through pattern, we will remain compatible if the contexts get more precise in the future.
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationCopy;
            break;
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    /*------------------------------------------------------
	 accept activation click as click in window
	 --------------------------------------------------------*/
	//so source doesn't have to be the active window
    return YES;
}

- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    /*------------------------------------------------------
	 method called by pasteboard to support promised
	 drag types.
	 --------------------------------------------------------*/
	//sender has accepted the drag and now we need to send the data for the type we promised
    if ( [type compare: NSPasteboardTypeTIFF] == NSOrderedSame ) {
        
		//set data for TIFF type on the pasteboard as requested
        [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
        
    } else if ( [type compare: NSPasteboardTypePDF] == NSOrderedSame ) {
        
		//set data for PDF type on the pasteboard as requested
        [sender setData:[self dataWithPDFInsideRect:[self bounds]] forType:NSPasteboardTypePDF];
    }
    
}
@end
