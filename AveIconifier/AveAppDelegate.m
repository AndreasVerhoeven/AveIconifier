//
//  AveAppDelegate.m
//  AveIconifier
//
//  Created by Andreas Verhoeven on 05-11-13.
//  Copyright (c) 2013 AveApps. All rights reserved.
//

#import "AveAppDelegate.h"

@implementation AveAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.fromImageWell.allowDrag = NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

-(void)openDocument:(id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowedFileTypes:[NSImage imageTypes]];
	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if(result == NSFileHandlingPanelOKButton)
		{
			self.fromImageWell.image = [[NSImage alloc] initWithContentsOfURL:panel.URL];
			self.fileName = [self outputFileNameFromOptionsForPath:[panel.URL path]];
			[self maskFromImageAccordingToOptions];
		}
	}];
}

-(void)saveDocument:(id)sender
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setNameFieldStringValue:[self fixupFilename]];
	[panel setAllowedFileTypes:@[@"png"]];
	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if(result == NSFileHandlingPanelOKButton)
		{
			[self saveImageToPath:panel.URL.path];
		}
	}];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(saveDocument:))
	{
		return self.toImageWell.image != nil;
	}
	
	return YES;
}

- (IBAction)imageWasDroppedOnFrom:(id)sender
{
	[self maskFromImageAccordingToOptions];
}

-(void)setIosMode:(AveIconMode)iosMode
{
	if(_iosMode != iosMode)
	{
		NSString* prefEndName = [self outputEndNameFromOptions];
		
		_iosMode = iosMode;
		[self maskFromImageAccordingToOptions];
		NSString* file = self.fileName;
		file = [file stringByReplacingOccurrencesOfString:prefEndName withString:@""];
		self.fileName = [self outputFileNameFromOptionsForPath:file];
	}
}

-(NSString*)maskNameFromOptions
{
	switch(self.iosMode)
	{
		case AveIconMode6Normal: return @"IconMask6";
		case AveIconMode6Retina: return @"IconMask6-Retina";
		case AveIconMode7Normal: return @"IconMask7";
		default:
		case AveIconMode7Retina: return @"IconMask7-Retina";
			
	}
}

-(NSString*)outputEndNameFromOptions
{
	switch(self.iosMode)
	{
		case AveIconMode6Normal: return @".png";
		case AveIconMode6Retina: return @"@2x.png";
		case AveIconMode7Normal: return @"7.png";
		default:
		case AveIconMode7Retina: return @"7@2x.png";
			
	}
}

-(NSString*)outputFileNameFromOptionsForPath:(NSString*)path
{
	path = [path lastPathComponent];
	path = [path stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
	return [[path stringByDeletingPathExtension] stringByAppendingString:self.outputEndNameFromOptions];
}

-(void)aveDragDropImageView:(AveDragDropImageView *)imageView dropComplete:(NSString *)filePath
{
	if(imageView == self.fromImageWell)
	{
		self.fileName = [self outputFileNameFromOptionsForPath:filePath];
	}
}

-(void)saveImageToPath:(NSString*)path
{
	NSImage* img = [self maskFromImageWithMaskName:self.maskNameFromOptions];
    NSData *imageData = [img TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:path atomically:NO];
}

-(NSString*)fixupFilename
{
	NSString* name = [self.fileName length] > 0 ? self.fileName : [self outputFileNameFromOptionsForPath:@"Output.png"];
	if([name rangeOfString:@".png"].location == NSNotFound)
		name = [self outputFileNameFromOptionsForPath:name];
	
	return name;
}

-(NSArray*)aveDragDropImageView:(AveDragDropImageView *)imageView writeImagesToPath:(NSString *)path
{
	NSString* name = [self fixupFilename];
	path = [path stringByAppendingPathComponent:name];
	[self saveImageToPath:path];

	return @[name];
}

-(void)maskFromImageAccordingToOptions
{
	self.toImageWell.image = [self maskFromImageWithMaskName:self.maskNameFromOptions];
}

-(NSImage*)maskFromImageWithMaskName:(NSString*)maskName
{
	NSImage* from = self.fromImageWell.image;
	NSImage* mask = [NSImage imageNamed:maskName];
	CGImageRef maskRef = [mask CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];
	CGImageRef bwMaskRef = CGImageMaskCreate(CGImageGetWidth(maskRef), CGImageGetHeight(maskRef), CGImageGetBitsPerComponent(maskRef), CGImageGetBitsPerPixel(maskRef), CGImageGetBytesPerRow(maskRef), CGImageGetDataProvider(maskRef), NULL, YES);

	
	NSSize size = mask.size;
	CGRect rc = CGRectMake(0, 0, size.width, size.height);
	
	NSImage* output = [[NSImage alloc] initWithSize:size];
	NSBitmapImageRep* representation = [[NSBitmapImageRep alloc]
								 initWithBitmapDataPlanes:NULL
								 pixelsWide:size.width
								 pixelsHigh:size.height
								 bitsPerSample:8
								 samplesPerPixel:4
								 hasAlpha:YES
								 isPlanar:NO
								 colorSpaceName:NSCalibratedRGBColorSpace
								 bytesPerRow:0
								 bitsPerPixel:0];
	
	[output addRepresentation:representation];
	[output lockFocus];
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	//CGImageRef maskCGImage = [mask CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];
	CGContextClipToMask(context, rc, bwMaskRef);
	[from drawInRect:rc];
	
	[output unlockFocus];
	return output;
}

@end
