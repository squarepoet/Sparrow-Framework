//
//  SPIndexData.m
//  Sparrow
//
//  Created by Robert Carone on 3/31/15.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPIndexData.h"
#import "SPMacros.h"

@implementation SPIndexData
{
    ushort *_indices;
    NSInteger _numIndices;
}

#pragma mark Initialization

- (instancetype)initWithSize:(NSInteger)numIndices
{
    if (self = [super init])
    {
        self.numIndices = numIndices;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithSize:0];
}

- (void)dealloc
{
    free(_indices);
    [super dealloc];
}

#pragma mark Methods

- (void)copyToIndexData:(SPIndexData *)target
{
    [self copyToIndexData:target atIndex:0 numIndices:_numIndices];
}

- (void)copyToIndexData:(SPIndexData *)target atIndex:(NSInteger)targetIndex
{
    [self copyToIndexData:target atIndex:targetIndex numIndices:_numIndices];
}

- (void)copyToIndexData:(SPIndexData *)target atIndex:(NSInteger)targetIndex numIndices:(NSInteger)count
{
    if (count < 0 || count > _numIndices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index count"];
    
    if (targetIndex + count > target->_numIndices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Target too small"];
    
    memcpy(&target->_indices[targetIndex], _indices, sizeof(ushort) * count);
}

- (void)appendIndex:(ushort)index
{
    self.numIndices = _numIndices + 1;
    assert(_indices);
    _indices[_numIndices-1] = index;
}

- (void)removeIndexAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _numIndices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index"];
    
    for (NSInteger i=index; i<_numIndices-1; ++i)
        _indices[i] = _indices[i+1];
    
    self.numIndices = _numIndices - 1;
}

- (void)setIndex:(ushort)i atIndex:(NSInteger)index
{
    if (index < 0 || index >= _numIndices)
        [NSException raise:SPExceptionIndexOutOfBounds format:@"Invalid index"];
    
    if (index == _numIndices) self.numIndices = _numIndices + 1;
    assert(_indices);
    _indices[index] = i;
}

- (void)appendTriangleWithA:(ushort)a b:(ushort)b c:(ushort)c
{
    NSInteger numIndices = _numIndices;
    self.numIndices = _numIndices + 3;
    
    assert(_indices);
    _indices[numIndices  ] = a;
    _indices[numIndices+1] = b;
    _indices[numIndices+2] = c;
}

- (void)offsetIndicesAtIndex:(NSInteger)index numIndices:(NSInteger)count offset:(ushort)offset
{
    for (NSInteger i=index; i<index+count; ++i)
        _indices[i] += offset;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SPIndexData *indexData = [[[self class] alloc] init];
    indexData->_numIndices = _numIndices;
    indexData->_indices = malloc(_numIndices * sizeof(ushort));
    memcpy(indexData->_indices, _indices, _numIndices * sizeof(ushort));
    return indexData;
}

#pragma mark Properties

- (void)setNumIndices:(NSInteger)numIndices
{
    if (numIndices != _numIndices)
    {
        if (numIndices)
        {
            if (!_indices) _indices = malloc(sizeof(ushort) * numIndices);
            else           _indices = realloc(_indices, sizeof(ushort) * numIndices);

            if (numIndices > _numIndices)
                memset(_indices + _numIndices, 0, numIndices - _numIndices);
        }
        else
        {
            free(_indices);
            _indices = NULL;
        }

        _numIndices = numIndices;
    }
}

@end
