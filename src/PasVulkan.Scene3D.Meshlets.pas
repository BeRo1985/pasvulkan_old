(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2024, Benjamin Rosseaux (benjamin@rosseaux.de)          *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. This PasVulkan wrapper may be used only with the PasVulkan-own Vulkan   *
 *    Pascal header.                                                          *
 * 4. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 5. Write code which's compatible with Delphi >= 2009 and FreePascal >=     *
 *    3.1.1                                                                   *
 * 6. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 7. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 8. Try to use const when possible.                                         *
 * 9. Make sure to comment out writeln, used while debugging.                 *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,    *
 *     x86-64, ARM, ARM64, etc.).                                             *
 * 11. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan.Scene3D.Meshlets;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasMP,
     PasVulkan.Types,
     PasVulkan.Collections;

const MaxVerticesPerMeshlet=256;
      MaxPrimitivesPerMeshlet=256;

type TpvScene3DMeshlet=packed record
      Indices:array[0..MaxPrimitivesPerMeshlet-1,0..2] of TpvUInt32;
      CountPrimitives:TpvUInt32;
     end; 
     PpvScene3DMeshlet=^TpvScene3DMeshlet;

     TpvScene3DMeshlets=TpvDynamicArray<TpvScene3DMeshlet>;

// The input indices should be preprocessed for example with the tipsify algorithm before calling this function to maximize the locality 
// of the indices for the meshlets.
procedure BuildMeshlets(const aIndices:Pointer;const aCountIndices:TpvSizeInt;const aMaxVertexSize,aMaxPrimitiveSize:TpvSizeInt;var aMeshlets:TpvScene3DMeshlets);

implementation

{$if not declared(BSRDWord)}
{$if defined(cpu386)}
function BSRDWord(Value:TpvUInt32):TpvUInt32; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 bsr eax,eax
 jnz @Done
 mov eax,255
@Done:
end;
{$elseif defined(cpux64) or defined(cpuamd64) or defined(cpux86_64)}
function BSRDWord(Value:TpvUInt32):TpvUInt32; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
{$ifndef fpc}
 .NOFRAME
{$endif}
{$ifdef Windows}
 bsr eax,ecx
{$else}
 bsr eax,edi
{$endif}
 jnz @Done
 mov eax,255
@Done:
end;
{$endif}
{$ifend}

function FindMSB(const aValue:TpvUInt32):TpvUInt32;
{$if declared(BSRDWord)}
begin
 result:=BSRDWord(aValue);
end;
{$elseif declared(TPasMPMath)}
begin
 result:=TPasMPMath.BitScanReverse32(aValue);
end;
{$else}
var v:TpvUInt32;
begin
 v:=aValue;
 result:=0;
 while v<>0 do begin
  v:=v shr 1;
  inc(result);
 end;
end;
{$ifend}

type { TpvScene3DMeshletPrimitiveCache }
     TpvScene3DMeshletPrimitiveCache=class
      public
      private
       fPrimitives:array[0..MaxPrimitivesPerMeshlet-1,0..2] of TpvUInt32;
       fVertices:array[0..MaxVerticesPerMeshlet-1] of TpvUInt32;
       fCountPrimitives:TpvSizeInt;
       fCountVertices:TpvSizeInt;
       fCountVertexDeltaBits:TpvSizeInt;
       fCountVertexAllBits:TpvSizeInt;
       fMaxVertexSize:TpvSizeInt;
       fMaxPrimitiveSize:TpvSizeInt;
       fPrimitiveBits:TpvUInt32;
       fMaxBlockBits:TpvUInt32;
      public
       constructor Create(const aMaxVertexSize,aMaxPrimitiveSize:TpvSizeInt); reintroduce;
       destructor Destroy; override;
       function Empty:boolean;
       procedure Reset;
       function FitsBlock:boolean;
       function CannotInsert(const aIndexA,aIndexB,aIndexC:TpvUInt32):boolean;
       function CannotInsertBlock(const aIndexA,aIndexB,aIndexC:TpvUInt32):boolean;
       procedure Insert(const aIndexA,aIndexB,aIndexC:TpvUInt32);
     end;

{ TpvScene3DMeshletPrimitiveCache }

constructor TpvScene3DMeshletPrimitiveCache.Create(const aMaxVertexSize,aMaxPrimitiveSize:TpvSizeInt);
begin
 inherited Create;
 FillChar(fPrimitives,SizeOf(fPrimitives),#0);
 FillChar(fVertices,SizeOf(fVertices),#$ff);
 fCountPrimitives:=0;
 fCountVertices:=0;
 fCountVertexDeltaBits:=0;
 fCountVertexAllBits:=0;
 fMaxVertexSize:=aMaxVertexSize;
 fMaxPrimitiveSize:=aMaxPrimitiveSize;
 fPrimitiveBits:=1;
 fMaxBlockBits:=$ffffffff;
 Reset;
end;

destructor TpvScene3DMeshletPrimitiveCache.Destroy;
begin
 inherited Destroy;
end;

function TpvScene3DMeshletPrimitiveCache.Empty:boolean;
begin
 result:=fCountVertices=0;
end;

procedure TpvScene3DMeshletPrimitiveCache.Reset;
begin
 fCountPrimitives:=0;
 fCountVertices:=0;
 fCountVertexDeltaBits:=0;
 fCountVertexAllBits:=0;
 FillChar(fVertices,SizeOf(fVertices),#$ff);
end;

function TpvScene3DMeshletPrimitiveCache.FitsBlock:boolean;
var PrimitiveBits,VertexBits:TpvUInt32;
begin
 PrimitiveBits:=(fCountPrimitives-1)*3*fPrimitiveBits;
 VertexBits:=(fCountVertices-1)*fCountVertexDeltaBits;
 result:=(PrimitiveBits+VertexBits)<=fMaxBlockBits;
end;

function TpvScene3DMeshletPrimitiveCache.CannotInsert(const aIndexA,aIndexB,aIndexC:TpvUInt32):boolean;
var Found,VertexIndex:TpvSizeInt;
    Vertex:TpvUInt32;
    Indices:array[0..2] of TpvUInt32;
begin
 Indices[0]:=aIndexA;
 Indices[1]:=aIndexB;
 Indices[2]:=aIndexC;
 if (Indices[0]=Indices[1]) or (Indices[0]=Indices[2]) or (Indices[1]=Indices[2]) then begin
  result:=false;
 end else begin
  Found:=0;
  for VertexIndex:=0 to fCountVertices-1 do begin
   Vertex:=fVertices[VertexIndex];
   if Vertex=Indices[0] then begin
    inc(Found);
   end;
   if Vertex=Indices[1] then begin
    inc(Found);
   end;
   if Vertex=Indices[2] then begin
    inc(Found);
   end;
  end;
  result:=(((fCountVertices+3)-Found)>fMaxVertexSize) or ((fCountPrimitives+1)>fMaxPrimitiveSize);
 end;
end;

function TpvScene3DMeshletPrimitiveCache.CannotInsertBlock(const aIndexA,aIndexB,aIndexC:TpvUInt32):boolean;
var Found,VertexIndex,Vertex,FirstVertex,NewVertices,NewPrimitives:TpvSizeInt;
    CmpBits,DeltaBits,NewVertexBits,NewPrimitiveBits,NewBits:TpvUInt32;
    Indices:array[0..2] of TpvUInt32;
begin
 Indices[0]:=aIndexA;
 Indices[1]:=aIndexB;
 Indices[2]:=aIndexC;
 if (Indices[0]=Indices[1]) or (Indices[0]=Indices[2]) or (Indices[1]=Indices[2]) then begin
  result:=false;
 end else begin
  Found:=0;
  for VertexIndex:=0 to fCountVertices-1 do begin
   Vertex:=fVertices[VertexIndex];
   if Vertex=Indices[0] then begin
    inc(Found);
   end;
   if Vertex=Indices[1] then begin
    inc(Found);
   end;
   if Vertex=Indices[2] then begin
    inc(Found);
   end;
  end;
  if fCountVertices>0 then begin
   FirstVertex:=fVertices[0];
  end else begin
   FirstVertex:=Indices[0];
  end;
  CmpBits:=Max(FindMSB((FirstVertex xor Indices[0]) or 1),
               Max(FindMSB((FirstVertex xor Indices[1]) or 1),
                   FindMSB((FirstVertex xor Indices[2]) or 1)))+1;
  DeltaBits:=Max(CmpBits,fCountVertexDeltaBits);
  NewVertices:=(fCountVertices+3)-Found;
  NewPrimitives:=fCountPrimitives+1;
  NewVertexBits:=(NewVertices-1)*DeltaBits;
  NewPrimitiveBits:=(NewPrimitives-1)*3*fPrimitiveBits;
  NewBits:=NewVertexBits+NewPrimitiveBits;
  result:=(NewPrimitives>fMaxPrimitiveSize) or (NewVertices>fMaxVertexSize) or (NewBits>fMaxBlockBits);
 end;
end;

procedure TpvScene3DMeshletPrimitiveCache.Insert(const aIndexA,aIndexB,aIndexC:TpvUInt32);
var Index,CurrentIndex,VertexIndex:TpvSizeInt;
    Found:boolean;
    Indices:array[0..2] of TpvUInt32;
    Triangle:array[0..2] of TpvUInt32;
begin
 Indices[0]:=aIndexA;
 Indices[1]:=aIndexB;
 Indices[2]:=aIndexC;
 if (Indices[0]<>Indices[1]) and (Indices[0]<>Indices[2]) and (Indices[1]<>Indices[2]) then begin
  for Index:=0 to 2 do begin
   CurrentIndex:=Indices[Index];
   Found:=false;
   for VertexIndex:=0 to fCountVertices-1 do begin
    if CurrentIndex=fVertices[VertexIndex] then begin
     Triangle[Index]:=VertexIndex;
     Found:=true;
     break;
    end;
   end;
   if not Found then begin
    fVertices[fCountVertices]:=CurrentIndex;
    Triangle[Index]:=fCountVertices;
    if fCountVertices>0 then begin
     fCountVertexDeltaBits:=Max(fCountVertexDeltaBits,FindMSB((CurrentIndex xor fVertices[0]) or 1)+1);
    end;
    fCountVertexAllBits:=Max(fCountVertexAllBits,FindMSB(CurrentIndex)+1);
    inc(fCountVertices);
   end;
  end;
  fPrimitives[fCountPrimitives,0]:=Triangle[0];
  fPrimitives[fCountPrimitives,1]:=Triangle[1];
  fPrimitives[fCountPrimitives,2]:=Triangle[2];
  inc(fCountPrimitives);
  Assert(FitsBlock);
 end;
end;

procedure BuildMeshlets(const aIndices:Pointer;const aCountIndices:TpvSizeInt;const aMaxVertexSize,aMaxPrimitiveSize:TpvSizeInt;var aMeshlets:TpvScene3DMeshlets);
var MeshletPrimitiveCache:TpvScene3DMeshletPrimitiveCache;
    Index,PrimitiveIndex:TpvSizeInt;
    Indices:PpvUInt32;
    a,b,c:TpvUInt32;
    Meshlet:PpvScene3DMeshlet;
begin

 MeshletPrimitiveCache:=TpvScene3DMeshletPrimitiveCache.Create(aMaxVertexSize,aMaxPrimitiveSize);
 try

  Indices:=aIndices;

  for Index:=0 to (aCountIndices div 3)-1 do begin

   a:=Indices^;
   inc(Indices);

   b:=Indices^;
   inc(Indices);

   c:=Indices^;
   inc(Indices);

   if MeshletPrimitiveCache.CannotInsertBlock(a,b,c) then begin

    if not MeshletPrimitiveCache.Empty then begin

     Meshlet:=pointer(aMeshlets.AddNew);
     Meshlet^.CountPrimitives:=MeshletPrimitiveCache.fCountPrimitives;
     for PrimitiveIndex:=0 to MeshletPrimitiveCache.fCountPrimitives-1 do begin
      Meshlet^.Indices[PrimitiveIndex,0]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,0];
      Meshlet^.Indices[PrimitiveIndex,1]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,1];
      Meshlet^.Indices[PrimitiveIndex,2]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,2];
     end;

    end;

    MeshletPrimitiveCache.Reset;

   end;

   MeshletPrimitiveCache.Insert(a,b,c);

  end;

  if not MeshletPrimitiveCache.Empty then begin

   Meshlet:=pointer(aMeshlets.AddNew);
   Meshlet^.CountPrimitives:=MeshletPrimitiveCache.fCountPrimitives;
   for PrimitiveIndex:=0 to MeshletPrimitiveCache.fCountPrimitives-1 do begin
    Meshlet^.Indices[PrimitiveIndex,0]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,0];
    Meshlet^.Indices[PrimitiveIndex,1]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,1];
    Meshlet^.Indices[PrimitiveIndex,2]:=MeshletPrimitiveCache.fPrimitives[PrimitiveIndex,2];
   end;

  end;

 finally
  FreeAndNil(MeshletPrimitiveCache);
 end;

end;

end.