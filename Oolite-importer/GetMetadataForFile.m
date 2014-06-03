/*

GetMetadataForFile.m

Spotlight metadata importer for Oolite
Copyright (C) 2005-2010 Jens Ayton

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <stdarg.h>
#import "NSScannerOOExtensions.h"
#import "OOCollectionExtractors.h"
#import "NSDataOOExtensions.h"


#define kTitle				(NSString *)kMDItemTitle
#define kAuthors			(NSString *)kMDItemAuthors
#define kVersion			(NSString *)kMDItemVersion
#define kCopyright			(NSString *)kMDItemCopyright
#define kIdentifier			(NSString *)kMDItemIdentifier
#define kDescription		(NSString *)kMDItemDescription
#define kURL				(NSString *)kMDItemURL
#define kTextContent		(NSString *)kMDItemTextContent
#define kShipIDs			@"org_aegidian_oolite_shipids"
#define kShipClassNames		@"org_aegidian_oolite_shipclassnames"
#define kShipRoles			@"org_aegidian_oolite_shiproles"
#define kShipModels			@"org_aegidian_oolite_shipmodels"
#define kCombatRating		@"org_aegidian_oolite_combatrating"
#define kSystemName			@"org_aegidian_oolite_systemname"
#define kMinOoliteVersion	@"org_aegidian_oolite_minversion"
#define kMaxOoliteVersion	@"org_aegidian_oolite_maxversion"


static bool GetMetadataForSaveFile(void *thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);
static bool GetMetadataForExpansionPack(void *thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);

static id GetBundlePropertyList(NSString *inPListName);
static NSDictionary *ConfigDictionary(NSString *basePath, NSString *name);
static NSDictionary *MergeShipData(NSDictionary *shipData, NSDictionary *shipDataOverrides);
static NSDictionary *MergeShipDataEntry(NSDictionary *baseDict, NSDictionary *overrideDict);

static NSDictionary *OOParseRolesFromString(NSString *string);
static NSMutableArray *ScanTokensFromString(NSString *values);


/*
	NOTE: this prototype differs from the one declared in main.c (which is mostly unmodified
	Apple boilerplate code), but the types are entirely compatible.
*/
BOOL GetMetadataForFile(void *thisInterface,
			   NSMutableDictionary *attributes, 
			   CFStringRef contentTypeUTI,
			   NSString *pathToFile)
{
	@autoreleasepool
	{
		@try
		{
			if (UTTypeConformsTo(contentTypeUTI, CFSTR("org.aegidian.oolite.save")))
			{
				return GetMetadataForSaveFile(thisInterface, attributes, pathToFile);
			}
			if (UTTypeConformsTo(contentTypeUTI, CFSTR("org.aegidian.oolite.expansion")))
			{
				return GetMetadataForExpansionPack(thisInterface, attributes, pathToFile);
			}
		}
		@catch (id any)
		{
			return false;
		}
	}
}

static bool GetMetadataForSaveFile(void *thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	NSDictionary *content = [NSDictionary dictionaryWithContentsOfFile:pathToFile];
	if (content == nil)  return false;
	
	NSString *playerName = [content oo_stringForKey:@"player_name"];
	if (playerName != nil)  attributes[kTitle] = playerName;
	
	NSString *shipDesc = [content oo_stringForKey:@"ship_desc"];
	if (shipDesc != nil)  attributes[kShipIDs] = shipDesc;
	
	NSString *shipName = [content oo_stringForKey:@"ship_name"];
	if (shipName != nil)  attributes[kShipClassNames] = shipName;
	
	NSString *currentSystemName = [content oo_stringForKey:@"current_system_name"];
	if (currentSystemName != nil)  attributes[kSystemName] = currentSystemName;
	
	NSArray *commLog = [content oo_arrayForKey:@"comm_log"];
	if (commLog.count != 0)  attributes[kTextContent] = [commLog componentsJoinedByString:@"\n"];
	
	NSInteger killCount = [content oo_integerForKey:@"ship_kills"];
	if (killCount > 0)
	{
		NSArray *ratings = GetBundlePropertyList(@"Values")[@"ratings"];
		if (ratings != nil)
		{
			int rating = 0;
			const int kRequiredKills[8] = { 0x0008,  0x0010,  0x0020,  0x0040,  0x0080,  0x0200,  0x0A00,  0x1900 };
			
			while (rating < 8 && kRequiredKills[rating] <= killCount)
			{
				rating ++;
			}
			
			attributes[kCombatRating] = ratings[rating];
		}
	}
	
	return true;
}


static bool GetMetadataForExpansionPack(void *thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	NSDictionary *manifest = ConfigDictionary(pathToFile, @"manifest.plist");
	if (manifest != nil)
	{
		NSString *title = [manifest oo_stringForKey:@"title"];
		if (title != nil)  attributes[kTitle] = title;
		
		NSString *identifier = [manifest oo_stringForKey:@"identifier"];
		if (identifier != nil)  attributes[kIdentifier] = identifier;
		
		NSString *version = [manifest oo_stringForKey:@"version"];
		if (version != nil)  attributes[kVersion] = version;
		
		// Allow a string or array for author
		id author = manifest[@"author"];
		if ([author isKindOfClass:NSString.class])  author = @[author];
		if ([author isKindOfClass:NSArray.class])  attributes[kAuthors] = author;
		
		NSString *description = [manifest oo_stringForKey:@"description"];
		if (description != nil)  attributes[kDescription] = description;
		
		NSString *copyright = [manifest oo_stringForKey:@"copyright"];
		if (copyright == nil)  copyright = [manifest oo_stringForKey:@"license"];
		if (copyright != nil)  attributes[kCopyright] = copyright;
		
		NSString *url = [manifest oo_stringForKey:@"download_url"];
		if (url == nil)  url = [manifest oo_stringForKey:@"information_url"];
		if (url != nil)  attributes[kURL] = url;
		
		NSString *minVersion = [manifest oo_stringForKey:@"required_oolite_version"];
		if (minVersion != nil)  attributes[kMinOoliteVersion] = minVersion;
	}
	else
	{
		// No manifest, look for requires.plist
		
		NSDictionary *requires = ConfigDictionary(pathToFile, @"requires.plist");
		if (requires != nil)
		{
			NSString *minVersion = [requires objectForKey:@"version"];
			if (minVersion != nil)  attributes[kMinOoliteVersion] = minVersion;
			
			NSString *maxVersion = [requires objectForKey:@"max_version"];
			if (maxVersion != nil)  attributes[kMaxOoliteVersion] = maxVersion;
		}
		
		// Not "officially" supported, but exists in some OXPs.
		NSDictionary *infoPList = ConfigDictionary(pathToFile, @"Info.plist");
		NSString *version = [infoPList oo_stringForKey:@"CFBundleVersion"];
		if (version != nil)  attributes[kVersion] = version;
	}
	
	NSDictionary *shipData = ConfigDictionary(pathToFile, @"shipdata.plist");
	NSDictionary *shipDataOverrides = ConfigDictionary(pathToFile, @"shipdata-overrides.plist");
	shipData = MergeShipData(shipData, shipDataOverrides);
	
	if (shipData.count != 0)
	{
		NSMutableSet *shipNames = [NSMutableSet setWithCapacity:shipData.count];
		NSMutableSet *shipModels = [NSMutableSet setWithCapacity:shipData.count];
		NSMutableSet *shipRoles = [NSMutableSet new];
		
		attributes[kShipIDs] = shipData.allKeys;
		
		for (NSDictionary *ship in shipData)
		{
			if (![ship isKindOfClass:NSDictionary.class])  continue;
			
			NSString *name = [ship oo_stringForKey:@"name"];
			if (name != nil)  [shipNames addObject:name];
			
			NSString *model = [ship oo_stringForKey:@"model"];
			if (model != nil)  [shipModels addObject:model];
			
			NSString *role = [ship oo_stringForKey:@"roles"];
			if (role != nil)  [shipRoles addObjectsFromArray:OOParseRolesFromString(role).allKeys];
		}
		
		attributes[kShipClassNames] = shipNames.allObjects;
		attributes[kShipModels] = shipModels.allObjects;
		attributes[kShipRoles] = shipRoles.allObjects;
	}
	
	return YES;
}


#pragma mark -
#pragma mark Helper functions

static id GetBundlePropertyList(NSString *inPListName)
{
	NSBundle *bundle = [NSBundle bundleWithIdentifier:@"org.aegidian.oolite.md-importer"];
	NSString *path = [bundle pathForResource:inPListName ofType:@"plist"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	return [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
}


static NSDictionary *ConfigDictionary(NSString *basePath, NSString *name)
{
	NSString *path = [[basePath stringByAppendingPathComponent:@"Config"] stringByAppendingPathComponent:name];
	NSData *data = [NSData oo_dataWithOXZFile:path];
	if (data == nil)
	{
		path = [basePath stringByAppendingPathComponent:name];
		data = [NSData oo_dataWithOXZFile:path];
	}
	if (data != nil)
	{
		id plist = [NSPropertyListSerialization propertyListWithData:data
															 options:0
															  format:NULL
															   error:NULL];
		if ([plist isKindOfClass:NSDictionary.class])  return plist;
	}
	
	return nil;
}


static NSDictionary *MergeShipData(NSDictionary *shipData, NSDictionary *shipDataOverrides)
{
	NSDictionary			*baseDict = nil;
	NSDictionary			*overrideDict = nil;
	
	if (shipDataOverrides == nil)  return shipData;
	if (shipData == nil)  return shipDataOverrides;
	
	NSMutableDictionary *mutableShipData = [NSMutableDictionary dictionaryWithDictionary:shipData];
	for (NSString *key in shipDataOverrides)
	{
		baseDict = [shipData oo_dictionaryForKey:key];
		overrideDict = [shipDataOverrides oo_dictionaryForKey:key];
		mutableShipData[key] = MergeShipDataEntry(baseDict, overrideDict);
	}
	
	return mutableShipData;
}


static NSDictionary *MergeShipDataEntry(NSDictionary *baseDict, NSDictionary *overrideDict)
{
	if (baseDict == nil)  return overrideDict;
	
	NSMutableDictionary *mutableEntry = [NSMutableDictionary dictionaryWithDictionary:baseDict];
	[mutableEntry addEntriesFromDictionary:overrideDict];
	
	return mutableEntry;
}


// Stuff lifted from messy files in Oolite

static NSDictionary *OOParseRolesFromString(NSString *string)
{
	NSMutableDictionary		*result = nil;
	NSArray					*tokens = nil;
	unsigned				i, count;
	NSString				*role = nil;
	float					probability;
	NSScanner				*scanner = nil;
	
	// Split string at spaces, sanity checks, set-up.
	if (string == nil)  return nil;
	
	tokens = ScanTokensFromString(string);
	count = [tokens count];
	if (count == 0)  return nil;
	
	result = [NSMutableDictionary dictionaryWithCapacity:count];
	
	// Scan tokens, looking for probabilities.
	for (i = 0; i != count; ++i)
	{
		role = [tokens objectAtIndex:i];
		
		probability = 1.0f;
		if ([role rangeOfString:@"("].location != NSNotFound)
		{
			scanner = [[NSScanner alloc] initWithString:role];
			[scanner scanUpToString:@"(" intoString:&role];
			[scanner scanString:@"(" intoString:NULL];
			if (![scanner scanFloat:&probability])	probability = 1.0f;
			// Ignore rest of string
		}
		
		// shipKey roles start with [ so other roles can't
		if (0 <= probability && ![role hasPrefix:@"["])
		{
			[result setObject:[NSNumber numberWithFloat:probability] forKey:role];
		}
	}
	
	if ([result count] == 0)  result = nil;
	return result;
}


static NSMutableArray *ScanTokensFromString(NSString *values)
{
	NSMutableArray			*result = nil;
	NSScanner				*scanner = nil;
	NSString				*token = nil;
	static NSCharacterSet	*space_set = nil;
	
	if (values == nil)  return [NSMutableArray array];
	if (space_set == nil) space_set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	result = [NSMutableArray array];
	scanner = [NSScanner scannerWithString:values];
	
	while (![scanner isAtEnd])
	{
		[scanner ooliteScanCharactersFromSet:space_set intoString:NULL];
		if ([scanner ooliteScanUpToCharactersFromSet:space_set intoString:&token])
		{
			[result addObject:token];
		}
	}
	
	return result;
}


/* Disable OOLog. The only logging in the importer at the time of writing is
   "File not found" logging in NSDataOOExtensions, which is not an error. In
   general, we are unlikely to want logging from the importer.
 */
void OOLogWithFunctionFileAndLine(NSString *inMessageClass, const char *inFunction, const char *inFile, unsigned long inLine, NSString *inFormat, ...)
{
	
}


NSString * const kOOLogFileNotFound = @"";
