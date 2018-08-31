(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                   Version see PasVulkan.RandomGenerator.pas                *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2018, Benjamin Rosseaux (benjamin@rosseaux.de)          *
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
unit PasVulkan.IDManager;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$m+}

interface

uses SysUtils,
     Classes,
     PasMP,
     PasVulkan.Types,
     PasVulkan.Collections;

type TpvIDManager<T>=class
      private
       type TIDManagerIntegerList=TpvGenericList<T>;
      private
       fCriticalSection:TPasMPCriticalSection;
       fIDCounter:T;
       fIDFreeList:TIDManagerIntegerList;
      public
       constructor Create; reintroduce;
       destructor Destroy; override;
       function AllocateID:T;
       procedure FreeID(aID:T);
       property IDCounter:T read fIDCounter;
       property IDFreeList:TIDManagerIntegerList read fIDFreeList;
     end;

implementation

constructor TpvIDManager<T>.Create;
begin
 inherited Create;
 fCriticalSection:=TPasMPCriticalSection.Create;
 FillChar(fIDCounter,SizeOf(T),#0);
 fIDFreeList:=TIDManagerIntegerList.Create;
end;

destructor TpvIDManager<T>.Destroy;
begin
 fIDFreeList.Free;
 fCriticalSection.Free;
 inherited Destroy;
end;

function TpvIDManager<T>.AllocateID:T;
begin
 fCriticalSection.Enter;
 try
  if fIDFreeList.Count>0 then begin
   result:=fIDFreeList.Items[fIDFreeList.Count-1];
   fIDFreeList.Delete(fIDFreeList.Count-1);
  end else begin
   result:=fIDCounter;
   case SizeOf(T) of
    1:begin
     inc(PpvUInt8(@fIDCounter)^);
    end;
    2:begin
     inc(PpvUInt16(@fIDCounter)^);
    end;
    4:begin
     inc(PpvUInt32(@fIDCounter)^);
    end;
    8:begin
     inc(PpvUInt64(@fIDCounter)^);
    end;
    else begin
     Assert(false);
    end;
   end;
  end;
 finally
  fCriticalSection.Leave;
 end;
end;

procedure TpvIDManager<T>.FreeID(aID:T);
begin
 fCriticalSection.Enter;
 try
  fIDFreeList.Add(aID);
 finally
  fCriticalSection.Leave;
 end;
end;

end.
