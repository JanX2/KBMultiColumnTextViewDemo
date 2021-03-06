//
//  KBMultiColumnTextView.m
//  -----------------------
//
//  Created by Keith Blount on 29/03/2006.
//  Copyright 2006 Keith Blount. All rights reserved.
//

#import "KBMultiColumnTextView.h"

NSString *KBMultiColumnTextViewDidAddColumnNotification = @"KBMultiColumnTextViewDidAddColumnNotification";
NSString *KBMultiColumnTextViewDidRemoveColumnNotification = @"KBMultiColumnTextViewDidRemoveColumnNotification";

/*************************** Private Methods ***************************/

#pragma mark -
#pragma mark Private Methods

@interface KBMultiColumnTextView (Private)
- (void)setupInitialTextViewSharedState;
- (void)addColumn;
- (void)removeColumn;
- (void)recalculateFrame;
- (void)resizeAllColumns;
- (void)rescaleTextView:(NSTextView *)aTextView;
- (void)textOfColumnDidChange:(NSNotification *)notification;
- (void)selectionDidChange:(NSNotification *)notification;
@end


@implementation KBMultiColumnTextView

@synthesize textViews;

/*************************** Init/Dealloc ***************************/

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
    {
		delegate = nil;
		self.textViews = [[NSArray alloc] init];
        [self setBackgroundColor:[NSColor whiteColor]];
		[self setColumnWidth:360.0f];
		[self setBorderSize:NSMakeSize(20.0f, 16.0f)];
		[self setScalePercent:100.0f];
		[self setTextViewClass:[NSTextView class]];
		
		// Create layout manager
		layoutManager = [[NSLayoutManager alloc] init];
		[layoutManager setDelegate:self];
		
		// Add first column and set up shared text view state
		[self addColumn];
		[self setupInitialTextViewSharedState];
		
		// Register as observer
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self
			   selector:@selector(textOfColumnDidChange:)
				   name:NSTextDidChangeNotification
				 object:nil];
		
		[nc addObserver:self
			   selector:@selector(selectionDidChange:)
				   name:NSTextViewDidChangeSelectionNotification
				 object:nil];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[layoutManager release];
	[backgroundColor release];
	self.textViews = nil;

	[super dealloc];
}

- (void)awakeFromNib
{
	// Make sure scroll view has same colour as our background
	if ([self enclosingScrollView] && backgroundColor)
		[[self enclosingScrollView] setBackgroundColor:backgroundColor];
}

/*************************** Accessors ***************************/

#pragma mark -
#pragma mark Accessors

- (NSLayoutManager *)layoutManager
{
	return [[layoutManager retain] autorelease];
}

- (NSTextStorage *)textStorage
{
	return [[[layoutManager textStorage] retain] autorelease];
}

- (NSTextView *)firstTextView
{
	return [[[layoutManager firstTextView] retain] autorelease];
}

- (NSInteger)numberOfColumns
{
	return [textViews count];
}

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- (id)delegate
{
	return delegate;
}

- (void)setBackgroundColor:(NSColor *)color
{
	[color retain];
	[backgroundColor release];
	backgroundColor = color;
	
	for (NSTextView *tv in textViews)
		[tv setBackgroundColor:backgroundColor];
	
	if ([self enclosingScrollView] != nil)
		[[self enclosingScrollView] setBackgroundColor:backgroundColor];
}

- (NSColor *)backgroundColor
{
	return backgroundColor;
}

- (void)setScalePercent:(CGFloat)percent
{
	scalePercent = percent;
	
	for (NSTextView *textView in textViews)
		[self rescaleTextView:textView];
}

- (CGFloat)scalePercent
{
	return scalePercent;
}

- (void)setTextViewClass:(Class)tvClass
{
	textViewClass = tvClass;
	
	// Go through and replace all text views with ones of the specified class
	NSMutableArray *newTextViews = [NSMutableArray arrayWithCapacity:[self.textViews count]];
	id newTextView;
	NSRect frame;
	for (NSTextView *textView in self.textViews)
	{
		frame = [textView frame];
		newTextView = [[textViewClass alloc] initWithFrame:frame
											 textContainer:[textView textContainer]];
		[self replaceSubview:textView with:newTextView];
		[self rescaleTextView:newTextView];
		[newTextViews addObject:newTextView];
	}
	self.textViews = newTextViews;
	
	// Ensure our attributes are still valid
	[self setupInitialTextViewSharedState];
}

- (Class)textViewClass
{
	return textViewClass;
}

- (void)setColumnWidth:(CGFloat)width
{
	columnWidth = width;
	[self resizeAllColumns];
}

- (CGFloat)columnWidth
{
	return columnWidth;
}

- (void)setBorderSize:(NSSize)size
{
	borderSize = NSMakeSize(size.width, size.height);
	[self resizeAllColumns];
}

- (NSSize)borderSize
{
	return borderSize;
}

/*************************** Private Methods ***************************/

#pragma mark -
#pragma mark Private Methods

- (void)setupInitialTextViewSharedState
{
	// Initialise the first text view (these attributes will get shared across text views
	NSTextView *textView = [self firstTextView];
	[textView setDelegate:self];
	[textView setSelectable:YES];
	[textView setEditable:YES];
	[textView setRichText:YES];
	[textView setImportsGraphics:YES];
	[textView setUsesFontPanel:YES];
	[textView setUsesRuler:YES];
	[textView setUsesFindPanel:YES];
	[textView setAllowsUndo:YES];
	[textView setAllowsDocumentBackgroundColorChange:YES];
}

- (void)rescaleTextView:(NSTextView *)aTextView
{
	CGFloat zoom = scalePercent / 100.0f;
	
	NSRect textViewBounds = [aTextView frame];
	textViewBounds.size.height = textViewBounds.size.height / zoom;
	textViewBounds.size.width = textViewBounds.size.width / zoom;
	[aTextView setBounds:textViewBounds];
	[aTextView sizeToFit];
	
	// We need to notifiy the clip view that the text view's size has changed to force rewrap
	[[NSNotificationCenter defaultCenter] postNotificationName:NSViewFrameDidChangeNotification
														object:aTextView];
	[aTextView setNeedsDisplayInRect:[aTextView visibleRect]];
}

- (void)resizeAllColumns
{
	NSRect frame;
	CGFloat xPos = 0.0f;
	for (NSTextView *textView in self.textViews)
	{
		frame = [self bounds];
		frame.origin.x = xPos;
		frame.size.width = columnWidth;
		frame = NSInsetRect(frame, borderSize.width, borderSize.height);
		[textView setFrame:frame];
	}
	[self recalculateFrame];
}

- (void)recalculateFrame
{
	if ([self.textViews count] < 1)	// This should never be the case...
		return;
	NSRect newFrame = [self frame];
	newFrame.size.width = NSMaxX([[self.textViews lastObject] frame]) + borderSize.width;
	
	[self setFrame:newFrame];
	[self setNeedsDisplay:YES];
}

- (void)addColumn
{
	NSTextContainer *textContainer;
    id textView;
	
    // Figure frame for NSTextView (and NSTextContainer size)
	NSRect frame = NSInsetRect([self bounds], borderSize.width, borderSize.height);
	frame.origin.x = ([self.textViews count] * columnWidth) + borderSize.width;
	frame.size.width = columnWidth - (borderSize.width * 2.0f);
	
    // Create and configure NSTextContainer
    textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(frame.size.width, frame.size.height)];
    [textContainer setWidthTracksTextView:YES];
    [textContainer setHeightTracksTextView:YES];
	
    // Create and configure NSTextView
    textView = [[textViewClass alloc] initWithFrame:frame textContainer:textContainer];
    [textView setMinSize:NSMakeSize(frame.size.width, frame.size.height)];
    [textView setMaxSize:NSMakeSize(frame.size.width, frame.size.height)];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:NO];
	
	if (scalePercent != 100.0f)
		[self rescaleTextView:textView];
	
    [self addSubview:textView];
	
	[layoutManager addTextContainer:textContainer];
    [textContainer release];
	
	NSMutableArray *tvs = [self.textViews mutableCopy];
	[tvs addObject:textView];
	self.textViews = tvs;
	[tvs release];

    [textView release];
	
	// Now need to recalculate own frame
	[self recalculateFrame];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:KBMultiColumnTextViewDidAddColumnNotification
														object:self];
}

- (void)removeColumn
{	
	[[self.textViews lastObject] removeFromSuperview];
    NSArray *textContainers = [layoutManager textContainers];
    [layoutManager removeTextContainerAtIndex:[textContainers count] - 1];
	
	NSMutableArray *tvs = [self.textViews mutableCopy];
	[tvs removeLastObject];
	self.textViews = tvs;
	[tvs release];
	
	// Now need to recalculate own frame
	[self recalculateFrame];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:KBMultiColumnTextViewDidRemoveColumnNotification
														object:self];
}

/*************************** NSView Overrides ***************************/

#pragma mark -
#pragma mark NSView Overrides

- (void)drawRect:(NSRect)rect
{
	// Just draw the background colour
    [backgroundColor set];
	[NSBezierPath fillRect:rect];
}

// Override -resizeSubviewsWithOldSize: and resize the text views manually - otherwise we can get
// out of bounds errors if super tries to handle resizing while columns are being added and removed dynamically.
- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	NSRect frame = NSInsetRect([self bounds], 0.0f, borderSize.height);
	frame.origin.x = 0.0f;
	frame.size.width = columnWidth - (borderSize.width * 2.0f);
	
	for (NSTextView *textView in self.textViews)
	{
		frame.origin.x += borderSize.width;
		[textView setFrame:frame];
		frame.origin.x += columnWidth - borderSize.width;
	}
}

// Don't have the text views resize during a live resize, as it can be too slow - they will get
// updated once the resize ends.

- (void)viewWillStartLiveResize
{
	for (NSTextView *tv in self.textViews)
		[tv setPostsFrameChangedNotifications:NO];
	
	[super viewWillStartLiveResize];
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	
	for (NSTextView *tv in self.textViews)
		[tv setPostsFrameChangedNotifications:YES];
}

/*************************** Layout Manager Delegate Methods ***************************/

#pragma mark -
#pragma mark Layout Manager Delegate Methods

// Taken from TextEdit
- (void)layoutManager:(NSLayoutManager *)lm didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag
{
	NSArray *containers = [layoutManager textContainers];
		
	if (!layoutFinishedFlag || (textContainer == nil))
	{
		// Either layout is not finished or it is but there are glyphs laid nowhere.
		NSTextContainer *lastContainer = [containers lastObject];
			
		if ((textContainer == lastContainer) || (textContainer == nil))
		{
			// Add a new column if the newly full container is the last container or the nowhere container.
			// Do this only if there are glyphs laid in the last container (temporary solution for 3729692, until AppKit makes something better available.)
			if ([layoutManager glyphRangeForTextContainer:lastContainer].length > 0)
				[self addColumn];
		}
	}
	else
	{
		// Layout is done and it all fit.  See if we can axe some columns.
		NSUInteger lastUsedContainerIndex = [containers indexOfObjectIdenticalTo:textContainer];
		NSUInteger numContainers = [containers count];
		while (++lastUsedContainerIndex < numContainers)
			[self removeColumn];
	}
}

/*************************** Notifications ***************************/

#pragma mark -
#pragma mark Notifications

// Show edited text view
// Note that we don't call this method -textDidChange:, because we want the delegate to be
// able to handle that method.
- (void)textOfColumnDidChange:(NSNotification *)notification
{
	id sender = [notification object];
	
	if (![self.textViews containsObject:sender])
		return;
	
	// This is a fix for a problem that also occurs in TextEdit...
	if ([[layoutManager textStorage] length] == 0)
		while ([self.textViews count] > 1) [self removeColumn];
	
	// If we the text has been moved into a different text view, make sure it becomes fully visible
	NSRect frame = [[layoutManager textViewForBeginningOfSelection] frame];
	if (!NSContainsRect([self visibleRect],frame))
	{
		frame = NSInsetRect(frame,-borderSize.width,-borderSize.height);
		[self scrollRectToVisible:frame];
	}
}

// If cursor is being moved, ensure affected text view is made visible
- (void)selectionDidChange:(NSNotification *)notification
{
	id sender = [notification object];
	
	if (![self.textViews containsObject:sender])
		return;
	
	// If none of the given text view is visible, make it visible
	// (Note that we don't want make the whole text view visible if the user has only clicked on it,
	// but only if the user has moved the cursor while the text view is off screen.)
	if ([[sender selectedRanges] count] != 1)
		return;
	
	NSRange selectedRange = [[[sender selectedRanges] objectAtIndex:0] rangeValue];
	if (selectedRange.length != 0)
		return;
	
	NSArray *containers = [layoutManager textContainers];
	NSTextContainer *tc = nil;
	
	if (selectedRange.location == [[layoutManager textStorage] length])
	{
		tc = [containers lastObject];
	}
	else
	{
		NSInteger glyphIndex = [layoutManager glyphRangeForCharacterRange:selectedRange
										   actualCharacterRange:nil].location;
		tc = [layoutManager textContainerForGlyphAtIndex:glyphIndex
										  effectiveRange:nil
								 withoutAdditionalLayout:YES];
	}
	
	NSUInteger thisIndex = [containers indexOfObject:tc];
	if (thisIndex >= [self.textViews count])
		return;
	
	NSTextView *tv = [self.textViews objectAtIndex:thisIndex];
	NSRect frame = [tv frame];
	if (!NSContainsRect([self visibleRect],frame))
	{
		frame = NSInsetRect(frame,-borderSize.width,-borderSize.height);
		[self scrollRectToVisible:frame];
	}
}

/*************************** Text View Delegate Methods ***************************/

#pragma mark -
#pragma mark Text View Delegate Methods

// Handle scrolling using page up and page down
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (![self.textViews containsObject:aTextView])
		return NO;
	
	if (aSelector == @selector(scrollPageDown:))
	{
		NSRect frame = [self visibleRect];
		frame.origin.x += (columnWidth - ((NSInteger)frame.origin.x % (NSInteger)columnWidth));
		[self scrollRectToVisible:frame];
		return YES;
	}
	
	else if (aSelector == @selector(scrollPageUp:))
	{
		NSRect frame = [self visibleRect];
		frame.origin.x -= columnWidth - (columnWidth - ((NSInteger)frame.origin.x % (NSInteger)columnWidth));
		// If we haven't moved, leap back another column
		if (frame.origin.x == [self visibleRect].origin.x)
			frame.origin.x -= columnWidth;
		[self scrollRectToVisible:frame];
		return YES;
	}
	
	// Give delegate the opportunity to handle other commands
	if ([delegate respondsToSelector:@selector(textView:doCommandBySelector:)])
		return [delegate textView:aTextView doCommandBySelector:aSelector];
	
	return NO;
}

/**** Forward unhandled delegate messages to our delegate ****/

- (BOOL)respondsToSelector:(SEL)selector
{
	return [super respondsToSelector:selector] ? YES : [delegate respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation*)theInvocation
{
	if ([delegate respondsToSelector:[theInvocation selector]])
		[theInvocation invokeWithTarget:delegate];
	else
		[super forwardInvocation:theInvocation];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{
	NSMethodSignature* signature=[super methodSignatureForSelector:selector];
	if (!signature)
		signature=[delegate methodSignatureForSelector:selector];
	return signature;
}

@end
