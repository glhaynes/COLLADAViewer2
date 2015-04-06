//
//  AGLKMesh.m
//  
//

#import "AGLKMesh.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@interface AGLKMesh ()

@property (strong, nonatomic, readonly) 
   NSMutableData *mutableVertexData;
@property (strong, nonatomic, readonly) 
   NSMutableData *mutableIndexData;
@property (strong, nonatomic, readwrite) 
   NSArray *commands;
@property (assign, nonatomic, readwrite) 
   GLuint indexBufferID;
@property (assign, nonatomic, readwrite) 
   GLuint vertexBufferID;
@property (assign, nonatomic, readwrite) 
   GLuint vertexArrayID;

@end


@implementation AGLKMesh

@synthesize mutableVertexData = mutableVertexData_;
@synthesize mutableIndexData = mutableIndexData_;
@synthesize extraVertexData = extraVertexData_;
@synthesize commands = commands_;
@synthesize indexBufferID = indexBufferID_;
@synthesize vertexBufferID = vertexBufferID_;
@synthesize vertexArrayID = vertexArrayID_;
@synthesize shouldUseVAOExtension = shouldUseVAOExtension_;


/////////////////////////////////////////////////////////////////
// Designated initializer
- (id)init
{
   if(nil != (self=[super init]))
   {
      mutableVertexData_ = [[NSMutableData alloc] init];
      mutableIndexData_ = [[NSMutableData alloc] init];
      commands_ = [NSArray array];
      shouldUseVAOExtension_ = NO;
   }
   
   return self;
}


/////////////////////////////////////////////////////////////////
// Initialize the receiver with values for the keys, 
// "vertexAttributeData", "indexData", and "commands" 
// in aDictionary.
- (id)initWithPlistRepresentation:(NSDictionary *)aDictionary;
{
   if(nil != (self=[self init]))
   {
      [mutableVertexData_ appendData:[aDictionary
         objectForKey:@"vertexAttributeData"]];
      [mutableIndexData_ appendData:[aDictionary
         objectForKey:@"indexData"]];
      commands_ = [commands_ arrayByAddingObjectsFromArray:
         [aDictionary objectForKey:@"commands"]];
   }
   
   return self;
}


/////////////////////////////////////////////////////////////////
// Returns a dictionary storing "vertexAttributeData", 
// "indexData", and "commands" keys with associated values.
- (NSDictionary *)plistRepresentation
{
    for (int i = 0; i < self.numberOfVertices; i++)
    {
        ///const AGLKMeshVertex *bytes = (const AGLKMeshVertex *)[self.vertexData bytes];
        ///NSLog(@"%d: %f %f %f, %f %f %f", i, bytes[i].position.x, bytes[i].position.y, bytes[i].position.z, bytes[i].tangent.x, bytes[i].tangent.y, bytes[i].tangent.z);
    }
    
   return [NSDictionary dictionaryWithObjectsAndKeys:
      self.mutableVertexData, @"vertexAttributeData", 
      self.mutableIndexData, @"indexData", 
      self.commands, @"commands", 
      nil];
}


/////////////////////////////////////////////////////////////////
//
- (void)encodeWithCoder:(NSCoder *)aCoder
{
   [aCoder encodeObject:self.plistRepresentation
      forKey:@"plistRepresentation"];
}


/////////////////////////////////////////////////////////////////
//
- (id)initWithCoder:(NSCoder *)aDecoder
{
   return [self initWithPlistRepresentation:
      [aDecoder decodeObjectForKey:@"plistRepresentation"]];
}


/////////////////////////////////////////////////////////////////
// Returns a mutable data object suitable for storing extra 
// attributes per vertex.  The specific extra attributes depend
// on the needs of applications.
- (NSMutableData *)extraVertexData
{
   if(nil == extraVertexData_)
   {
      extraVertexData_ = [NSMutableData data];
   }
   
   return extraVertexData_;
}


/////////////////////////////////////////////////////////////////
// Returns the calculated number of vertices stored by the 
// receiver.
- (NSUInteger)numberOfVertices;
{
   return [self.vertexData length] / sizeof(AGLKMeshVertex);
}


/////////////////////////////////////////////////////////////////
// Returns a string containing information about the vertices
// stored by the receiver.
- (NSString *)description
{
   NSMutableString *result = [NSMutableString string];
   const NSUInteger count = [self numberOfVertices];
   
   for(int i = 0; i < count; i++)
   {
      AGLKMeshVertex currentVertex = [self vertexAtIndex:i];
      
      [result appendFormat:
         @"p{%0.2f, %0.2f, %0.2f} n{%0.2f, %0.2f, %0.2f}}\n", 
         currentVertex.position.v[0],
         currentVertex.position.v[1],
         currentVertex.position.v[2],
         currentVertex.normal.v[0],
         currentVertex.normal.v[1],
         currentVertex.normal.v[2]];
      [result appendFormat:
         @" t0{%0.2f %0.2f}\n", 
         currentVertex.texCoords0.v[0],
         currentVertex.texCoords0.v[1]];
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
// Returns the calculated number of vertex indices stored by the
// receiver.
- (NSUInteger)numberOfIndices;
{
   return (NSUInteger)([self.indexData length] / 
      sizeof(GLushort));
}


/////////////////////////////////////////////////////////////////
// Returns the receiver's index data. Indices are type GLushort.
- (NSData *)indexData
{
   return self.mutableIndexData;
}


/////////////////////////////////////////////////////////////////
// Returns the receiver's vertex data. Vertices are type 
// AGLKMeshVertex.
- (NSData *)vertexData
{
   return self.mutableVertexData;
}


/////////////////////////////////////////////////////////////////
// Return's the receiver's vertex at the specified index.
- (AGLKMeshVertex)vertexAtIndex:(NSUInteger)anIndex;
{
   NSParameterAssert(anIndex < [self numberOfVertices]);
      
   const AGLKMeshVertex *bytes = 
      (const AGLKMeshVertex *)[self.vertexData bytes];
   
   return bytes[anIndex];
}


/////////////////////////////////////////////////////////////////
// Return's the receiver's index at the specified index.
- (GLushort)indexAtIndex:(NSUInteger)anIndex;
{
   NSParameterAssert(anIndex < [self numberOfIndices]);
      
   const GLushort *bytes = 
      (const GLushort *)[self.indexData bytes];
   
   return bytes[anIndex];
}


- (AGLKAxisAllignedBoundingBox)
   axisAlignedBoundingBoxForCommandsInRange:(NSRange)aRange;
{
   AGLKAxisAllignedBoundingBox result;
         
   if(0 < aRange.length)
   {
      const NSUInteger lastCommandIndex = 
         (aRange.location + aRange.length) - 1;

      NSParameterAssert(aRange.location <
         [self.commands count]);
      NSParameterAssert(lastCommandIndex <
         [self.commands count]);

      AGLKMeshVertex *vertexAttributes = (AGLKMeshVertex *)
         [self.vertexData bytes];
      BOOL hasFoundFirstVertex = NO;
               
      for(NSUInteger i = aRange.location; 
         i <= lastCommandIndex; i++)
      {
         NSDictionary *currentCommand = 
            [self.commands objectAtIndex:i];
         size_t  numberOfIndices = (size_t)[[currentCommand
            objectForKey:@"numberOfIndices"] 
            unsignedIntegerValue];
         size_t  firstIndex = (size_t)[[currentCommand 
            objectForKey:@"firstIndex"] unsignedIntegerValue];
         GLushort *indices = (GLushort *)
            [self.indexData bytes];
         
         NSAssert(AGLKMeshMaximumNumberOfVertices >=
            (firstIndex + numberOfIndices),
            @"Vertex index out of bounds");
         
         if(0 < numberOfIndices && !hasFoundFirstVertex)
         {
            hasFoundFirstVertex = YES;
            GLushort  index = indices[0 + firstIndex];
            AGLKMeshVertex currentVertex =
               vertexAttributes[index];
            
            result.min.x = currentVertex.position.x;
            result.min.y = currentVertex.position.y;
            result.min.z = currentVertex.position.z;
            result.max.x = currentVertex.position.x;
            result.max.y = currentVertex.position.y;
            result.max.z = currentVertex.position.z;
         }
         for(int j = 1; j < numberOfIndices; j++)
         {
            GLushort  index = indices[j + firstIndex];
            AGLKMeshVertex currentVertex =
               vertexAttributes[index];
            
            result.min.x = 
               MIN(currentVertex.position.x, 
               result.min.x);
            result.min.y = 
               MIN(currentVertex.position.y, 
               result.min.y);
            result.min.z = 
               MIN(currentVertex.position.z, 
               result.min.z);
            result.max.x = 
               MAX(currentVertex.position.x, 
               result.max.x);
            result.max.y = 
               MAX(currentVertex.position.y, 
               result.max.y);
            result.max.z = 
               MAX(currentVertex.position.z, 
               result.max.z);
         }
      }
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
// This method returns a string encoding the minimum and maximum
// extents of an axis aligned bounding box enclosing all of the
// receiver's vertices described by the receiver's commands in 
// the specified range.
- (NSString *)axisAlignedBoundingBoxStringForCommandsInRange:
   (NSRange)aRange;
{
   AGLKAxisAllignedBoundingBox aabb =
      [self axisAlignedBoundingBoxForCommandsInRange:aRange];
         
   return [NSString stringWithFormat:
      @"{%0.2f, %0.2f, %0.2f},{%0.2f, %0.2f, %0.2f}",
      aabb.min.x,
      aabb.min.y,
      aabb.min.z,
      aabb.max.x,
      aabb.max.y,
      aabb.max.z];
}


/////////////////////////////////////////////////////////////////
// This method returns a string encoding the minimum and maximum
// extents of an axis aligned bounding box enclosing all of the
// receiver's vertices.
- (NSString *)axisAlignedBoundingBoxString;
{
   NSRange allCommandsRange = {0, [self.commands count]};
   
   return [self axisAlignedBoundingBoxStringForCommandsInRange:
      allCommandsRange];
}


/////////////////////////////////////////////////////////////////
//
- (id)copyWithTransform:(GLKMatrix4)transforms
   textureTransform:(GLKMatrix3)textureTransform;
{
   AGLKMesh *result = [[AGLKMesh alloc] init];
   
   bool isInvertible;
   GLKMatrix3 normalMatrix = GLKMatrix4GetMatrix3(
      GLKMatrix4Transpose(GLKMatrix4Invert(
         transforms, &isInvertible)));
   
   if(!isInvertible)
   {
      normalMatrix = GLKMatrix4GetMatrix3(
         GLKMatrix4Transpose(transforms));
   }

   const NSUInteger count =
      MIN(self.numberOfIndices, AGLKMeshMaximumNumberOfVertices);
   
   // Transform all the positions and normals while copying
   // vertex attributes into result.
   // Renormalizes normals.
   for(NSUInteger i = 0; i < count; i++)
   {
      AGLKMeshVertex vertex = [self vertexAtIndex:i];
      
      vertex.position = 
         GLKMatrix4MultiplyVector3WithTranslation(
            transforms, vertex.position);
      vertex.normal = GLKVector3Normalize(
         GLKMatrix3MultiplyVector3(normalMatrix,
         vertex.normal));
      
      GLKVector3 textureCoords =
      {
         vertex.texCoords0.x,
         vertex.texCoords0.y,
         0.0f
      };
      textureCoords =
         GLKMatrix3MultiplyVector3(textureTransform,
         textureCoords);
      
      vertex.texCoords0 =
         GLKVector2Make(textureCoords.x, textureCoords.y);
         
      [result appendVertex:vertex];
   }
   
   // Copy indices and commands which remain identical but 
   // can't be shared.
   [result.mutableIndexData appendData:self.indexData];
   result.commands = [self.commands copy];
   
   return result;
}


/////////////////////////////////////////////////////////////////
//
- (void)appendCommandDictionary:(NSDictionary *)aDictionary
{
   self.commands = 
      [self.commands arrayByAddingObject:aDictionary];
   //NSLog(@"%p %@", self, self.commands);
}


/////////////////////////////////////////////////////////////////
//
- (void)appendVertex:(AGLKMeshVertex)aVertex;
{
   NSAssert(AGLKMeshMaximumNumberOfVertices >
      [self numberOfVertices],
      @"Attempt to append to omany vertices");
   
    /***NSLog(@"Appending vertex: p{%f, %f, %f} n{%f, %f, %f}, t0{%f, %f}, t1{%f, %f}",
          aVertex.position.x, aVertex.position.y, aVertex.position.z,
          aVertex.normal.x, aVertex.normal.y, aVertex.normal.z,
          aVertex.texCoords0.s, aVertex.texCoords0.t,
          aVertex.texCoords1.s, aVertex.texCoords1.t);***/
    
   [self.mutableVertexData appendBytes:&aVertex
      length:sizeof(aVertex)];
}


/////////////////////////////////////////////////////////////////
//
- (BOOL)canAppendMesh:(AGLKMesh *)aMesh;
{
   NSParameterAssert(nil != aMesh);
   const NSUInteger  startNumberOfIndices = self.numberOfIndices;
   
   // Offset all of aMesh's indices while appending them
   const NSUInteger numberOfIndicesToAdd = aMesh.numberOfIndices;
   for(NSUInteger i = 0; i < numberOfIndicesToAdd; i++)
   {
      NSUInteger offsetIndex = 
         startNumberOfIndices + [aMesh indexAtIndex:i];
      if(AGLKMeshMaximumNumberOfVertices < offsetIndex)
      {
         // Exit loop and method prematurely!!!
         return NO;
      }
   }

   return YES;
}


/////////////////////////////////////////////////////////////////
//
- (void)appendMesh:(AGLKMesh *)aMesh;
{
   NSParameterAssert(nil != aMesh);
   const NSUInteger  startNumberOfIndices = self.numberOfIndices;
   
   // Append vertex attribute data for the aMesh
   [self.mutableVertexData appendData:aMesh.vertexData];
   
   // Offset all of aMesh's indices while appending them
   const NSUInteger numberOfIndicesToAdd = aMesh.numberOfIndices;
   for(NSUInteger i = 0; i < numberOfIndicesToAdd; i++)
   {
      NSUInteger offsetIndex = 
         startNumberOfIndices + [aMesh indexAtIndex:i];
      if(AGLKMeshMaximumNumberOfVertices >= offsetIndex)
      {      
         [self appendIndex:offsetIndex];
      }
   }

   // Append aMesh's commands
   for(NSDictionary *commandDictionary in aMesh.commands)
   {
      NSMutableDictionary *newCommandDictionary = 
         [NSMutableDictionary dictionaryWithDictionary:
            commandDictionary];
      
      NSUInteger newCommandFirstIndex = 
         [[commandDictionary objectForKey:@"firstIndex"]
            unsignedIntegerValue] + startNumberOfIndices;
      
      NSUInteger newCommandNumberOfIndices =
         (size_t)[[commandDictionary objectForKey:
            @"numberOfIndices"] unsignedIntegerValue];
      
      [newCommandDictionary setObject:[NSNumber
         numberWithUnsignedInteger:newCommandFirstIndex]
         forKey:@"firstIndex"];
      
      if(AGLKMeshMaximumNumberOfVertices >=
         (newCommandFirstIndex + newCommandNumberOfIndices))
      {
         [self appendCommandDictionary:newCommandDictionary];
      }
   }
}


/////////////////////////////////////////////////////////////////
//
- (void)appendCommand:(GLenum)command 
   firstIndex:(size_t)firstIndex
   numberOfIndices:(size_t)numberOfIndices
   materialName:(NSString *)materialName;
{
   NSDictionary *renderingDictionary = 
      [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithUnsignedInteger:firstIndex], 
            @"firstIndex",
         [NSNumber numberWithUnsignedInteger:numberOfIndices], 
            @"numberOfIndices",
         [NSNumber numberWithUnsignedInteger:command], 
            @"command",
         materialName,
            @"materialName",
         nil];
        
   [self appendCommandDictionary:renderingDictionary];
}


/////////////////////////////////////////////////////////////////
//
- (void)appendIndex:(GLushort)index;
{
    ///NSLog(@"appending index: %d", index);
    
   [self.mutableIndexData appendBytes:&index 
      length:sizeof(index)];
}


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)numberOfVerticesForCommandsInRange:(NSRange)aRange;
{
   NSInteger result = 0;
   
   if(0 < aRange.length)
   {
      const NSUInteger lastCommandIndex = 
         (aRange.location + aRange.length) - 1;
      const NSUInteger numberOfCommands = 
         [self.commands count];

      NSParameterAssert(aRange.location < numberOfCommands);
      NSParameterAssert(lastCommandIndex < numberOfCommands);
                
      for(NSUInteger i = aRange.location; 
         i <= lastCommandIndex; i++)
      {
         NSDictionary *currentCommand = 
            [self.commands objectAtIndex:i];
         result += [[currentCommand 
            objectForKey:@"numberOfIndices"]
            unsignedIntegerValue];
      }
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
//
static void ANormalizeTextureCoords(
   GLKVector2 *vertex0,
   GLKVector2 *vertex1,
   GLKVector2 *vertex2)
{
   NSCAssert(NULL != vertex0, @"vertex0 == NULL");
   NSCAssert(NULL != vertex1, @"vertex1 == NULL");
   NSCAssert(NULL != vertex2, @"vertex2 == NULL");
   
   const float minS =
      MIN(vertex0->s, MIN(vertex1->s, vertex2->s));
   const float minT =
      MIN(vertex0->t, MIN(vertex1->t, vertex2->t));
   const float maxS =
      MAX(vertex0->s, MAX(vertex1->s, vertex2->s));
   const float maxT =
      MAX(vertex0->t, MAX(vertex1->t, vertex2->t));
   const float rangeS =
      MAX(1.0, maxS - minS);  // prevent laterdivide by zero and
                              // preserve coords less than 1.0
   const float rangeT =
      MAX(1.0, maxT - minT);  // prevent laterdivide by zero and
                              // preserve coords less than 1.0
   
//   {
//      NSLog(@"before:{%f, %f}{%f, %f}{%f, %f}",
//         vertex0->s,
//         vertex0->t,
//         vertex1->s,
//         vertex1->t,
//         vertex2->s,
//         vertex2->t);
//   }
   
   vertex0->s = (vertex0->s - minS) / rangeS;
   vertex1->s = (vertex1->s - minS) / rangeS;
   vertex2->s = (vertex2->s - minS) / rangeS;
   vertex0->t = (vertex0->t - minT) / rangeT;
   vertex1->t = (vertex1->t - minT) / rangeT;
   vertex2->t = (vertex2->t - minT) / rangeT;

//   if(((vertex0->s == vertex1->s) && (vertex1->s == vertex2->s)) ||
//      ((vertex0->t == vertex1->t) && (vertex1->t == vertex2->t)))
//   {
//      NSLog(@"after:{%f, %f}{%f, %f}{%f, %f}",
//         vertex0->s,
//         vertex0->t,
//         vertex1->s,
//         vertex1->t,
//         vertex2->s,
//         vertex2->t);
//   }
}


/////////////////////////////////////////////////////////////////
//
typedef struct
{
   AGLKMeshVertex a;
   AGLKMeshVertex b;
   AGLKMeshVertex c;
   GLushort origIndexA;
   GLushort origIndexB;
   GLushort origIndexC;
}
ANoShareTriangle;


/////////////////////////////////////////////////////////////////
//
- (void)normalizeAllTextureCoords;
{
   const NSUInteger numberOfCommands =
      [self.commands count];

   const GLushort *indices =
      (const GLushort *)[self.indexData bytes];
    AGLKMeshVertex *vertices =
       (AGLKMeshVertex *)[self.mutableVertexData mutableBytes];
   
   for(NSUInteger i = 0; i < numberOfCommands; i++)
   {
      NSDictionary *currentCommand = 
         [self.commands objectAtIndex:i];
      GLenum mode = (GLenum)[[currentCommand 
         objectForKey:@"command"] unsignedIntegerValue];

      // Accumulate triangles that do not share any vertices and have
      // normalized texture coordinates
      NSMutableData *noShareTrianglesData =
         [NSMutableData data];
      
      if(GL_TRIANGLES == mode)
      {
         const size_t  numberOfIndices = (size_t)[[currentCommand
            objectForKey:AGLKMeshCommandNumberOfIndices] 
            unsignedIntegerValue];
         const size_t  firstIndex = (size_t)[[currentCommand
            objectForKey:AGLKMeshCommandFirstIndex] 
               unsignedIntegerValue];
         
         for(GLsizei j = 0; j <= (numberOfIndices - 3); j += 3)
         {
            ANoShareTriangle triangle;
            const GLushort index0 = indices[firstIndex + j];
            triangle.a = vertices[index0];
            triangle.origIndexA = index0;
            const GLushort index1 = indices[firstIndex + j + 1];
            triangle.b = vertices[index1];
            triangle.origIndexB = index1;
            const GLushort index2 = indices[firstIndex + j + 2];
            triangle.c = vertices[index2];
            triangle.origIndexC = index2;

            ANormalizeTextureCoords(
               &triangle.a.texCoords0,
               &triangle.b.texCoords0,
               &triangle.c.texCoords0
            );
            
            /////////////////////////////////////////
            AGLKMeshVertex a = triangle.a;
            AGLKMeshVertex b = triangle.b;
            AGLKMeshVertex c = triangle.c;
             
            GLKVector3 edge1 = GLKVector3Subtract(b.position, a.position);
            GLKVector3 edge2 = GLKVector3Subtract(c.position, a.position);
             
            float deltaU1 = b.texCoords0.x - a.texCoords0.x;
            float deltaV1 = b.texCoords0.y - a.texCoords0.y;
            float deltaU2 = c.texCoords0.x - a.texCoords0.x;
            float deltaV2 = c.texCoords0.y - a.texCoords0.y;

             /*NSLog(@"deltaU1: %f", deltaU1);
             NSLog(@"deltaV1: %f", deltaV1);
             NSLog(@"deltaU2: %f", deltaU2);
             NSLog(@"deltaV2: %f", deltaV2);*/

            float f = 1.0f / (deltaU1 * deltaV2 - deltaU2 * deltaV1);
             
            ///NSLog(@"f: %f", f);

            GLKVector3 tangent; //, Bitangent;

            tangent.x = f * (deltaV2 * edge1.x - deltaV1 * edge2.x);
            tangent.y = f * (deltaV2 * edge1.y - deltaV1 * edge2.y);
            tangent.z = f * (deltaV2 * edge1.z - deltaV1 * edge2.z);
             
            /*
            Bitangent.x = f * (-DeltaU2 * Edge1.x - DeltaU1 * Edge2.x);
            Bitangent.y = f * (-DeltaU2 * Edge1.y - DeltaU1 * Edge2.y);
            Bitangent.z = f * (-DeltaU2 * Edge1.z - DeltaU1 * Edge2.z);
            */

            triangle.a.tangent = triangle.b.tangent = triangle.c.tangent = GLKVector3Normalize(tangent);
             
             /*
             GLKVector3 v1 = triangle.a.position;
             GLKVector3 v2 = triangle.b.position;
             GLKVector3 v3 = triangle.c.position;
             
             GLKVector2 w1 = triangle.a.texCoords0;
             GLKVector2 w2 = triangle.b.texCoords0;
             GLKVector2 w3 = triangle.c.texCoords0;
             
             float x1 = v2.x - v1.x;
             float x2 = v3.x - v1.x;
             float y1 = v2.y - v1.y;
             float y2 = v3.y - v1.y;
             float z1 = v2.z - v1.z;
             float z2 = v3.z - v1.z;
             
             float s1 = w2.x - w1.x;
             float s2 = w3.x - w1.x;
             float t1 = w2.y - w1.y;
             float t2 = w3.y - w1.y;
             
             float r = 1.0f / (s1 * t2 - s2 * t1);
             
             if (isinf(r))
             {
                 //r = 1.0f;
             }
             
             GLKVector3 sdir = GLKVector3Make((t2 * x1 - t1 * x2) * r,
                                              (t2 * y1 - t1 * y2) * r,
                                              (t2 * z1 - t1 * z2) * r);
             //GLKVector3 tdir = GLKVector3Make((s1 * x2 - s2 * x1) * r,
             //                                 (s1 * y2 - s2 * y1) * r,
             //                                 (s1 * z2 - s2 * z1) * r);
             
             //triangle.a.tangent = GLKVector3DotProduct(triangle.a.normal, sdir);
             //triangle.a.tangent = GLKVector3Normalize(sdir); //triangle.a.tangent);

             //triangle.b.tangent = GLKVector3Subtract(sdir, triangle.b.normal);
             //triangle.b.tangent = GLKVector3MultiplyScalar(triangle.b.tangent,
             //                                              GLKVector3DotProduct(triangle.b.normal, sdir));
             //triangle.b.tangent = GLKVector3Normalize(sdir);

             //triangle.c.tangent = GLKVector3Subtract(sdir, triangle.c.normal);
             //triangle.c.tangent = GLKVector3MultiplyScalar(triangle.c.tangent,
             //                                              GLKVector3DotProduct(triangle.c.normal, sdir));
             //triangle.c.tangent = GLKVector3Normalize(sdir);
             
             if (sdir.x == sdir.y == sdir.z == 0.0f)
             {
                 triangle.a.tangent = triangle.b.tangent = triangle.c.tangent = GLKVector3Make(0.0f, 0.0f, 0.0f);
             }
             else
             {
                 triangle.a.tangent = triangle.b.tangent = triangle.c.tangent = GLKVector3Normalize(sdir);
             }
*/
            /////////////////////////////////////////
            
            [noShareTrianglesData appendBytes:&triangle
               length:sizeof(ANoShareTriangle)];
         }
         
         // Copy vertices back in original order within vertices array
         const GLsizei numberOfTriangles =
            (GLsizei)([noShareTrianglesData length] /
               sizeof(ANoShareTriangle));
         const ANoShareTriangle *triangles =
            (ANoShareTriangle *)[noShareTrianglesData bytes];
         
//         NSLog(@"numShared:%ld unshared:%d",
//            numberOfIndices, numberOfTriangles * 3);
         
         for(GLsizei j = 0;
            j < numberOfTriangles; j++)
         {
            vertices[triangles[j].origIndexA] = triangles[j].a;
            vertices[triangles[j].origIndexB] = triangles[j].b;
            vertices[triangles[j].origIndexC] = triangles[j].c;
         }
         
         // discard uneeded copies of vertex data
         noShareTrianglesData = nil;
      }
   }
}

@end


/////////////////////////////////////////////////////////////////
// Constants used to access properties from a drawing
// command dictionary.
NSString *const AGLKMeshCommandNumberOfIndices = 
   @"numberOfIndices";
NSString *const AGLKMeshCommandFirstIndex = 
   @"firstIndex";
