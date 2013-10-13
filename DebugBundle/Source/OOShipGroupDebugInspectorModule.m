/*

OOShipGroupDebugInspectorModule.m


Oolite Debug Bundle

Copyright © 2007-2009 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOShipGroupDebugInspectorModule.h"
#import "OOEntityInspectorExtensions.h"
#import "OOShipGroup.h"


@implementation OOShipGroupDebugInspectorModule

- (void) awakeFromNib
{
	[membersList setDoubleAction:[membersList action]];
	[membersList setAction:NULL];
}


- (void) update
{
	OOShipGroup			*object = [self object];
	NSString			*placeholder = InspectorUnknownValueString();
	NSEnumerator		*memberEnum = nil;
	ShipEntity			*member = nil;
	NSMutableArray		*members = nil;
	
	[leaderField setStringValue:[[object leader] inspDescription] ?: placeholder];
	
	// Make array of weakRefs to group members.
	members = [NSMutableArray array];
	for (memberEnum = [object objectEnumerator]; (member = [memberEnum nextObject]); )
	{
		id memberRef = [member weakRetain];
		[members addObject:memberRef];
		[memberRef release];
	}
	
	// Sort array.
	[members sortUsingSelector:@selector(ooCompareByPointerValue:)];
	if (![_members isEqualToArray:members])
	{
		[_members release];
		_members = [members copy];
		[membersList reloadData];
	}
}


- (IBAction) inspectLeader:(id)sender
{
	[[[self object] leader] inspect];
}


- (IBAction) inspectMember:(id)sender
{
	NSInteger clickedRow = [sender clickedRow];
	if (clickedRow < 0)  return;
	
	[[_members objectAtIndex:clickedRow] inspect];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_members count];
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[_members objectAtIndex:row] inspDescription];
}

@end


@implementation OOShipGroup (OOInspectorExtensions)

- (NSString *) inspDescription
{
	NSString *name = [self name];
	if (name != nil)  name = [NSString stringWithFormat:@"\"%@\"", name];
	else  name = @"anonymous";
	
	return [NSString stringWithFormat:@"%@, %lu ships", name, [self count]];
}


- (NSString *) inspBasicIdentityLine
{
	NSString *name = [self name];
	if (name != nil)  return [NSString stringWithFormat:@"Group \"%@\"", name];
	else  return @"Anonymous group";
}


- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOShipGroupDebugInspectorModule class]
																	forObject:(id)self];
}

@end


@implementation NSObject (OOCompareByPointerValue)

- (NSComparisonResult) ooCompareByPointerValue:(id)other
{
	if ((uintptr_t)self < (uintptr_t)other)  return NSOrderedAscending;
	if ((uintptr_t)self > (uintptr_t)other)  return NSOrderedDescending;
	return NSOrderedSame;
}

@end
