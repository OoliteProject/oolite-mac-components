#import "OOShipGroupTests.h"
#import "ShipEntity.h"
#import "OOShipGroup.h"


@implementation OOShipGroupTests

- (void) testBasicGrouping
{
	OOShipGroup *group = [[OOShipGroup alloc] initWithName:@"test testBasicGrouping"];
	
	ShipEntity *a = [[ShipEntity alloc] initWithName:@"A"];
	ShipEntity *b = [[ShipEntity alloc] initWithName:@"B"];
	ShipEntity *c = [[ShipEntity alloc] initWithName:@"C"];
	
	[group addShip:a];
	[group addShip:b];
	
	STAssertTrue([group containsShip:a], @"Ship group should contain exactly the ships added to it.");
	STAssertTrue([group containsShip:b], @"Ship group should contain exactly the ships added to it.");
	STAssertFalse([group containsShip:c], @"Ship group should contain exactly the ships added to it.");
	STAssertEquals(group.count, (NSUInteger)2, @"Ship group should contain exactly the ships added to it.");
	
	[group release];
	[a release];
	[b release];
	[c release];
}


- (void) testInvalidation
{
	OOShipGroup *group = [[OOShipGroup alloc] initWithName:@"testInvalidation group"];
	
	ShipEntity *a = [[ShipEntity alloc] initWithName:@"A"];
	ShipEntity *b = [[ShipEntity alloc] initWithName:@"B"];
	ShipEntity *c = [[ShipEntity alloc] initWithName:@"C"];
	
	[group addShip:a];
	[group addShip:b];
	[group addShip:c];
	
	STAssertEquals(group.count, (NSUInteger)3, @"After adding three ships to a group, it should contain three ships.");
	
	[a release];
	STAssertEquals(group.count, (NSUInteger)2, @"Releasing all strong references to a ship should remove it from any group it's in.");
	
	STAssertTrue([group containsShip:b], @"After purging a released ship, remaining strongly-referenced ships should still be members of the group.");
	STAssertTrue([group containsShip:c], @"After purging a released ship, remaining strongly-referenced ships should still be members of the group.");
	
	[b release];
	STAssertEquals(group.count, (NSUInteger)1, @"Releasing all strong references to a ship should remove it from any group it's in.");
	
	[c release];
	STAssertEquals(group.count, (NSUInteger)0, @"Releasing all strong references to a ship should remove it from any group it's in.");
	
	[group release];
}


- (void) testGrowth
{
	OOShipGroup *group = [[OOShipGroup alloc] initWithName:@"testGrowth group"];
	
	NSMutableArray *evenShips = [[NSMutableArray alloc] initWithCapacity:150];
	@autoreleasepool
	{
		// Main test here is that it doesn't crash.
		
		for (unsigned i = 0; i < 300; i++)
		{
			ShipEntity *s = [[ShipEntity alloc] initWithName:[NSString stringWithFormat:@"%u", i]];
			[group addShip:s];
			if ((i % 2) == 0)  [evenShips addObject:s];
			[s autorelease];
		}
		
		STAssertEquals(group.count, (NSUInteger)300, @"Adding 300 ships to a group should produce a group with 300 ships in it.");
	}
	
	STAssertEquals(group.count, (NSUInteger)150, @"Releasing half the ships in a group with 300 ships in should produce a group with 150 ships in it.");
	
	[evenShips release];
	
	STAssertEquals(group.count, (NSUInteger)0, @"Releasing half the ships in a group with 300 ships in should produce a group with 150 ships in it.");
	
	[group release];
}


- (void) testFastEnumeration
{
	OOShipGroup *group = [[OOShipGroup alloc] initWithName:@"testGrowth group"];
	
	NSMutableArray *evenShips = [[NSMutableArray alloc] initWithCapacity:150];
	@autoreleasepool
	{
		for (unsigned i = 0; i < 300; i++)
		{
			ShipEntity *s = [[ShipEntity alloc] initWithName:[NSString stringWithFormat:@"%u", i]];
			[group addShip:s];
			if ((i % 2) == 0)  [evenShips addObject:s];
			[s autorelease];
		}
	}
	
	NSUInteger count = 0;
	for (ShipEntity *s in group)
	{
		count++;
	}
	
	STAssertEquals(count, (NSUInteger)150, @"Fast iteration should hit every ship in a group once.");
	
	[evenShips release];
	[group release];
}

@end
