#import "ShipEntity.h"


@implementation Entity

- (void) dealloc
{
	[_owner release];
	
	[super dealloc];
}


- (Entity *) owner
{
	return [_owner weakRefUnderlyingObject];
}


- (void) setOwner:(Entity *)owner
{
	[_owner release];
	_owner = [owner weakRetain];
}

@end


@implementation ShipEntity

@synthesize name = _name;
@synthesize group = _group;


- (id) initWithName:(NSString *)name
{
	if ((self = [super init]))
	{
		_name = [name copy];
	}
	return self;
}


- (NSString *) description
{
	return self.name;
}


- (void) dealloc
{
	[_name release];
	[_group release];
	
	[super dealloc];
}


- (BOOL) isEqual:(id)other
{
	if (![other isKindOfClass:[ShipEntity class]])  return NO;
	
	return [[other name] isEqual:self.name];
}

@end
