/*
 *  csv2plist.m
 *  csv2plist
 *
 *  Copyright (c) 2011 Michael Gile
 *
 *
 * The MIT License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */



#import <Foundation/Foundation.h>
#import "parseCSV.h"


NSString* const kUsageInstructions	= @"Usage: csv2plist <inputfile.csv>\n\t-h\t\t- Print this help message and exit.\n\t-i\t\t- (Optional) Specify the input CSV file.\n\t-o\t\t- (Optional) Specify the name with which to write the output .plist file.\nExample: csv2plist -i mycsvfile.csv -o myplistfile.plist\n";


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool	= [[NSAutoreleasePool alloc] init];
	
	CSVParser* csvParser		= nil;
	NSMutableArray *plist		= nil;
	NSString* inputFilePath		= nil;
	NSString* outputFilePath	= nil;
	BOOL helpFlagSet			= NO;
	int error					= 0;
	
	if ([[[NSProcessInfo processInfo] arguments] count] > 1) {
		
		for(int i=1; i<argc; i++) {
			NSString* arg = [[[NSProcessInfo processInfo] arguments] objectAtIndex:i];
			
			if ([arg isEqualToString:@"-h"]) {
				helpFlagSet		= YES;
				break;
			}
			else if ([arg isEqualToString:@"-i"]) {
				if (!inputFilePath) {
					inputFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"i"];
				}
				i++;
			}
			else if ([arg isEqualToString:@"-o"]) {
				if (!outputFilePath) {
					outputFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"o"];
				}
				i++;
			}
			else if (i == 1 && !inputFilePath) {
				inputFilePath = arg;
			}
			else {
				helpFlagSet = YES;
				error		= 1;
				break;
			}
		}
	}
	else {
		helpFlagSet = YES;
		error		= 1;
	}


#ifdef DEBUG
	printf("************ DEBUG ************\n");
	NSLog(@"%s (%d) - inputFilePath = %@", __PRETTY_FUNCTION__, __LINE__, inputFilePath);
	NSLog(@"%s (%d) - outputFilePath = %@", __PRETTY_FUNCTION__, __LINE__, outputFilePath);
	NSLog(@"%s (%d) - helpFlagSet = %i", __PRETTY_FUNCTION__, __LINE__, helpFlagSet);
	NSLog(@"%s (%d) - arguments = %@", __PRETTY_FUNCTION__, __LINE__, [[NSProcessInfo processInfo] arguments]);
	printf("************ DEBUG ************\n");
#endif
	
	@try {
		if (helpFlagSet) {
			printf("%s", [kUsageInstructions UTF8String]);
			return error;
		}
		
		if (!inputFilePath) {
			printf("%s", [kUsageInstructions UTF8String]);
			return error;
		}
		else {
			csvParser					= [[CSVParser alloc] init];
			[csvParser openFile:inputFilePath];
			NSMutableArray* csvArray	= [csvParser parseFile];
			[csvParser closeFile];
			
			NSArray* keys				= [csvArray objectAtIndex:0];
			plist						= [[NSMutableArray alloc] initWithCapacity:1];
			
			NSInteger csvRowCount		= [csvArray count]; 
			
			for (NSInteger csvRowIndex = 1; csvRowIndex < csvRowCount; csvRowIndex++) {
				// Start at 1 to skip keys in first row
				NSArray* rowContents		= [csvArray objectAtIndex:csvRowIndex];
				NSInteger columnCount		= [rowContents count];
				NSInteger keyIndex			= 0;
				NSInteger columnIndex		= 0;
				NSMutableDictionary* rowDict= [NSMutableDictionary dictionary];
				
				for (columnIndex = 0; columnIndex < columnCount; columnIndex++, keyIndex++) {
					[rowDict setObject:[rowContents objectAtIndex:columnIndex] forKey:[keys objectAtIndex:keyIndex]];
				}
				
				[plist addObject:rowDict];	
			}		
			
			NSURL* outputFilePathURL			= nil;
			if (!outputFilePath) {
				outputFilePathURL				= [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.plist", [inputFilePath stringByDeletingPathExtension]]];
			}
			else {
				outputFilePathURL				= [NSURL fileURLWithPath:outputFilePath];
			}

			[plist writeToURL:outputFilePathURL atomically:YES];
		}
	}
	@catch (NSException * e) {
		fprintf(stderr, "Error: %s: %s", [[e name] UTF8String], [[e reason] UTF8String] );
	}
	@finally {
		[csvParser release];
		[plist release];
		[pool drain];
	}
	
    return error;
}
