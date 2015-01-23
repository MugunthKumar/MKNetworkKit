//
//  MKObject.h
//  MKFoundation
//
//  Created by Mugunth Kumar (@mugunthkumar) on 14/02/13.
//  Copyright (C) 2011-2020 by Steinlogic Consulting and Training Pte Ltd

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MKObject.h"
#import <objc/runtime.h>

@implementation MKObject

#pragma--
#pragma Runtime stuff

+(void) initialize {
  
  if (self == [MKObject self]) {
    
  }
}

-(void) mappingDidComplete {
  
  NSDictionary *classMap = @{
                             @"__NSCFNumber" : @"NSNumber",
                             @"__NSCFString" : @"NSString",
                             @"__NSCFBoolean" : @"BOOL",
                             @"__NSArrayI" : @"NSArray",
                             @"__NSArrayM" : @"NSMutableArray",
                             @"__NSDictionaryI" : @"NSDictionary",
                             @"__NSDictionaryM" : @"NSMutableDictionary",
                             };
  
  if(self.unmappedEntries.count == 0) return;
  NSMutableString *string = [NSMutableString string];
  [string appendFormat:@"\n--------------------------\nMissing property declarations in class '%@'\n", NSStringFromClass([self class])];
  
    [self.unmappedEntries enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
      
      NSString *type = NSStringFromClass([value class]);
      type = classMap[type] ? classMap[type] : type;
      [string appendFormat:@"@property %@ *%@;\n", type, key];
  }];
  
  [string appendString:@"--------------------------\n"];
  
  NSLog(@"%@", string);
}

-(NSDictionary*) classesForMapping {
  
  return @{};
}

-(NSDictionary*) equivalentKeys {
  
  return @{};
}

+ (id)map:(id)data usingClass:(Class) class {
  
  if ([data isKindOfClass:[NSArray class]]) {
    NSMutableArray *returnArray = [NSMutableArray array];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      id mappedObject = [[class alloc] initWithDictionary:obj];
      [returnArray addObject:mappedObject];
    }];
    
    return returnArray;
  } else {
    return [[class alloc] initWithDictionary:data];
  }
}

- (NSDictionary *)objectAsDictionary {
  
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
  
  unsigned int outCount, i;
  
  objc_property_t *properties = class_copyPropertyList([self class], &outCount);
  for (i = 0; i < outCount; i++) {
    objc_property_t property = properties[i];
    const char *propName = property_getName(property);
    if (propName) {
      NSString *propertyName = @(propName);
      NSValue *value = [self valueForKey:propertyName];
      
      if (value && (id)value != [NSNull null]) {
        
        // NSString, NSNumber, NSArray, NSDictionary
        if ([value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]]) {
          
          [dict setValue:value forKey:propertyName];
        } else if ([value isKindOfClass:[NSArray class]]) {
          
          NSMutableArray *array = [NSMutableArray array];
          NSArray *toMapArray = (NSArray *)value;
          [toMapArray
           enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
             
             if ([obj isKindOfClass:[NSString class]] ||
                 [obj isKindOfClass:[NSNumber class]]) {
               [array addObject:obj];
             } else if ([obj isKindOfClass:[MKObject class]]) {
               [array addObject:[(MKObject *)obj objectAsDictionary]];
             } else {
               
               NSLog(@"Property %@ is of type %@ which is unknown",
                     propertyName, NSStringFromClass([value class]));
             }
           }];
          [dict setValue:array forKey:propertyName];
          
        } else if ([value isKindOfClass:[NSDictionary class]]) {
          
          NSMutableDictionary *mappedDict = [NSMutableDictionary dictionary];
          NSMutableDictionary *toMapDict = (NSMutableDictionary *)value;
          [toMapDict
           enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
             
             if ([value isKindOfClass:[NSString class]] ||
                 [value isKindOfClass:[NSNumber class]]) {
               [toMapDict setValue:obj forKey:key];
             } else if ([obj isKindOfClass:[MKObject class]]) {
               [toMapDict setValue:[(MKObject *)value objectAsDictionary]
                            forKey:key];
             } else {
               
               NSLog(@"Property %@ is of type %@ which is unknown",
                     propertyName, NSStringFromClass([value class]));
             }
           }];
          
          [dict setValue:mappedDict forKey:propertyName];
        } else {
          if ([value respondsToSelector:@selector(objectAsDictionary)]) {
            [dict setValue:[(MKObject *)value objectAsDictionary]
                    forKey:propertyName];
          } else {
            NSLog(@"Property %@ is of type %@ which is unknown", propertyName,
                  NSStringFromClass([value class]));
          }
        }
      }
    }
  }
  free(properties);
  
  return dict;
}

- (id)transformedJSONObjectForJSONObject:(id)jsonObject {
  
  if ([jsonObject isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [jsonObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj,
                                                    BOOL *stop) {
      
      if ([obj isKindOfClass:[NSDictionary class]]) {
        obj = [self transformedJSONObjectForJSONObject:obj];
      }
      
      if ([obj isKindOfClass:[NSArray class]]) {
        obj = [self transformedJSONObjectForJSONObject:obj];
      }
      
      NSString *camelCaseKey = [key
                                stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                withString:[[key substringToIndex:
                                             1] lowercaseString]];
      [dict setObject:obj forKey:camelCaseKey];
    }];
    
    return [dict copy];
  } else if ([jsonObject isKindOfClass:[NSArray class]]) {
    
    NSMutableArray *array = [NSMutableArray array];
    [jsonObject
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       
       if ([obj isKindOfClass:[NSDictionary class]]) {
         obj = [self transformedJSONObjectForJSONObject:obj];
       }
       
       if ([obj isKindOfClass:[NSArray class]]) {
         obj = [self transformedJSONObjectForJSONObject:obj];
       }
       
       [array addObject:obj];
     }];
    return array;
  } else
    return nil;
}

#pragma--
#pragma KVC stuff

- (id)initWithDictionary:(NSDictionary *)jsonObject {
  if (jsonObject == nil)
    return nil;
  
  if ((self = [self init])) {
    self.unmappedEntries = [NSMutableDictionary dictionary];
    jsonObject = [self transformedJSONObjectForJSONObject:jsonObject];
    [self setValuesForKeysWithDictionary:jsonObject];
    [self mappingDidComplete];
  }
  return self;
}

-(void) setValue:(id)value forKey:(NSString *)key {
  
  NSDictionary *equivalentKeys = [self equivalentKeys];
  if([equivalentKeys.allKeys containsObject:key]) {
  
    key = equivalentKeys[key];
  }
  
  NSDictionary *classesForMapping = [self classesForMapping];
  
  if([classesForMapping.allKeys containsObject:key]) {

    Class classToUse = NSClassFromString(classesForMapping[key]);
    if(classToUse) {
      value = [MKObject map:value usingClass:classToUse];
    }
  }
  
  [super setValue:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key {

  NSDictionary *equivalentKeys = [self equivalentKeys];

  if([equivalentKeys.allKeys containsObject:key]) {
    
    id replacementKey = equivalentKeys[key];
    return [self valueForKey:replacementKey];
  } else {
    
    return nil;
  }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {

  NSDictionary *equivalentKeys = [self equivalentKeys];
  
  if([equivalentKeys.allKeys containsObject:key]) {
    
    id replacementKey = equivalentKeys[key];
    [self setValue:value forKey:replacementKey]; // attempt again
  } else {
    
    __block BOOL matched = NO;
    [equivalentKeys.allKeys enumerateObjectsUsingBlock:^(NSString* equivalentKey, NSUInteger idx, BOOL *stop) {
      
      NSMutableArray *keyPaths = [[equivalentKey componentsSeparatedByString:@"."] mutableCopy];
      if([keyPaths.firstObject isEqualToString:key]) {
        
        [keyPaths removeObjectAtIndex:0];
        NSString *innerKey = [keyPaths componentsJoinedByString:@"."];
        id innerValue = [value valueForKeyPath:innerKey];
        
        NSString *replacementKey = equivalentKeys[equivalentKey];
        [self setValue:innerValue forKey:replacementKey];
        matched = YES;
      }
    }];
    
    if(!matched) {
      
      if(value) {
        self.unmappedEntries[key] = value;
      }
    }
  }
}

#pragma--
#pragma Protocol methods

- (id)mutableCopyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] init];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] init];
}

#pragma--
#pragma JSON stuff

- (NSString *)jsonString {
  NSError *error = nil;
  NSData *jsonData =
  [NSJSONSerialization dataWithJSONObject:[self objectAsDictionary]
                                  options:0
                                    error:&error];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)prettyJsonString {
  NSError *error = nil;
  NSData *jsonData =
  [NSJSONSerialization dataWithJSONObject:[self objectAsDictionary]
                                  options:NSJSONWritingPrettyPrinted
                                    error:&error];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)description {
  
  return [self prettyJsonString];
}

#pragma--
#pragma Overridable methods

- (NSMutableDictionary *)requestDictionary {
  return [NSMutableDictionary dictionary];
}

- (NSMutableDictionary *)requestDictionarySmall {
  return [NSMutableDictionary dictionary];
}

@end
