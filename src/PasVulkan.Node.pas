(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2023, Benjamin Rosseaux (benjamin@rosseaux.de)          *
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
unit PasVulkan.Node;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}

interface

uses Classes,SysUtils,PasVulkan.Types,PasVulkan.Collections;

type TpvNode=class;

     TpvNodes=TpvObjectGenericList<TpvNode>;

     { TpvNode }
     TpvNode=class
      public
      private
       fParent:TpvNode;
       fData:TObject;
       fChildren:TpvNodes;
      public
       constructor Create(const aParent:TpvNode;const aData:TObject=nil); reintroduce; virtual;
       destructor Destroy; override;
       procedure Store; virtual;
       procedure Update(const aDeltaTime:TpvDouble); virtual;
       procedure Interpolate(const aAlpha:TpvDouble); virtual;
      published
       property Parent:TpvNode read fParent;
       property Data:TObject read fData;
       property Children:TpvNodes read fChildren;
     end;

implementation

{ TpvNode }

constructor TpvNode.Create(const aParent:TpvNode;const aData:TObject);
begin
 inherited Create;
 fParent:=aParent;
 fData:=aData;
 fChildren:=TpvNodes.Create;
 fChildren.OwnsObjects:=true;
end;

destructor TpvNode.Destroy;
begin
 FreeAndNil(fChildren);
 inherited Destroy;
end;

procedure TpvNode.Store;
var ChildNodeIndex:TpvSizeInt;
    ChildNode:TpvNode;
begin
 for ChildNodeIndex:=0 to fChildren.Count-1 do begin
  ChildNode:=fChildren[ChildNodeIndex];
  ChildNode.Store;
 end;
end;

procedure TpvNode.Update(const aDeltaTime:TpvDouble);
var ChildNodeIndex:TpvSizeInt;
    ChildNode:TpvNode;
begin
 for ChildNodeIndex:=0 to fChildren.Count-1 do begin
  ChildNode:=fChildren[ChildNodeIndex];
  ChildNode.Update(aDeltaTime);
 end;
end;

procedure TpvNode.Interpolate(const aAlpha:TpvDouble);
var ChildNodeIndex:TpvSizeInt;
    ChildNode:TpvNode;
begin
 for ChildNodeIndex:=0 to fChildren.Count-1 do begin
  ChildNode:=fChildren[ChildNodeIndex];
  ChildNode.Interpolate(aAlpha);
 end;
end;

end.

