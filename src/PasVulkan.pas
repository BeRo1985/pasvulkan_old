(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                        Version 2016-07-09-13-55-0000                       *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016, Benjamin Rosseaux (benjamin@rosseaux.de)               *
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
 * 3. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 4. Write code, which is compatible with Delphi 7-XE7 and FreePascal >= 3.0 *
 *    so don't use generics/templates, operator overloading and another newer *
 *    syntax features than Delphi 7 has support for that, but if needed, make *
 *    it out-ifdef-able.                                                      *
 * 5. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 6. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 7. Try to use const when possible.                                         *
 * 8. Make sure to comment out writeln, used while debugging.                 *
 * 9. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,     *
 *    x86-64, ARM, ARM64, etc.).                                              *
 * 10. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpui386}
  {$define cpu386}
 {$endif}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
 {$ifdef cpuamd64}
  {$asmmode intel}
 {$endif}
 {$ifdef FPC_LITTLE_ENDIAN}
  {$define LITTLE_ENDIAN}
 {$else}
  {$ifdef FPC_BIG_ENDIAN}
   {$define BIG_ENDIAN}
  {$endif}
 {$endif}
 {-$pic off}
 {$define caninline}
 {$ifdef FPC_HAS_TYPE_EXTENDED}
  {$define HAS_TYPE_EXTENDED}
 {$else}
  {$undef HAS_TYPE_EXTENDED}
 {$endif}
 {$ifdef FPC_HAS_TYPE_DOUBLE}
  {$define HAS_TYPE_DOUBLE}
 {$else}
  {$undef HAS_TYPE_DOUBLE}
 {$endif}
 {$ifdef FPC_HAS_TYPE_SINGLE}
  {$define HAS_TYPE_SINGLE}
 {$else}
  {$undef HAS_TYPE_SINGLE}
 {$endif}
{$else}
 {$realcompatibility off}
 {$localsymbols on}
 {$define LITTLE_ENDIAN}
 {$ifndef cpu64}
  {$define cpu32}
 {$endif}
 {$define HAS_TYPE_EXTENDED}
 {$define HAS_TYPE_DOUBLE}
 {$define HAS_TYPE_SINGLE}
 {$ifndef BCB}
  {$ifdef ver120}
   {$define Delphi4or5}
  {$endif}
  {$ifdef ver130}
   {$define Delphi4or5}
  {$endif}
  {$ifdef ver140}
   {$define Delphi6}
  {$endif}
  {$ifdef ver150}
   {$define Delphi7}
  {$endif}
  {$ifdef ver170}
   {$define Delphi2005}
  {$endif}
 {$else}
  {$ifdef ver120}
   {$define Delphi4or5}
   {$define BCB4}
  {$endif}
  {$ifdef ver130}
   {$define Delphi4or5}
  {$endif}
 {$endif}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24}
   {$legacyifend on}
  {$ifend}
  {$if CompilerVersion>=14.0}
   {$if CompilerVersion=14.0}
    {$define Delphi6}
   {$ifend}
   {$define Delphi6AndUp}
  {$ifend}
  {$if CompilerVersion>=15.0}
   {$if CompilerVersion=15.0}
    {$define Delphi7}
   {$ifend}
   {$define Delphi7AndUp}
  {$ifend}
  {$if CompilerVersion>=17.0}
   {$if CompilerVersion=17.0}
    {$define Delphi2005}
   {$ifend}
   {$define Delphi2005AndUp}
  {$ifend}
  {$if CompilerVersion>=18.0}
   {$if CompilerVersion=18.0}
    {$define BDS2006}
    {$define Delphi2006}
   {$ifend}
   {$define Delphi2006AndUp}
  {$ifend}
  {$if CompilerVersion>=18.5}
   {$if CompilerVersion=18.5}
    {$define Delphi2007}
   {$ifend}
   {$define Delphi2007AndUp}
  {$ifend}
  {$if CompilerVersion=19.0}
   {$define Delphi2007Net}
  {$ifend}
  {$if CompilerVersion>=20.0}
   {$if CompilerVersion=20.0}
    {$define Delphi2009}
   {$ifend}
   {$define Delphi2009AndUp}
  {$ifend}
  {$if CompilerVersion>=21.0}
   {$if CompilerVersion=21.0}
    {$define Delphi2010}
   {$ifend}
   {$define Delphi2010AndUp}
  {$ifend}
  {$if CompilerVersion>=22.0}
   {$if CompilerVersion=22.0}
    {$define DelphiXE}
   {$ifend}
   {$define DelphiXEAndUp}
  {$ifend}
  {$if CompilerVersion>=23.0}
   {$if CompilerVersion=23.0}
    {$define DelphiXE2}
   {$ifend}
   {$define DelphiXE2AndUp}
  {$ifend}
  {$if CompilerVersion>=24.0}
   {$if CompilerVersion=24.0}
    {$define DelphiXE3}
   {$ifend}
   {$define DelphiXE3AndUp}
  {$ifend}
  {$if CompilerVersion>=25.0}
   {$if CompilerVersion=25.0}
    {$define DelphiXE4}
   {$ifend}
   {$define DelphiXE4AndUp}
  {$ifend}
  {$if CompilerVersion>=26.0}
   {$if CompilerVersion=26.0}
    {$define DelphiXE5}
   {$ifend}
   {$define DelphiXE5AndUp}
  {$ifend}
  {$if CompilerVersion>=27.0}
   {$if CompilerVersion=27.0}
    {$define DelphiXE6}
   {$ifend}
   {$define DelphiXE6AndUp}
  {$ifend}
  {$if CompilerVersion>=28.0}
   {$if CompilerVersion=28.0}
    {$define DelphiXE7}
   {$ifend}
   {$define DelphiXE7AndUp}
  {$ifend}
  {$if CompilerVersion>=29.0}
   {$if CompilerVersion=29.0}
    {$define DelphiXE8}
   {$ifend}
   {$define DelphiXE8AndUp}
  {$ifend}
  {$if CompilerVersion>=30.0}
   {$if CompilerVersion=30.0}
    {$define Delphi10Seattle}
   {$ifend}
   {$define Delphi10SeattleAndUp}
  {$ifend}
  {$if CompilerVersion>=31.0}
   {$if CompilerVersion=31.0}
    {$define Delphi10Berlin}
   {$ifend}
   {$define Delphi10BerlinAndUp}
  {$ifend}
 {$endif}
 {$ifndef Delphi4or5}
  {$ifndef BCB}
   {$define Delphi6AndUp}
  {$endif}
   {$ifndef Delphi6}
    {$define BCB6OrDelphi7AndUp}
    {$ifndef BCB}
     {$define Delphi7AndUp}
    {$endif}
    {$ifndef BCB}
     {$ifndef Delphi7}
      {$ifndef Delphi2005}
       {$define BDS2006AndUp}
      {$endif}
     {$endif}
    {$endif}
   {$endif}
 {$endif}
 {$ifdef Delphi6AndUp}
  {$warn symbol_platform off}
  {$warn symbol_deprecated off}
 {$endif}
{$endif}
{$ifdef win32}
 {$define windows}
{$endif}
{$ifdef win64}
 {$define windows}
{$endif}
{$ifdef wince}
 {$define windows}
{$endif}
{$rangechecks off}
{$extendedsyntax on}
{$writeableconst on}
{$hints off}
{$booleval off}
{$typedaddress off}
{$stackframes off}
{$varstringchecks on}
{$typeinfo on}
{$overflowchecks off}
{$longstrings on}
{$openstrings on}
{$ifndef HAS_TYPE_DOUBLE}
 {$error No double floating point precision}
{$endif}

interface

uses {$ifdef Windows}Windows,{$endif}{$ifdef Unix}BaseUnix,UnixType,dl,{$endif}{$ifdef X11}x,xlib,{$endif}{$ifdef XCB}xcb,{$endif}{$ifdef Mir}Mir,{$endif}{$ifdef Wayland}Wayland,{$endif}{$ifdef Android}Android,{$endif}SysUtils,Classes,SyncObjs,Math,Vulkan;

type EVulkanException=class(Exception);

     EVulkanMemoryAllocation=class(EVulkanException);

     EVulkanResultException=class(EVulkanException)
      private
       fResultCode:TVkResult;
      public
       constructor Create(const pResultCode:TVkResult);
       destructor Destroy; override;
      published
       property ResultCode:TVkResult read fResultCode;
     end;

     TVulkanObject=class(TInterfacedObject);

     TVulkanCharString=AnsiString;

     TVulkanCharStringArray=array of TVulkanCharString;
     TVkInt32Array=array of TVkInt32;
     TVkUInt32Array=array of TVkUInt32;
     TVkFloatArray=array of TVkFloat;
     TVkLayerPropertiesArray=array of TVkLayerProperties;
     TVkExtensionPropertiesArray=array of TVkExtensionProperties;
     TVkLayerExtensionPropertiesArray=array of array of TVkExtensionProperties;
     TPVkCharArray=array of PVkChar;
     TVkPhysicalDeviceArray=array of TVkPhysicalDevice;
     TVkQueueFamilyPropertiesArray=array of TVkQueueFamilyProperties;
     TVkSparseImageFormatPropertiesArray=array of TVkSparseImageFormatProperties;
     TVkSurfaceFormatKHRArray=array of TVkSurfaceFormatKHR;
     TVkPresentModeKHRArray=array of TVkPresentModeKHR;
     TVkDisplayPropertiesKHRArray=array of TVkDisplayPropertiesKHR;
     TVkDisplayPlanePropertiesKHRArray=array of TVkDisplayPlanePropertiesKHR;
     TVkDisplayKHRArray=array of TVkDisplayKHR;
     TVkDisplayModePropertiesKHRArray=array of TVkDisplayModePropertiesKHR;
     TVkDeviceQueueCreateInfoArray=array of TVkDeviceQueueCreateInfo;
     TVkImageArray=array of TVkImage;
     TVkCommandBufferArray=array of TVkCommandBuffer;
     TVkDescriptorSetLayoutBindingArray=array of TVkDescriptorSetLayoutBinding;
     TVkDescriptorSetLayoutArray=array of TVkDescriptorSetLayout;
     TVkPushConstantRangeArray=array of TVkPushConstantRange;
     TVkPipelineShaderStageCreateInfoArray=array of TVkPipelineShaderStageCreateInfo;
     TVkPipelineVertexInputStateCreateInfoArray=array of TVkPipelineVertexInputStateCreateInfo;
     TVkAttachmentDescriptionArray=array of TVkAttachmentDescription;
     TVkSubpassDescriptionArray=array of TVkSubpassDescription;
     TVkSubpassDependencyArray=array of TVkSubpassDependency;
     TVkAttachmentReferenceArray=array of TVkAttachmentReference;
     TVkMemoryBarrierArray=array of TVkMemoryBarrier;
     TVkBufferMemoryBarrierArray=array of TVkBufferMemoryBarrier;
     TVkImageMemoryBarrierArray=array of TVkImageMemoryBarrier;
     TVkViewportArray=array of TVkViewport;
     TVkRect2DArray=array of TVkRect2D;
     TVkSampleMaskArray=array of TVkSampleMask;
     TVkVertexInputBindingDescriptionArray=array of TVkVertexInputBindingDescription;
     TVkVertexInputAttributeDescriptionArray=array of TVkVertexInputAttributeDescription;
     TVkPipelineColorBlendAttachmentStateArray=array of TVkPipelineColorBlendAttachmentState;
     TVkDynamicStateArray=array of TVkDynamicState;
     TVkDescriptorPoolSizeArray=array of TVkDescriptorPoolSize;
     TVkDescriptorSetArray=array of TVkDescriptorSet;
     TVkDescriptorImageInfoArray=array of TVkDescriptorImageInfo;
     TVkDescriptorBufferInfoArray=array of TVkDescriptorBufferInfo;
     TVkClearValueArray=array of TVkClearValue;
     TVkResultArray=array of TVkResult;

     TVulkanBaseList=class(TVulkanObject)
      private
       fItemSize:TVkSizeInt;
       fCount:TVkSizeInt;
       fAllocated:TVkSizeInt;
       fMemory:pointer;
       procedure SetCount(const NewCount:TVkSizeInt);
       function GetItem(const Index:TVkSizeInt):pointer;
      protected
       procedure InitializeItem(var Item); virtual;
       procedure FinalizeItem(var Item); virtual;
       procedure CopyItem(const Source;var Destination); virtual;
       procedure ExchangeItem(var Source,Destination); virtual;
       function CompareItem(const Source,Destination):longint; virtual;
      public
       constructor Create(const pItemSize:TVkSizeInt);
       destructor Destroy; override;
       procedure Clear; virtual;
       procedure FillWith(const SourceData;const SourceCount:TVkSizeInt); virtual;
       function Add(const Item):TVkSizeInt;
       function Find(const Item):TVkSizeInt;
       procedure Insert(const Index:TVkSizeInt;const Item);
       procedure Delete(const Index:TVkSizeInt);
       procedure Remove(const Item);
       procedure Exchange(const Index,WithIndex:TVkSizeInt);
       property Count:TVkSizeInt read fCount write SetCount;
       property Allocated:TVkSizeInt read fAllocated;
       property Memory:pointer read fMemory;
       property ItemPointers[const Index:TVkSizeInt]:pointer read GetItem; default;
     end;

     TVulkanObjectList=class(TVulkanBaseList)
      private
       fOwnObjects:boolean;
       function GetItem(const Index:TVkSizeInt):TVulkanObject;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVulkanObject);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function Add(const Item:TVulkanObject):TVkSizeInt; reintroduce;
       function Find(const Item:TVulkanObject):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVulkanObject); reintroduce;
       procedure Remove(const Item:TVulkanObject); reintroduce;
       property Items[const Index:TVkSizeInt]:TVulkanObject read GetItem write SetItem; default;
       property OwnObjects:boolean read fOwnObjects write fOwnObjects;
     end;

     TVkUInt32List=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkUInt32;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkUInt32);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkUInt32):TVkSizeInt; reintroduce;
       function Find(const Item:TVkUInt32):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkUInt32); reintroduce;
       procedure Remove(const Item:TVkUInt32); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkUInt32 read GetItem write SetItem; default;
     end;

     TVkFloatList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkFloat;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkFloat);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkFloat):TVkSizeInt; reintroduce;
       function Find(const Item:TVkFloat):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkFloat); reintroduce;
       procedure Remove(const Item:TVkFloat); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkFloat read GetItem write SetItem; default;
     end;

     TVkImageViewList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkImageView;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkImageView);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkImageView):TVkSizeInt; reintroduce;
       function Find(const Item:TVkImageView):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkImageView); reintroduce;
       procedure Remove(const Item:TVkImageView); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkImageView read GetItem write SetItem; default;
     end;

     TVkSamplerList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkSampler;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkSampler);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkSampler):TVkSizeInt; reintroduce;
       function Find(const Item:TVkSampler):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkSampler); reintroduce;
       procedure Remove(const Item:TVkSampler); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkSampler read GetItem write SetItem; default;
     end;

     TVkDescriptorSetLayoutList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkDescriptorSetLayout;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkDescriptorSetLayout):TVkSizeInt; reintroduce;
       function Find(const Item:TVkDescriptorSetLayout):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout); reintroduce;
       procedure Remove(const Item:TVkDescriptorSetLayout); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkDescriptorSetLayout read GetItem write SetItem; default;
     end;

     TVkSampleMaskList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkSampleMask;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkSampleMask);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkSampleMask):TVkSizeInt; reintroduce;
       function Find(const Item:TVkSampleMask):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkSampleMask); reintroduce;
       procedure Remove(const Item:TVkSampleMask); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkSampleMask read GetItem write SetItem; default;
     end;

     TVkDynamicStateList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkDynamicState;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkDynamicState);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkDynamicState):TVkSizeInt; reintroduce;
       function Find(const Item:TVkDynamicState):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkDynamicState); reintroduce;
       procedure Remove(const Item:TVkDynamicState); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkDynamicState read GetItem write SetItem; default;
     end;

     TVkBufferViewList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkBufferView;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkBufferView);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkBufferView):TVkSizeInt; reintroduce;
       function Find(const Item:TVkBufferView):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkBufferView); reintroduce;
       procedure Remove(const Item:TVkBufferView); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkBufferView read GetItem write SetItem; default;
     end;

     TVkClearValueList=class(TVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkClearValue;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkClearValue);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):longint; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkClearValue):TVkSizeInt; reintroduce;
       function Find(const Item:TVkClearValue):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkClearValue); reintroduce;
       procedure Remove(const Item:TVkClearValue); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkClearValue read GetItem write SetItem; default;
     end;

     TVulkanHandle=class(TVulkanObject)
      private
      protected
      public
       constructor Create;
       destructor Destroy; override;
      published
     end;

     TVulkanAllocationManager=class(TVulkanObject)
      private
       fAllocationCallbacks:TVkAllocationCallbacks;
      protected
       function AllocationCallback(const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid; virtual;
       function ReallocationCallback(const Original:PVkVoid;const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid; virtual;
       procedure FreeCallback(const Memory:PVkVoid); virtual;
       procedure InternalAllocationCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
       procedure InternalFreeCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
      public
       constructor Create;
       destructor Destroy; override;
       property AllocationCallbacks:TVkAllocationCallbacks read fAllocationCallbacks;
     end;

     PVulkanAvailableLayer=^TVulkanAvailableLayer;
     TVulkanAvailableLayer=record
      LayerName:TVulkanCharString;
      SpecVersion:TVkUInt32;
      ImplementationVersion:TVkUInt32;
      Description:TVulkanCharString;
     end;

     TVulkanAvailableLayers=array of TVulkanAvailableLayer;

     PVulkanAvailableExtension=^TVulkanAvailableExtension;
     TVulkanAvailableExtension=record
      LayerIndex:TVkUInt32;
      ExtensionName:TVulkanCharString;
      SpecVersion:TVkUInt32;
     end;

     TVulkanAvailableExtensions=array of TVulkanAvailableExtension;

     TVulkanInstance=class;

     TVulkanPhysicalDevice=class;

     TVulkanPhysicalDeviceList=class;

     TVulkanInstanceDebugReportCallback=function(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TVkInt32;const pLayerPrefix:TVulkaNCharString;const pMessage:TVulkanCharString):TVkBool32 of object;

     TVulkanInstance=class(TVulkanHandle)
      private    
       fVulkan:TVulkan;
       fApplicationInfo:TVkApplicationInfo;
       fApplicationName:TVulkanCharString;
       fEngineName:TVulkanCharString;
       fValidation:longbool;
       fAllocationManager:TVulkanAllocationManager;
       fAllocationCallbacks:PVkAllocationCallbacks;
       fAvailableLayers:TVulkanAvailableLayers;
       fAvailableExtensions:TVulkanAvailableExtensions;
       fAvailableLayerNames:TStringList;
       fAvailableExtensionNames:TStringList;
       fEnabledLayerNames:TStringList;
       fEnabledExtensionNames:TStringList;
       fInstanceCreateInfo:TVkInstanceCreateInfo;
       fEnabledLayerNameStrings:array of TVulkanCharString;
       fEnabledExtensionNameStrings:array of TVulkanCharString;
       fRawEnabledLayerNameStrings:array of PVkChar;
       fRawEnabledExtensionNameStrings:array of PVkChar;
       fInstanceHandle:TVkInstance;
       fInstanceVulkan:TVulkan;
       fPhysicalDevices:TVulkanPhysicalDeviceList;
       fNeedToEnumeratePhysicalDevices:boolean;
       fDebugReportCallbackCreateInfoEXT:TVkDebugReportCallbackCreateInfoEXT;
       fDebugReportCallbackEXT:TVkDebugReportCallbackEXT;
       fOnInstanceDebugReportCallback:TVulkanInstanceDebugReportCallback;
       procedure SetApplicationInfo(const NewApplicationInfo:TVkApplicationInfo);
       function GetApplicationName:TVulkanCharString;
       procedure SetApplicationName(const NewApplicationName:TVulkanCharString);
       function GetApplicationVersion:TVkUInt32;
       procedure SetApplicationVersion(const NewApplicationVersion:TVkUInt32);
       function GetEngineName:TVulkanCharString;
       procedure SetEngineName(const NewEngineName:TVulkanCharString);
       function GetEngineVersion:TVkUInt32;
       procedure SetEngineVersion(const NewEngineVersion:TVkUInt32);
       function GetAPIVersion:TVkUInt32;
       procedure SetAPIVersion(const NewAPIVersion:TVkUInt32);
       procedure EnumeratePhysicalDevices;
      protected
       function DebugReportCallback(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TVkInt32;const pLayerPrefix:TVulkaNCharString;const pMessage:TVulkanCharString):TVkBool32; virtual;
      public
       constructor Create(const pApplicationName:TVulkanCharString='Vulkan application';
                          const pApplicationVersion:TVkUInt32=1;
                          const pEngineName:TVulkanCharString='Vulkan engine';
                          const pEngineVersion:TVkUInt32=1;
                          const pAPIVersion:TVkUInt32=VK_API_VERSION_1_0;
                          const pValidation:boolean=false;
                          const pAllocationManager:TVulkanAllocationManager=nil);
       destructor Destroy; override;
       procedure Initialize;
       procedure InstallDebugReportCallback;
       property ApplicationName:TVulkanCharString read GetApplicationName write SetApplicationName;
       property ApplicationVersion:TVkUInt32 read GetApplicationVersion write SetApplicationVersion;
       property EngineName:TVulkanCharString read GetEngineName write SetEngineName;
       property EngineVersion:TVkUInt32 read GetEngineVersion write SetEngineVersion;
       property APIVersion:TVkUInt32 read GetAPIVersion write SetAPIVersion;
       property Validation:longbool read fValidation write fValidation;
       property ApplicationInfo:TVkApplicationInfo read fApplicationInfo write SetApplicationInfo;
       property AvailableLayers:TVulkanAvailableLayers read fAvailableLayers;
       property AvailableExtensions:TVulkanAvailableExtensions read fAvailableExtensions;
       property AvailableLayerNames:TStringList read fAvailableLayerNames;
       property AvailableExtensionNames:TStringList read fAvailableExtensionNames;
       property EnabledLayerNames:TStringList read fEnabledLayerNames;
       property EnabledExtensionNames:TStringList read fEnabledExtensionNames;
       property Handle:TVkInstance read fInstanceHandle;
       property Commands:TVulkan read fInstanceVulkan;
       property PhysicalDevices:TVulkanPhysicalDeviceList read fPhysicalDevices;
       property OnInstanceDebugReportCallback:TVulkanInstanceDebugReportCallback read fOnInstanceDebugReportCallback write fOnInstanceDebugReportCallback;
     end;

     TVulkanSurface=class;

     TVulkanPhysicalDevice=class(TVulkanObject)
      private
       fInstance:TVulkanInstance;
       fPhysicalDeviceHandle:TVkPhysicalDevice;
       fDeviceName:TVulkanCharString;
       fProperties:TVkPhysicalDeviceProperties;
       fMemoryProperties:TVkPhysicalDeviceMemoryProperties;
       fFeatures:TVkPhysicalDeviceFeatures;
       fQueueFamilyProperties:TVkQueueFamilyPropertiesArray;
       fAvailableLayers:TVulkanAvailableLayers;
       fAvailableExtensions:TVulkanAvailableExtensions;
       fAvailableLayerNames:TStringList;
       fAvailableExtensionNames:TStringList;
      public
       constructor Create(const pInstance:TVulkanInstance;const pPhysicalDevice:TVkPhysicalDevice);
       destructor Destroy; override;
       function GetFormatProperties(const pFormat:TVkFormat):TVkFormatProperties;
       function GetImageFormatProperties(const pFormat:TVkFormat;
                                         const pType:TVkImageType;
                                         const pTiling:TVkImageTiling;
                                         const pUsageFlags:TVkImageUsageFlags;
                                         const pCreateFlags:TVkImageCreateFlags):TVkImageFormatProperties;
       function GetSparseImageFormatProperties(const pFormat:TVkFormat;
                                               const pType:TVkImageType;
                                               const pSamples:TVkSampleCountFlagBits;
                                               const pUsageFlags:TVkImageUsageFlags;
                                               const pTiling:TVkImageTiling):TVkSparseImageFormatPropertiesArray;
       function GetSurfaceSupport(const pQueueFamilyIndex:TVkUInt32;const pSurface:TVulkanSurface):boolean;
       function GetSurfaceCapabilities(const pSurface:TVulkanSurface):TVkSurfaceCapabilitiesKHR;
       function GetSurfaceFormats(const pSurface:TVulkanSurface):TVkSurfaceFormatKHRArray;
       function GetSurfacePresentModes(const pSurface:TVulkanSurface):TVkPresentModeKHRArray;
       function GetDisplayProperties:TVkDisplayPropertiesKHRArray;
       function GetDisplayPlaneProperties:TVkDisplayPlanePropertiesKHRArray;
       function GetDisplayPlaneSupportedDisplays(const pPlaneIndex:TVkUInt32):TVkDisplayKHRArray;
       function GetDisplayModeProperties(const pDisplay:TVkDisplayKHR):TVkDisplayModePropertiesKHRArray;
       function GetMemoryType(const pTypeBits:TVkUInt32;const pProperties:TVkFlags):TVkUInt32;
       function GetBestSupportedDepthFormat(const pWithStencil:boolean):TVkFormat;
       function GetQueueNodeIndex(const pSurface:TVulkanSurface;const pQueueFlagBits:TVkQueueFlagBits):TVkInt32;
       function GetSurfaceFormat(const pSurface:TVulkanSurface):TVkSurfaceFormatKHR;
       property Handle:TVkPhysicalDevice read fPhysicalDeviceHandle;
       property DeviceName:TVulkanCharString read fDeviceName;
       property Properties:TVkPhysicalDeviceProperties read fProperties;
       property MemoryProperties:TVkPhysicalDeviceMemoryProperties read fMemoryProperties;
       property Features:TVkPhysicalDeviceFeatures read fFeatures;
       property QueueFamilyProperties:TVkQueueFamilyPropertiesArray read fQueueFamilyProperties;
       property AvailableLayers:TVulkanAvailableLayers read fAvailableLayers;
       property AvailableExtensions:TVulkanAvailableExtensions read fAvailableExtensions;
       property AvailableLayerNames:TStringList read fAvailableLayerNames;
       property AvailableExtensionNames:TStringList read fAvailableExtensionNames;
     end;

     TVulkanPhysicalDeviceList=class(TVulkanObjectList)
      private
       function GetItem(const Index:TVkSizeInt):TVulkanPhysicalDevice;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVulkanPhysicalDevice);
      public
       property Items[const Index:TVkSizeInt]:TVulkanPhysicalDevice read GetItem write SetItem; default;
     end;

     PVulkanSurfaceCreateInfo=^TVulkanSurfaceCreateInfo;
{$if defined(Android)}
     TVulkanSurfaceCreateInfo=TVkAndroidSurfaceCreateInfoKHR;
{$elseif defined(Mir)}
     TVulkanSurfaceCreateInfo=TVkMirSurfaceCreateInfoKHR;
{$elseif defined(Wayland)}
     TVulkanSurfaceCreateInfo=TVkWaylandSurfaceCreateInfoKHR;
{$elseif defined(Windows)}
     TVulkanSurfaceCreateInfo=TVkWin32SurfaceCreateInfoKHR;
{$elseif defined(X11)}
     TVulkanSurfaceCreateInfo=TVkX11SurfaceCreateInfoKHR;
{$elseif defined(XCB)}
     TVulkanSurfaceCreateInfo=TVkXCBSurfaceCreateInfoKHR;
{$ifend}

     TVulkanSurface=class(TVulkanHandle)
      private
       fInstance:TVulkanInstance;
       fSurfaceCreateInfo:TVulkanSurfaceCreateInfo;
       fSurfaceHandle:TVkSurfaceKHR;
      protected
      public
       constructor Create(const pInstance:TVulkanInstance;
{$if defined(Android)}
                          const pWindow:PANativeWindow
{$elseif defined(Mir)}
                          const pConnection:PMirConnection;const pMirSurface:PMirSurface
{$elseif defined(Wayland)}
                          const pDisplay:Pwl_display;const pSurface:Pwl_surface
{$elseif defined(Windows)}
                          const pInstanceHandle,pWindowHandle:THandle
{$elseif defined(X11)}
                          const pDisplay:PDisplay;const pWindow:TWindow
{$elseif defined(XCB)}
                          const pConnection:Pxcb_connection;pWindow:Pxcb_window
{$ifend}
                         );
       destructor Destroy; override;
       property Handle:TVkSurfaceKHR read fSurfaceHandle;
     end;

     TVulkanDeviceQueueCreateInfo=class;

     TVulkanDeviceQueueCreateInfoList=class;

     TVulkanDeviceMemoryManager=class;

     TVulkanQueue=class;
     
     TVulkanDevice=class(TVulkanHandle)
      private
       fInstance:TVulkanInstance;
       fPhysicalDevice:TVulkanPhysicalDevice;
       fSurface:TVulkanSurface;
       fDeviceQueueCreateInfoList:TVulkanDeviceQueueCreateInfoList;
       fDeviceQueueCreateInfos:TVkDeviceQueueCreateInfoArray;
       fDeviceCreateInfo:TVkDeviceCreateInfo;
       fEnabledLayerNames:TStringList;
       fEnabledExtensionNames:TStringList;
//     fInstanceCreateInfo:TVkInstanceCreateInfo;
       fEnabledLayerNameStrings:array of TVulkanCharString;
       fEnabledExtensionNameStrings:array of TVulkanCharString;
       fRawEnabledLayerNameStrings:array of PVkChar;
       fRawEnabledExtensionNameStrings:array of PVkChar;
       fEnabledFeatures:TVkPhysicalDeviceLimits;
       fPointerToEnabledFeatures:PVkPhysicalDeviceLimits;
       fAllocationManager:TVulkanAllocationManager;
       fAllocationCallbacks:PVkAllocationCallbacks;
       fDeviceHandle:TVkDevice;
       fDeviceVulkan:TVulkan;
       fGraphicQueueFamilyIndex:TVkInt32;
       fComputeQueueFamilyIndex:TVkInt32;
       fTransferQueueFamilyIndex:TVkInt32;
       fSparseBindingQueueFamilyIndex:TVkInt32;
       fGraphicQueue:TVulkanQueue;
       fComputeQueue:TVulkanQueue;
       fTransferQueue:TVulkanQueue;
       fMemoryManager:TVulkanDeviceMemoryManager;
      protected
      public
       constructor Create(const pInstance:TVulkanInstance;
                          const pPhysicalDevice:TVulkanPhysicalDevice=nil;
                          const pSurface:TVulkanSurface=nil;
                          const pAllocationManager:TVulkanAllocationManager=nil);
       destructor Destroy; override;
       procedure AddQueue(const pQueueFamilyIndex:TVkUInt32;const pQueuePriorities:array of TVkFloat);
       procedure AddQueues(const pGraphic:boolean=true;
                           const pCompute:boolean=true;
                           const pTransfer:boolean=true;
                           const pSparseBinding:boolean=false);
       procedure Initialize;
       procedure WaitIdle;
       property PhysicalDevice:TVulkanPhysicalDevice read fPhysicalDevice;
       property Surface:TVulkanSurface read fSurface;
       property EnabledLayerNames:TStringList read fEnabledLayerNames;
       property EnabledExtensionNames:TStringList read fEnabledExtensionNames;
       property EnabledFeatures:PVkPhysicalDeviceLimits read fPointerToEnabledFeatures;
       property Handle:TVkDevice read fDeviceHandle;
       property Commands:TVulkan read fDeviceVulkan;
       property GraphicQueueFamilyIndex:TVkInt32 read fGraphicQueueFamilyIndex;
       property ComputeQueueFamilyIndex:TVkInt32 read fComputeQueueFamilyIndex;
       property TransferQueueFamilyIndex:TVkInt32 read fTransferQueueFamilyIndex;
       property SparseBindingQueueFamilyIndex:TVkInt32 read fSparseBindingQueueFamilyIndex;
       property GraphicQueue:TVulkanQueue read fGraphicQueue;
       property ComputeQueue:TVulkanQueue read fComputeQueue;
       property TransferQueue:TVulkanQueue read fTransferQueue;
       property MemoryManager:TVulkanDeviceMemoryManager read fMemoryManager;
     end;

     TVulkanDeviceQueueCreateInfo=class(TVulkanObject)
      private
       fQueueFamilyIndex:TVkUInt32;
       fQueuePriorities:TVkFloatArray;
      public
       constructor Create(const pQueueFamilyIndex:TVkUInt32;const pQueuePriorities:array of TVkFloat);
       destructor Destroy; override;
       property QueueFamilyIndex:TVkUInt32 read fQueueFamilyIndex;
       property QueuePriorities:TVkFloatArray read fQueuePriorities;
     end;

     TVulkanDeviceQueueCreateInfoList=class(TVulkanObjectList)
      private
       function GetItem(const Index:TVkSizeInt):TVulkanDeviceQueueCreateInfo;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVulkanDeviceQueueCreateInfo);
      public
       property Items[const Index:TVkSizeInt]:TVulkanDeviceQueueCreateInfo read GetItem write SetItem; default;
     end;

     TVulkanResource=class(TVulkanObject)
      private
       fDevice:TVulkanDevice;
       fOwnsResource:boolean;
      public
       constructor Create; reintroduce; virtual;
       destructor Destroy; override;
       procedure Clear; virtual;
       property Device:TVulkanDevice read fDevice write fDevice;
       property OwnsResource:boolean read fOwnsResource write fOwnsResource;
     end;

     TVulkanDeviceMemoryChunkBlock=class;

     PVulkanDeviceMemoryChunkBlockRedBlackTreeKey=^TVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
     TVulkanDeviceMemoryChunkBlockRedBlackTreeKey=TVkDeviceSize;

     PVulkanDeviceMemoryChunkBlockRedBlackTreeValue=^TVulkanDeviceMemoryChunkBlockRedBlackTreeValue;
     TVulkanDeviceMemoryChunkBlockRedBlackTreeValue=TVulkanDeviceMemoryChunkBlock;

     PVulkanDeviceMemoryChunkBlockRedBlackTreeNode=^TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
     TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=class(TVulkanObject)
      private
       fKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
       fValue:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue;
       fLeft:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fRight:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fParent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fColor:boolean;
      public
       constructor Create(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey=0;
                          const pValue:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue=nil;
                          const pLeft:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const pRight:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const pParent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const pColor:boolean=false);
       destructor Destroy; override;
       procedure Clear;
       function Minimum:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Maximum:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Predecessor:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Successor:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       property Key:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey read fKey write fKey;
       property Value:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue read fValue write fValue;
       property Left:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fLeft write fLeft;
       property Right:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fRight write fRight;
       property Parent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fParent write fParent;
       property Color:boolean read fColor write fColor;
     end;

     TVulkanDeviceMemoryChunkBlockRedBlackTree=class(TVulkanObject)
      private
       fRoot:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
      protected
       procedure RotateLeft(x:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
       procedure RotateRight(x:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear;
       function Find(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey):TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Insert(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
                       const pValue:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue):TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       procedure Remove(const pNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
       procedure Delete(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey);
       function LeftMost:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function RightMost:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       property Root:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fRoot;
     end;

     TVulkanDeviceMemoryChunk=class;

     TVulkanDeviceMemoryChunkBlock=class(TVulkanObject)
      private
       fMemoryChunk:TVulkanDeviceMemoryChunk;
       fOffset:TVkDeviceSize;
       fSize:TVkDeviceSize;
       fUsed:boolean;
       fOffsetRedBlackTreeNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fSizeRedBlackTreeNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
      public
       constructor Create(const pMemoryChunk:TVulkanDeviceMemoryChunk;
                          const pOffset:TVkDeviceSize;
                          const pSize:TVkDeviceSize;
                          const pUsed:boolean);
       destructor Destroy; override;
       procedure Update(const pOffset:TVkDeviceSize;
                        const pSize:TVkDeviceSize;
                        const pUsed:boolean);
       property MemoryChunk:TVulkanDeviceMemoryChunk read fMemoryChunk;
       property Offset:TVkDeviceSize read fOffset;
       property Size:TVkDeviceSize read fSize;
       property Used:boolean read fUsed;
     end;

     PVulkanDeviceMemoryManagerChunkList=^TVulkanDeviceMemoryManagerChunkList;
     PVulkanDeviceMemoryManagerChunkLists=^TVulkanDeviceMemoryManagerChunkLists;

     TVulkanDeviceMemoryChunk=class(TVulkanObject)
      private
       fMemoryManager:TVulkanDeviceMemoryManager;
       fPreviousMemoryChunk:TVulkanDeviceMemoryChunk;
       fNextMemoryChunk:TVulkanDeviceMemoryChunk;
       fLock:TCriticalSection;
       fAlignment:TVkDeviceSize;
       fMemoryChunkList:PVulkanDeviceMemoryManagerChunkList;
       fSize:TVkDeviceSize;
       fUsed:TVkDeviceSize;
       fMappedOffset:TVkDeviceSize;
       fMappedSize:TVkDeviceSize;
       fOffsetRedBlackTree:TVulkanDeviceMemoryChunkBlockRedBlackTree;
       fSizeRedBlackTree:TVulkanDeviceMemoryChunkBlockRedBlackTree;
       fMemoryTypeIndex:TVkUInt32;
       fMemoryTypeBits:TVkUInt32;
       fMemoryHeapIndex:TVkUInt32;
       fMemoryPropertyFlags:TVkMemoryPropertyFlags;
       fMemoryHandle:TVkDeviceMemory;
       fMemory:PVkVoid;
      public
       constructor Create(const pMemoryManager:TVulkanDeviceMemoryManager;
                          const pSize:TVkDeviceSize;
                          const pAlignment:TVkDeviceSize;
                          const pMemoryTypeBits:TVkUInt32;
                          const pMemoryPropertyFlags:TVkMemoryPropertyFlags;
                          const pMemoryChunkList:PVulkanDeviceMemoryManagerChunkList;
                          const pMemoryHeapFlags:TVkMemoryHeapFlags=0);
       destructor Destroy; override;
       function AllocateMemory(out pOffset:TVkDeviceSize;const pSize:TVkDeviceSize):boolean;
       function ReallocateMemory(var pOffset:TVkDeviceSize;const pSize:TVkDeviceSize):boolean;
       function FreeMemory(const pOffset:TVkDeviceSize):boolean;
       function MapMemory(const pOffset:TVkDeviceSize=0;const pSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
       procedure UnmapMemory;
       procedure FlushMappedMemory;
       procedure InvalidateMappedMemory;
       property MemoryManager:TVulkanDeviceMemoryManager read fMemoryManager;
       property Size:TVkDeviceSize read fSize;
       property MemoryPropertyFlags:TVkMemoryPropertyFlags read fMemoryPropertyFlags;
       property MemoryTypeIndex:TVkUInt32 read fMemoryTypeIndex;
       property MemoryTypeBits:TVkUInt32 read fMemoryTypeBits;
       property MemoryHeapIndex:TVkUInt32 read fMemoryHeapIndex;
       property Handle:TVkDeviceMemory read fMemoryHandle;
       property Memory:PVkVoid read fMemory;
     end;

     TVulkanDeviceMemoryBlock=class(TVulkanObject)
      private
       fMemoryManager:TVulkanDeviceMemoryManager;
       fMemoryChunk:TVulkanDeviceMemoryChunk;
       fOffset:TVkDeviceSize;
       fSize:TVkDeviceSize;
       fPreviousMemoryBlock:TVulkanDeviceMemoryBlock;
       fNextMemoryBlock:TVulkanDeviceMemoryBlock;
      public
       constructor Create(const pMemoryManager:TVulkanDeviceMemoryManager;
                          const pMemoryChunk:TVulkanDeviceMemoryChunk;
                          const pOffset:TVkDeviceSize;
                          const pSize:TVkDeviceSize);
       destructor Destroy; override;
       function MapMemory(const pOffset:TVkDeviceSize=0;const pSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
       procedure UnmapMemory;
       procedure FlushMappedMemory;
       procedure InvalidateMappedMemory;
       function Fill(const pData:PVkVoid;const pSize:TVkDeviceSize):TVkDeviceSize;
       property MemoryManager:TVulkanDeviceMemoryManager read fMemoryManager;
       property MemoryChunk:TVulkanDeviceMemoryChunk read fMemoryChunk;
       property Offset:TVkDeviceSize read fOffset;
       property Size:TVkDeviceSize read fSize;
     end;

     TVulkanDeviceMemoryManagerChunkList=record
      First:TVulkanDeviceMemoryChunk;
      Last:TVulkanDeviceMemoryChunk;
     end;

     TVulkanDeviceMemoryManagerChunkLists=array[0..31] of TVulkanDeviceMemoryManagerChunkList;

     TVulkanDeviceMemoryManager=class(TVulkanObject)
      private
       fDevice:TVulkanDevice;
       fLock:TCriticalSection;
       fMemoryChunkLists:TVulkanDeviceMemoryManagerChunkLists;
       fFirstMemoryBlock:TVulkanDeviceMemoryBlock;
       fLastMemoryBlock:TVulkanDeviceMemoryBlock;
      public
       constructor Create(const pDevice:TVulkanDevice);
       destructor Destroy; override;
       function AllocateMemoryBlock(const pSize:TVkDeviceSize;
                                    const pMemoryTypeBits:TVkUInt32;
                                    const pMemoryPropertyFlags:TVkMemoryPropertyFlags;
                                    const pAlignment:TVkDeviceSize=16;
                                    const pOwnSingleMemoryChunk:boolean=false):TVulkanDeviceMemoryBlock;
       function FreeMemoryBlock(const pMemoryBlock:TVulkanDeviceMemoryBlock):boolean;
     end;

     TVulkanQueueFamilyIndices=array of TVkUInt32;

     TVulkanBuffer=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fSize:TVkDeviceSize;
       fMemoryProperties:TVkMemoryPropertyFlags;
       fOwnSingleMemoryChunk:boolean;
       fBufferCreateInfo:TVkBufferCreateInfo;
       fBufferHandle:TVkBuffer;
       fMemoryRequirements:TVkMemoryRequirements;
       fMemoryBlock:TVulkanDeviceMemoryBlock;
       fQueueFamilyIndices:TVulkanQueueFamilyIndices;
       fCountQueueFamilyIndices:TVkInt32;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pSize:TVkDeviceSize;
                          const pUsage:TVkBufferUsageFlags;
                          const pSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                          const pQueueFamilyIndices:TVkUInt32List=nil;
                          const pMemoryProperties:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
                          const pOwnSingleMemoryChunk:boolean=false);
       destructor Destroy; override;
       procedure Bind;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkBuffer read fBufferHandle;
       property Size:TVkDeviceSize read fSize;
       property Memory:TVulkanDeviceMemoryBlock read fMemoryBlock;
     end;

     TVulkanEvent=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fEventHandle:TVkEvent;
       fEventCreateInfo:TVkEventCreateInfo;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pFlags:TVkEventCreateFlags=TVkEventCreateFlags(0));
       destructor Destroy; override;
       function GetStatus:TVkResult;
       function SetEvent:TVkResult;
       function Reset:TVkResult;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkEvent read fEventHandle;
     end;

     TVulkanFence=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fFenceHandle:TVkFence;
       fFenceCreateInfo:TVkFenceCreateInfo;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pFlags:TVkFenceCreateFlags=TVkFenceCreateFlags(0));
       destructor Destroy; override;
       function GetStatus:TVkResult;
       function Reset:TVkResult; overload;
       class function Reset(const pFences:array of TVulkanFence):TVkResult; overload;
       function WaitFor(const pTimeOut:TVkUInt64=TVKUInt64(TVKInt64(-1))):TVkResult; overload;
       class function WaitFor(const pFences:array of TVulkanFence;const pWaitAll:boolean=true;const pTimeOut:TVkUInt64=TVKUInt64(TVKInt64(-1))):TVkResult; overload;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkFence read fFenceHandle;
     end;

     TVulkanSemaphore=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fSemaphoreHandle:TVkSemaphore;
       fSemaphoreCreateInfo:TVkSemaphoreCreateInfo;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pFlags:TVkSemaphoreCreateFlags=TVkSemaphoreCreateFlags(0));
       destructor Destroy; override;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkSemaphore read fSemaphoreHandle;
     end;

     TVulkanQueue=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fQueueHandle:TVkQueue;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pQueue:TVkQueue);
       destructor Destroy; override;
       procedure Submit(const pSubmitCount:TVkUInt32;const pSubmits:PVkSubmitInfo;const pFence:TVulkanFence);
       procedure BindSparse(const pBindInfoCount:TVkUInt32;const pBindInfo:PVkBindSparseInfo;const pFence:TVulkanFence);
       procedure WaitIdle;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkQueue read fQueueHandle;
     end;

     TVulkanCommandPool=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fQueueFamilyIndex:TVkUInt32;
       fFlags:TVkCommandPoolCreateFlags;
       fCommandPoolHandle:TVkCommandPool;
       fCommandPoolCreateInfo:TVkCommandPoolCreateInfo;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pQueueFamilyIndex:TVkUInt32;
                          const pFlags:TVkCommandPoolCreateFlags=TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
       destructor Destroy; override;
       property Device:TVulkanDevice read fDevice;
       property QueueFamilyIndex:TVkUInt32 read fQueueFamilyIndex;
       property Handle:TVkCommandPool read fCommandPoolHandle;
     end;

     TVulkanCommandBuffer=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fCommandPool:TVulkanCommandPool;
       fLevel:TVkCommandBufferLevel;
       fCommandBufferHandle:TVkCommandBuffer;
//     fFence:TVulkanFence;
      public
       constructor Create(const pCommandPool:TVulkanCommandPool;
                          const pLevel:TVkCommandBufferLevel;
                          const pCommandBufferHandle:TVkCommandBuffer); reintroduce; overload;
       constructor Create(const pCommandPool:TVulkanCommandPool;
                          const pLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY); reintroduce; overload;
       destructor Destroy; override;
       class function Allocate(const pCommandPool:TVulkanCommandPool;
                               const pLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY;
                               const pCommandBufferCount:TVkUInt32=1):TVulkanObjectList;
       procedure BeginRecording(const pFlags:TVkCommandBufferUsageFlags=0;const pInheritanceInfo:PVkCommandBufferInheritanceInfo=nil);
       procedure BeginRecordingPrimary;
       procedure BeginRecordingSecondary(const pRenderPass:TVkRenderPass;const pSubPass:TVkUInt32;const pFrameBuffer:TVkFramebuffer;const pOcclusionQueryEnable:boolean;const pQueryFlags:TVkQueryControlFlags;const pPipelineStatistics:TVkQueryPipelineStatisticFlags);
       procedure EndRecording;
       procedure Reset(const pFlags:TVkCommandBufferResetFlags=TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
       procedure CmdBindPipeline(pipelineBindPoint:TVkPipelineBindPoint;pipeline:TVkPipeline);
       procedure CmdSetViewport(firstViewport:TVkUInt32;viewportCount:TVkUInt32;const pViewports:PVkViewport);
       procedure CmdSetScissor(firstScissor:TVkUInt32;scissorCount:TVkUInt32;const pScissors:PVkRect2D);
       procedure CmdSetLineWidth(lineWidth:TVkFloat);
       procedure CmdSetDepthBias(depthBiasConstantFactor:TVkFloat;depthBiasClamp:TVkFloat;depthBiasSlopeFactor:TVkFloat);
       procedure CmdSetBlendConstants(const blendConstants:TVkFloat);
       procedure CmdSetDepthBounds(minDepthBounds:TVkFloat;maxDepthBounds:TVkFloat);
       procedure CmdSetStencilCompareMask(faceMask:TVkStencilFaceFlags;compareMask:TVkUInt32);
       procedure CmdSetStencilWriteMask(faceMask:TVkStencilFaceFlags;writeMask:TVkUInt32);
       procedure CmdSetStencilReference(faceMask:TVkStencilFaceFlags;reference:TVkUInt32);
       procedure CmdBindDescriptorSets(pipelineBindPoint:TVkPipelineBindPoint;layout:TVkPipelineLayout;firstSet:TVkUInt32;descriptorSetCount:TVkUInt32;const pDescriptorSets:PVkDescriptorSet;dynamicOffsetCount:TVkUInt32;const pDynamicOffsets:PVkUInt32);
       procedure CmdBindIndexBuffer(buffer:TVkBuffer;offset:TVkDeviceSize;indexType:TVkIndexType);
       procedure CmdBindVertexBuffers(firstBinding:TVkUInt32;bindingCount:TVkUInt32;const pBuffers:PVkBuffer;const pOffsets:PVkDeviceSize);
       procedure CmdDraw(vertexCount:TVkUInt32;instanceCount:TVkUInt32;firstVertex:TVkUInt32;firstInstance:TVkUInt32);
       procedure CmdDrawIndexed(indexCount:TVkUInt32;instanceCount:TVkUInt32;firstIndex:TVkUInt32;vertexOffset:TVkInt32;firstInstance:TVkUInt32);
       procedure CmdDrawIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TVkUInt32;stride:TVkUInt32);
       procedure CmdDrawIndexedIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TVkUInt32;stride:TVkUInt32);
       procedure CmdDispatch(x:TVkUInt32;y:TVkUInt32;z:TVkUInt32);
       procedure CmdDispatchIndirect(buffer:TVkBuffer;offset:TVkDeviceSize);
       procedure CmdCopyBuffer(srcBuffer:TVkBuffer;dstBuffer:TVkBuffer;regionCount:TVkUInt32;const pRegions:PVkBufferCopy);
       procedure CmdCopyImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageCopy);
       procedure CmdBlitImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageBlit;filter:TVkFilter);
       procedure CmdCopyBufferToImage(srcBuffer:TVkBuffer;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkBufferImageCopy);
       procedure CmdCopyImageToBuffer(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstBuffer:TVkBuffer;regionCount:TVkUInt32;const pRegions:PVkBufferImageCopy);
       procedure CmdUpdateBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;dataSize:TVkDeviceSize;const pData:PVkVoid);
       procedure CmdFillBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;size:TVkDeviceSize;data:TVkUInt32);
       procedure CmdClearColorImage(image:TVkImage;imageLayout:TVkImageLayout;const pColor:PVkClearColorValue;rangeCount:TVkUInt32;const pRanges:PVkImageSubresourceRange);
       procedure CmdClearDepthStencilImage(image:TVkImage;imageLayout:TVkImageLayout;const pDepthStencil:PVkClearDepthStencilValue;rangeCount:TVkUInt32;const pRanges:PVkImageSubresourceRange);
       procedure CmdClearAttachments(attachmentCount:TVkUInt32;const pAttachments:PVkClearAttachment;rectCount:TVkUInt32;const pRects:PVkClearRect);
       procedure CmdResolveImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageResolve);
       procedure CmdSetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
       procedure CmdResetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
       procedure CmdWaitEvents(eventCount:TVkUInt32;const pEvents:PVkEvent;srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;memoryBarrierCount:TVkUInt32;const pMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TVkUInt32;const pBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TVkUInt32;const pImageMemoryBarriers:PVkImageMemoryBarrier);
       procedure CmdPipelineBarrier(srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;dependencyFlags:TVkDependencyFlags;memoryBarrierCount:TVkUInt32;const pMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TVkUInt32;const pBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TVkUInt32;const pImageMemoryBarriers:PVkImageMemoryBarrier);
       procedure CmdBeginQuery(queryPool:TVkQueryPool;query:TVkUInt32;flags:TVkQueryControlFlags);
       procedure CmdEndQuery(queryPool:TVkQueryPool;query:TVkUInt32);
       procedure CmdResetQueryPool(queryPool:TVkQueryPool;firstQuery:TVkUInt32;queryCount:TVkUInt32);
       procedure CmdWriteTimestamp(pipelineStage:TVkPipelineStageFlagBits;queryPool:TVkQueryPool;query:TVkUInt32);
       procedure CmdCopyQueryPoolResults(queryPool:TVkQueryPool;firstQuery:TVkUInt32;queryCount:TVkUInt32;dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;stride:TVkDeviceSize;flags:TVkQueryResultFlags);
       procedure CmdPushConstants(layout:TVkPipelineLayout;stageFlags:TVkShaderStageFlags;offset:TVkUInt32;size:TVkUInt32;const pValues:PVkVoid);
       procedure CmdBeginRenderPass(const pRenderPassBegin:PVkRenderPassBeginInfo;contents:TVkSubpassContents);
       procedure CmdNextSubpass(contents:TVkSubpassContents);
       procedure CmdEndRenderPass;
       procedure CmdExecuteCommands(commandBufferCount:TVkUInt32;const pCommandBuffers:PVkCommandBuffer);
       procedure CmdExecute(const pCommandBuffer:TVulkanCommandBuffer);
       procedure MetaCmdPresentImageBarrier(const pImage:TVkImage);
       procedure Execute(const pQueue:TVulkanQueue;const pFence:TVulkanFence;const pFlags:TVkPipelineStageFlags;const pWaitSemaphore:TVulkanSemaphore=nil;const pSignalSemaphore:TVulkanSemaphore=nil);
       property Device:TVulkanDevice read fDevice;
       property CommandPool:TVulkanCommandPool read fCommandPool;
       property Level:TVkCommandBufferLevel read fLevel;
       property Handle:TVkCommandBuffer read fCommandBufferHandle;
     end;

     TVulkanRenderPassAttachmentDescriptions=array of TVkAttachmentDescription;

     TVulkanRenderPassAttachmentReferences=array of TVkAttachmentReference;

     PVulkanRenderPassSubpassDescription=^TVulkanRenderPassSubpassDescription;
     TVulkanRenderPassSubpassDescription=record
      Flags:TVkSubpassDescriptionFlags;
      PipelineBindPoint:TVkPipelineBindPoint;
      InputAttachments:array of TVkInt32;
      ColorAttachments:array of TVkInt32;
      ResolveAttachments:array of TVkInt32;
      DepthStencilAttachment:TVkInt32;
      PreserveAttachments:array of TVkUInt32;
      pInputAttachments:TVulkanRenderPassAttachmentReferences;
      pColorAttachments:TVulkanRenderPassAttachmentReferences;
      pResolveAttachments:TVulkanRenderPassAttachmentReferences;
     end;

     TVulkanRenderPassSubpassDescriptions=array of TVulkanRenderPassSubpassDescription;

     TVulkanRenderPass=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fRenderPassHandle:TVkRenderPass;
       fRenderPassCreateInfo:TVkRenderPassCreateInfo;
       fAttachmentDescriptions:TVulkanRenderPassAttachmentDescriptions;
       fCountAttachmentDescriptions:TVkInt32;
       fAttachmentReferences:TVulkanRenderPassAttachmentReferences;
       fCountAttachmentReferences:TVkInt32;
       fRenderPassSubpassDescriptions:TVulkanRenderPassSubpassDescriptions;
       fSubpassDescriptions:TVkSubpassDescriptionArray;
       fCountSubpassDescriptions:TVkInt32;
       fSubpassDependencies:TVkSubpassDependencyArray;
       fCountSubpassDependencies:TVkInt32;
       fClearValues:TVkClearValueArray;
       function GetClearValue(const Index:TVkUInt32):PVkClearValue;
      public
       constructor Create(const pDevice:TVulkanDevice);
       destructor Destroy; override;
       function AddAttachmentDescription(const pFlags:TVkAttachmentDescriptionFlags;
                                         const pFormat:TVkFormat;
                                         const pSamples:TVkSampleCountFlagBits;
                                         const pLoadOp:TVkAttachmentLoadOp;
                                         const pStoreOp:TVkAttachmentStoreOp;
                                         const pStencilLoadOp:TVkAttachmentLoadOp;
                                         const pStencilStoreOp:TVkAttachmentStoreOp;
                                         const pInitialLayout:TVkImageLayout;
                                         const pFinalLayout:TVkImageLayout):TVkUInt32;
       function AddAttachmentReference(const pAttachment:TVkUInt32;
                                       const pLayout:TVkImageLayout):TVkUInt32;
       function AddSubpassDescription(const pFlags:TVkSubpassDescriptionFlags;
                                      const pPipelineBindPoint:TVkPipelineBindPoint;
                                      const pInputAttachments:array of TVkInt32;
                                      const pColorAttachments:array of TVkInt32;
                                      const pResolveAttachments:array of TVkInt32;
                                      const pDepthStencilAttachment:TVkInt32;
                                      const pPreserveAttachments:array of TVkUInt32):TVkUInt32;
       function AddSubpassDependency(const pSrcSubpass:TVkUInt32;
                                     const pDstSubpass:TVkUInt32;
                                     const pSrcStageMask:TVkPipelineStageFlags;
                                     const pDstStageMask:TVkPipelineStageFlags;
                                     const pSrcAccessMask:TVkAccessFlags;
                                     const pDstAccessMask:TVkAccessFlags;
                                     const pDependencyFlags:TVkDependencyFlags):TVkUInt32;
       procedure Initialize;
       procedure BeginRenderpass(const pCommandBuffer:TVulkanCommandBuffer;
                                 const pFrameBuffer:TVkFrameBuffer;
                                 const pSubpassContents:TVkSubpassContents;
                                 const pOffsetX,pOffsetY,pWidth,pHeight:TVkUInt32);
       procedure EndRenderpass(const pCommandBuffer:TVulkanCommandBuffer);
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkRenderPass read fRenderPassHandle;
       property ClearValues[const Index:TVkUInt32]:PVkClearValue read GetClearValue;
     end;

     PVulkanSwapChainBuffer=^TVulkanSwapChainBuffer;
     TVulkanSwapChainBuffer=record
      Image:TVkImage;
      ImageView:TVkImageView;
     end;

     TVulkanSwapChainBuffers=array of TVulkanSwapChainBuffer;

     TVulkanSwapChainFrameBuffers=array of TVkFrameBuffer;

     TVulkanSwapChain=class(TVulkanHandle)
      private
       fDevice:TVulkanDevice;
       fSwapChainHandle:TVkSwapChainKHR;
       fSwapChainCreateInfo:TVkSwapchainCreateInfoKHR;
       fQueueFamilyIndices:TVulkanQueueFamilyIndices;
       fCountQueueFamilyIndices:TVkInt32;
       fDepthImage:TVkImage;
       fDepthImageFormat:TVkFormat;
       fDepthImageView:TVkImageView;
       fDepthMemoryBlock:TVulkanDeviceMemoryBlock;
       fSwapChainBuffers:TVulkanSwapChainBuffers;
       fFrameBuffers:TVulkanSwapChainFrameBuffers;
       fCurrentBuffer:TVkUInt32;
       fRenderPass:TVulkanRenderPass;
       fWidth:TVkInt32;
       fHeight:TVkInt32;
       function GetCurrentImage:TVkImage;
       function GetCurrentFrameBuffer:TVkFrameBuffer;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pCommandBuffer:TVulkanCommandBuffer;
                          const pCommandBufferFence:TVulkanFence;
                          const pOldSwapChain:TVulkanSwapChain=nil;
                          const pDesiredImageWidth:TVkUInt32=0;
                          const pDesiredImageHeight:TVkUInt32=0;
                          const pDesiredImageCount:TVkUInt32=2;
                          const pImageArrayLayers:TVkUInt32=1;
                          const pImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                          const pImageColorSpace:TVkColorSpaceKHR=VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
                          const pImageUsage:TVkImageUsageFlags=TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
                          const pImageSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                          const pDepthImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                          const pDepthImageFormatWithStencil:boolean=false;
                          const pQueueFamilyIndices:TVkUInt32List=nil;
                          const pCompositeAlpha:TVkCompositeAlphaFlagBitsKHR=VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
                          const pPresentMode:TVkPresentModeKHR=VK_PRESENT_MODE_MAILBOX_KHR;
                          const pClipped:boolean=true;
                          const pDesiredTransform:TVkSurfaceTransformFlagsKHR=TVkSurfaceTransformFlagsKHR($ffffffff));
       destructor Destroy; override;
       procedure QueuePresent(const pQueue:TVulkanQueue;const pSemaphore:TVulkanSemaphore=nil);
       function AcquireNextImage(const pSemaphore:TVulkanSemaphore=nil;const pFence:TVulkanFence=nil;const pTimeOut:TVkUInt64=TVkUInt64(high(TVkUInt64))):TVkResult;
       property Device:TVulkanDevice read fDevice;
       property Handle:TVkSwapChainKHR read fSwapChainHandle;
       property CurrentBuffer:TVkUInt32 read fCurrentBuffer;
       property RenderPass:TVulkanRenderPass read fRenderPass;
       property CurrentImage:TVkImage read GetCurrentImage;
       property CurrentFrameBuffer:TVkFrameBuffer read GetCurrentFrameBuffer;
       property Width:TVkInt32 read fWidth;
       property Height:TVkInt32 read fHeight;
     end;

     TVulkanFrameBufferAttachment=class(TVulkanObject)
      private
       fDevice:TVulkanDevice;
       fWidth:TVkInt32;
       fHeight:TVkInt32;
       fFormat:TVkFormat;
       fImage:TVkImage;
       fImageView:TVkImageView;
       fMemoryBlock:TVulkanDeviceMemoryBlock;
      public
       constructor Create(const pDevice:TVulkanDevice;
                          const pCommandBuffer:TVulkanCommandBuffer;
                          const pCommandBufferFence:TVulkanFence;
                          const pWidth:TVkUInt32;
                          const pHeight:TVkUInt32;
                          const pFormat:TVkFormat;
                          const pUsage:TVkBufferUsageFlags);
       destructor Destroy; override;
       property Device:TVulkanDevice read fDevice;
       property Width:TVkInt32 read fWidth;
       property Height:TVkInt32 read fHeight;
       property Format:TVkFormat read fFormat;
       property Image:TVkImage read fImage;
       property ImageView:TVkImageView read fImageView;
       property Memory:TVulkanDeviceMemoryBlock read fMemoryBlock;
     end;

function VulkanRoundUpToPowerOfTwo(Value:TVkSize):TVkSize;

function VulkanErrorToString(const ErrorCode:TVkResult):TVulkanCharString;

function StringListToVulkanCharStringArray(const StringList:TStringList):TVulkanCharStringArray;

procedure VulkanSetImageLayout(const pImage:TVkImage;
                               const pAspectMask:TVkImageAspectFlags;
                               const pOldImageLayout:TVkImageLayout;
                               const pNewImageLayout:TVkImageLayout;
                               const pRange:PVkImageSubresourceRange;
                               const pCommandBuffer:TVulkanCommandBuffer;
                               const pDevice:TVulkanDevice;
                               const pQueue:TVulkanQueue;
                               const pFence:TVulkanFence;
                               const pBeginAndExecuteCommandBuffer:boolean);

implementation

function VulkanRoundUpToPowerOfTwo(Value:TVkSize):TVkSize;
begin
 dec(Value);
 Value:=Value or (Value shr 1);
 Value:=Value or (Value shr 2);
 Value:=Value or (Value shr 4);
 Value:=Value or (Value shr 8);
 Value:=Value or (Value shr 16);
{$ifdef CPU64}
 Value:=Value or (Value shr 32);
{$endif}
 result:=Value+1;
end;

function VulkanDeviceSizeRoundUpToPowerOfTwo(Value:TVkDeviceSize):TVkDeviceSize;
begin
 dec(Value);
 Value:=Value or (Value shr 1);
 Value:=Value or (Value shr 2);
 Value:=Value or (Value shr 4);
 Value:=Value or (Value shr 8);
 Value:=Value or (Value shr 16);
 Value:=Value or (Value shr 32);
 result:=Value+1;
end;

{$if defined(fpc)}
function CTZDWord(Value:TVkUInt32):TVkUInt8; inline;
begin
 if Value=0 then begin
  result:=32;
 end else begin
  result:=BSFDWord(Value);
 end;
end;
{$elseif defined(cpu386)}
{$ifndef fpc}
function CTZDWord(Value:TVkUInt32):TVkUInt8; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 bsf eax,eax
 jnz @Done
 mov eax,32
@Done:
end;
{$endif}
{$elseif defined(cpux86_64)}
{$ifndef fpc}
function CTZDWord(Value:TVkUInt32):TVkUInt8; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
{$ifndef fpc}
 .NOFRAME
{$endif}
{$ifdef Windows}
 bsf eax,ecx
{$else}
 bsf eax,edi
{$endif}
 jnz @Done
 mov eax,32
@Done:
end;
{$endif}
{$elseif not defined(fpc)}
function CTZDWord(Value:TVkUInt32):TVkUInt8;
const CTZDebruijn32Multiplicator=TVkUInt32($077cb531);
      CTZDebruijn32Shift=27;
      CTZDebruijn32Mask=31;
      CTZDebruijn32Table:array[0..31] of TVkUInt8=(0,1,28,2,29,14,24,3,30,22,20,15,25,17,4,8,31,27,13,23,21,19,16,7,26,12,18,6,11,5,10,9);
begin
 if Value=0 then begin
  result:=32;
 end else begin
  result:=CTZDebruijn32Table[((TVkUInt32(Value and (-Value))*CTZDebruijn32Multiplicator) shr CTZDebruijn32Shift) and CTZDebruijn32Mask];
 end;
end;
{$ifend}

function VulkanErrorToString(const ErrorCode:TVkResult):TVulkanCharString;
begin
 case ErrorCode of
  VK_SUCCESS:begin
   result:='VK_SUCCESS';
  end;
  VK_NOT_READY:begin
   result:='VK_NOT_READY';
  end;
  VK_TIMEOUT:begin
   result:='VK_TIMEOUT';
  end;
  VK_EVENT_SET:begin
   result:='VK_EVENT_SET';
  end;
  VK_EVENT_RESET:begin
   result:='VK_EVENT_RESET';
  end;
  VK_INCOMPLETE:begin
   result:='VK_INCOMPLETE';
  end;
  VK_ERROR_OUT_OF_HOST_MEMORY:begin
   result:='VK_ERROR_OUT_OF_HOST_MEMORY';
  end;
  VK_ERROR_OUT_OF_DEVICE_MEMORY:begin
   result:='VK_ERROR_OUT_OF_DEVICE_MEMORY';
  end;
  VK_ERROR_INITIALIZATION_FAILED:begin
   result:='VK_ERROR_INITIALIZATION_FAILED';
  end;
  VK_ERROR_DEVICE_LOST:begin
   result:='VK_ERROR_DEVICE_LOST';
  end;
  VK_ERROR_MEMORY_MAP_FAILED:begin
   result:='VK_ERROR_MEMORY_MAP_FAILED';
  end;
  VK_ERROR_LAYER_NOT_PRESENT:begin
   result:='VK_ERROR_LAYER_NOT_PRESENT';
  end;
  VK_ERROR_EXTENSION_NOT_PRESENT:begin
   result:='VK_ERROR_EXTENSION_NOT_PRESENT';
  end;
  VK_ERROR_FEATURE_NOT_PRESENT:begin
   result:='VK_ERROR_FEATURE_NOT_PRESENT';
  end;
  VK_ERROR_INCOMPATIBLE_DRIVER:begin
   result:='VK_ERROR_INCOMPATIBLE_DRIVER';
  end;
  VK_ERROR_TOO_MANY_OBJECTS:begin
   result:='VK_ERROR_TOO_MANY_OBJECTS';
  end;
  VK_ERROR_FORMAT_NOT_SUPPORTED:begin
   result:='VK_ERROR_FORMAT_NOT_SUPPORTED';
  end;
  VK_ERROR_SURFACE_LOST_KHR:begin
   result:='VK_ERROR_SURFACE_LOST_KHR';
  end;
  VK_ERROR_NATIVE_WINDOW_IN_USE_KHR:begin
   result:='VK_ERROR_NATIVE_WINDOW_IN_USE_KHR';
  end;
  VK_SUBOPTIMAL_KHR:begin
   result:='VK_SUBOPTIMAL_KHR';
  end;
  VK_ERROR_OUT_OF_DATE_KHR:begin
   result:='VK_ERROR_OUT_OF_DATE_KHR';
  end;
  VK_ERROR_INCOMPATIBLE_DISPLAY_KHR:begin
   result:='VK_ERROR_INCOMPATIBLE_DISPLAY_KHR';
  end;
  VK_ERROR_VALIDATION_FAILED_EXT:begin
   result:='VK_ERROR_VALIDATION_FAILED_EXT';
  end;
  VK_ERROR_INVALID_SHADER_NV:begin
   result:='VK_ERROR_INVALID_SHADER_NV';
  end;
  else begin
   result:='Unknown error code detected ('+IntToStr(longint(ErrorCode))+')';
  end;
 end;
end;

function StringListToVulkanCharStringArray(const StringList:TStringList):TVulkanCharStringArray;
var i:TVkInt32;
begin
 result:=nil;
 SetLength(result,StringList.Count);
 for i:=0 to StringList.Count-1 do begin
  result[i]:=StringList.Strings[i];
 end;
end;

procedure HandleResultCode(const ResultCode:TVkResult);
begin
 if ResultCode<>VK_SUCCESS then begin
  raise EVulkanResultException.Create(ResultCode);
 end;
end;

procedure VulkanSetImageLayout(const pImage:TVkImage;
                               const pAspectMask:TVkImageAspectFlags;
                               const pOldImageLayout:TVkImageLayout;
                               const pNewImageLayout:TVkImageLayout;
                               const pRange:PVkImageSubresourceRange;
                               const pCommandBuffer:TVulkanCommandBuffer;
                               const pDevice:TVulkanDevice;
                               const pQueue:TVulkanQueue;
                               const pFence:TVulkanFence;
                               const pBeginAndExecuteCommandBuffer:boolean);
var ImageMemoryBarrier:TVkImageMemoryBarrier;
    SrcStages,DestStages:TVkPipelineStageFlags;
begin
 if pBeginAndExecuteCommandBuffer then begin
  pCommandBuffer.BeginRecording;
 end;

 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.oldLayout:=pOldImageLayout;
 ImageMemoryBarrier.newLayout:=pNewImageLayout;
 ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.image:=pImage;

 if assigned(pRange) then begin
  ImageMemoryBarrier.subresourceRange:=pRange^;
 end else begin
  ImageMemoryBarrier.subresourceRange.aspectMask:=pAspectMask;
  ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
  ImageMemoryBarrier.subresourceRange.levelCount:=1;
  ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
  ImageMemoryBarrier.subresourceRange.layerCount:=1;
 end;

 case pOldImageLayout of
  VK_IMAGE_LAYOUT_UNDEFINED:begin
   ImageMemoryBarrier.srcAccessMask:=0;
  end;
  VK_IMAGE_LAYOUT_GENERAL:begin
  end;
	VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
  end;
	VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL:begin
  end;
  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
  end;
 	VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
  end;
	VK_IMAGE_LAYOUT_PREINITIALIZED:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_HOST_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_PRESENT_SRC_KHR:begin
  end;
 end;

 case pNewImageLayout of
  VK_IMAGE_LAYOUT_UNDEFINED:begin
  end;
  VK_IMAGE_LAYOUT_GENERAL:begin
  end;
 	VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
  end;
	VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=ImageMemoryBarrier.dstAccessMask or TVkAccessFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL:begin
  end;
  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
  end;
	VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=ImageMemoryBarrier.srcAccessMask or TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
  end;
	VK_IMAGE_LAYOUT_PREINITIALIZED:begin
  end;
	VK_IMAGE_LAYOUT_PRESENT_SRC_KHR:begin
  end;
 end;

 SrcStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
 DestStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);

 pCommandBuffer.CmdPipelineBarrier(SrcStages,DestStages,0,0,nil,0,nil,1,@ImageMemoryBarrier);

 if pBeginAndExecuteCommandBuffer then begin
  pCommandBuffer.EndRecording;
  pCommandBuffer.Execute(pQueue,pFence,TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT));
 end;
 
end;

constructor EVulkanResultException.Create(const pResultCode:TVkResult);
begin
 fResultCode:=pResultCode;
 inherited Create(VulkanErrorToString(fResultCode));
end;

destructor EVulkanResultException.Destroy;
begin
 inherited Destroy;
end;

constructor TVulkanBaseList.Create(const pItemSize:TVkSizeInt);
begin
 inherited Create;
 fItemSize:=pItemSize;
 fCount:=0;
 fAllocated:=0;
 fMemory:=nil;
end;

destructor TVulkanBaseList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TVulkanBaseList.SetCount(const NewCount:TVkSizeInt);
var Index,NewAllocated:TVkSizeInt;
    Item:pointer;
begin
 if fCount<NewCount then begin
  NewAllocated:=TVkSizeInt(VulkanRoundUpToPowerOfTwo(NewCount));
  if fAllocated<NewAllocated then begin
   if assigned(fMemory) then begin
    ReallocMem(fMemory,NewAllocated*fItemSize);
   end else begin
    GetMem(fMemory,NewAllocated*fItemSize);
   end;
   FillChar(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(fAllocated)*TVkPtrUInt(fItemSize))))^,(NewAllocated-fAllocated)*fItemSize,#0);
   fAllocated:=NewAllocated;
  end;
  Item:=fMemory;
  Index:=fCount;
  inc(TVkPtrUInt(Item),Index*fItemSize);
  while Index<NewCount do begin
   FillChar(Item^,fItemSize,#0);
   InitializeItem(Item^);
   inc(TVkPtrUInt(Item),fItemSize);
   inc(Index);
  end;
  fCount:=NewCount;
 end else if fCount>NewCount then begin
  Item:=fMemory;
  Index:=NewCount;
  inc(TVkPtrUInt(Item),Index*fItemSize);
  while Index<fCount do begin
   FinalizeItem(Item^);
   FillChar(Item^,fItemSize,#0);
   inc(TVkPtrUInt(Item),fItemSize);
   inc(Index);
  end;
  fCount:=NewCount;
  if NewCount<(fAllocated shr 2) then begin
   if NewCount=0 then begin
    if assigned(fMemory) then begin
     FreeMem(fMemory);
     fMemory:=nil;
    end;
    fAllocated:=0;
   end else begin                             
    NewAllocated:=fAllocated shr 1;
    if assigned(fMemory) then begin
     ReallocMem(fMemory,NewAllocated*fItemSize);
    end else begin
     GetMem(fMemory,NewAllocated*fItemSize);
    end;
    fAllocated:=NewAllocated;
   end;
  end;
 end;
end;

function TVulkanBaseList.GetItem(const Index:TVkSizeInt):pointer;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))));
 end else begin
  result:=nil;
 end;
end;

procedure TVulkanBaseList.InitializeItem(var Item);
begin
end;

procedure TVulkanBaseList.FinalizeItem(var Item);
begin
end;

procedure TVulkanBaseList.CopyItem(const Source;var Destination);
begin
 Move(Source,Destination,fItemSize);
end;

procedure TVulkanBaseList.ExchangeItem(var Source,Destination);
var a,b:PVkUInt8;
    c8:TVkUInt8;
    c32:TVkUInt32;
    Index:TVkInt32;
begin
 a:=@Source;
 b:=@Destination;
 for Index:=1 to fItemSize shr 2 do begin
  c32:=PVkUInt32(a)^;
  PVkUInt32(a)^:=PVkUInt32(b)^;
  PVkUInt32(b)^:=c32;
  inc(PVkUInt32(a));
  inc(PVkUInt32(b));
 end;
 for Index:=1 to fItemSize and 3 do begin
  c8:=a^;
  a^:=b^;
  b^:=c8;
  inc(a);
  inc(b);
 end;
end;

function TVulkanBaseList.CompareItem(const Source,Destination):longint;
var a,b:PVkUInt8;
    Index:TVkInt32;
begin
 result:=0;
 a:=@Source;
 b:=@Destination;
 for Index:=1 to fItemSize do begin
  result:=a^-b^;
  if result<>0 then begin
   exit;
  end;
  inc(a);
  inc(b);
 end;
end;

procedure TVulkanBaseList.Clear;
var Index:TVkSizeInt;
    Item:pointer;
begin
 Item:=fMemory;
 Index:=0;
 while Index<fCount do begin
  FinalizeItem(Item^);
  inc(TVkPtrInt(Item),fItemSize);
  inc(Index);
 end;
 if assigned(fMemory) then begin
  FreeMem(fMemory);
  fMemory:=nil;
 end;
 fCount:=0;
 fAllocated:=0;
end;

procedure TVulkanBaseList.FillWith(const SourceData;const SourceCount:TVkSizeInt);
var Index:TVkSizeInt;
    SourceItem,Item:pointer;
begin
 SourceItem:=@SourceData;
 if assigned(SourceItem) and (SourceCount>0) then begin
  SetCount(SourceCount);
  Item:=fMemory;
  Index:=0;
  while Index<fCount do begin
   CopyItem(SourceItem^,Item^);
   inc(TVkPtrInt(SourceItem),fItemSize);
   inc(TVkPtrInt(Item),fItemSize);
   inc(Index);
  end;
 end else begin
  SetCount(0);
 end;
end;

function TVulkanBaseList.Add(const Item):TVkSizeInt;
begin
 result:=fCount;
 SetCount(result+1);
 CopyItem(Item,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(result)*TVkPtrUInt(fItemSize))))^);
end;

function TVulkanBaseList.Find(const Item):TVkSizeInt;
var Index:TVkSizeInt;
begin
 result:=-1;
 Index:=0;
 while Index<fCount do begin
  if CompareItem(Item,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^)=0 then begin
   result:=Index;
   break;
  end;
  inc(Index);
 end;
end;

procedure TVulkanBaseList.Insert(const Index:TVkSizeInt;const Item);
begin
 if Index>=0 then begin
  if Index<fCount then begin
   SetCount(fCount+1);
   Move(pointer(TVkPtrInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index+1)*TVkPtrUInt(fItemSize))))^,(fCount-Index)*fItemSize);
   FillChar(pointer(TVkPtrInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^,fItemSize,#0);
  end else begin
   SetCount(Index+1);
  end;
  CopyItem(Item,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end;
end;

procedure TVulkanBaseList.Delete(const Index:TVkSizeInt);
begin
 if (Index>=0) and (Index<fCount) then begin
  FinalizeItem(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
  Move(pointer(TVkPtrUInt(TVkPtruInt(fMemory)+(TVkPtrUInt(Index+1)*TVkPtrUInt(fItemSize))))^,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^,(fCount-Index)*fItemSize);
  FillChar(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(fCount-1)*TVkPtrUInt(fItemSize))))^,fItemSize,#0);
  SetCount(fCount-1);
 end;
end;

procedure TVulkanBaseList.Remove(const Item);
var Index:TVkSizeInt;
begin
 repeat
  Index:=Find(Item);
  if Index>=0 then begin
   Delete(Index);
  end else begin
   break;
  end;
 until false;
end;

procedure TVulkanBaseList.Exchange(const Index,WithIndex:TVkSizeInt);
begin
 if (Index>=0) and (Index<fCount) and (WithIndex>=0) and (WithIndex<fCount) then begin
  ExchangeItem(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^,pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(WithIndex)*TVkPtrUInt(fItemSize))))^);
 end;
end;

constructor TVulkanObjectList.Create;
begin
 fOwnObjects:=true;
 inherited Create(SizeOf(TVulkanObject));
end;

destructor TVulkanObjectList.Destroy;
begin
 inherited Destroy;
end;

procedure TVulkanObjectList.Clear;
begin
 inherited Clear;
end;

function TVulkanObjectList.GetItem(const Index:TVkSizeInt):TVulkanObject;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVulkanObject(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=nil;
 end;
end;

procedure TVulkanObjectList.SetItem(const Index:TVkSizeInt;const Item:TVulkanObject);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVulkanObject(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVulkanObjectList.InitializeItem(var Item);
begin
 TVulkanObject(pointer(Item)):=nil;
end;

procedure TVulkanObjectList.FinalizeItem(var Item);
begin
 if fOwnObjects then begin
  TVulkanObject(pointer(Item)).Free;
 end;
 TVulkanObject(pointer(Item)):=nil;
end;

procedure TVulkanObjectList.CopyItem(const Source;var Destination);
begin
 TVulkanObject(pointer(Destination)):=TVulkanObject(pointer(Source));
end;

procedure TVulkanObjectList.ExchangeItem(var Source,Destination);
var Temporary:TVulkanObject;
begin
 Temporary:=TVulkanObject(pointer(Source));
 TVulkanObject(pointer(Source)):=TVulkanObject(pointer(Destination));
 TVulkanObject(pointer(Destination)):=Temporary;
end;

function TVulkanObjectList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkPtrDiff(Source)-TVkPtrDiff(Destination);
end;

function TVulkanObjectList.Add(const Item:TVulkanObject):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVulkanObjectList.Find(const Item:TVulkanObject):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVulkanObjectList.Insert(const Index:TVkSizeInt;const Item:TVulkanObject);
begin
 inherited Insert(Index,Item);
end;

procedure TVulkanObjectList.Remove(const Item:TVulkanObject);
begin
 inherited Remove(Item);
end;

constructor TVkUInt32List.Create;
begin
 inherited Create(SizeOf(TVkUInt32));
end;

destructor TVkUInt32List.Destroy;
begin
 inherited Destroy;
end;

function TVkUInt32List.GetItem(const Index:TVkSizeInt):TVkUInt32;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkUInt32(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkUInt32List.SetItem(const Index:TVkSizeInt;const Item:TVkUInt32);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkUInt32(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkUInt32List.InitializeItem(var Item);
begin
 TVkUInt32(Item):=0;
end;

procedure TVkUInt32List.FinalizeItem(var Item);
begin
 TVkUInt32(Item):=0;
end;

procedure TVkUInt32List.CopyItem(const Source;var Destination);
begin
 TVkUInt32(Destination):=TVkUInt32(Source);
end;

procedure TVkUInt32List.ExchangeItem(var Source,Destination);
var Temporary:TVkUInt32;
begin
 Temporary:=TVkUInt32(Source);
 TVkUInt32(Source):=TVkUInt32(Destination);
 TVkUInt32(Destination):=Temporary;
end;

function TVkUInt32List.CompareItem(const Source,Destination):longint;
begin
 result:=TVkUInt32(Source)-TVkUInt32(Destination);
end;

function TVkUInt32List.Add(const Item:TVkUInt32):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkUInt32List.Find(const Item:TVkUInt32):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkUInt32List.Insert(const Index:TVkSizeInt;const Item:TVkUInt32);
begin
 inherited Insert(Index,Item);
end;

procedure TVkUInt32List.Remove(const Item:TVkUInt32);
begin
 inherited Remove(Item);
end;

constructor TVkFloatList.Create;
begin
 inherited Create(SizeOf(TVkFloat));
end;

destructor TVkFloatList.Destroy;
begin
 inherited Destroy;
end;

function TVkFloatList.GetItem(const Index:TVkSizeInt):TVkFloat;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkFloat(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkFloatList.SetItem(const Index:TVkSizeInt;const Item:TVkFloat);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkFloat(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkFloatList.InitializeItem(var Item);
begin
 TVkFloat(Item):=0;
end;

procedure TVkFloatList.FinalizeItem(var Item);
begin
 TVkFloat(Item):=0;
end;

procedure TVkFloatList.CopyItem(const Source;var Destination);
begin
 TVkFloat(Destination):=TVkFloat(Source);
end;

procedure TVkFloatList.ExchangeItem(var Source,Destination);
var Temporary:TVkFloat;
begin
 Temporary:=TVkFloat(Source);
 TVkFloat(Source):=TVkFloat(Destination);
 TVkFloat(Destination):=Temporary;
end;

function TVkFloatList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkInt32(Source)-TVkInt32(Destination);
end;

function TVkFloatList.Add(const Item:TVkFloat):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkFloatList.Find(const Item:TVkFloat):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkFloatList.Insert(const Index:TVkSizeInt;const Item:TVkFloat);
begin
 inherited Insert(Index,Item);
end;

procedure TVkFloatList.Remove(const Item:TVkFloat);
begin
 inherited Remove(Item);
end;

constructor TVkImageViewList.Create;
begin
 inherited Create(SizeOf(TVkImageView));
end;

destructor TVkImageViewList.Destroy;
begin
 inherited Destroy;
end;

function TVkImageViewList.GetItem(const Index:TVkSizeInt):TVkImageView;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkImageView(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkImageViewList.SetItem(const Index:TVkSizeInt;const Item:TVkImageView);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkImageView(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkImageViewList.InitializeItem(var Item);
begin
 TVkImageView(Item):=0;
end;

procedure TVkImageViewList.FinalizeItem(var Item);
begin
 TVkImageView(Item):=0;
end;

procedure TVkImageViewList.CopyItem(const Source;var Destination);
begin
 TVkImageView(Destination):=TVkImageView(Source);
end;

procedure TVkImageViewList.ExchangeItem(var Source,Destination);
var Temporary:TVkImageView;
begin
 Temporary:=TVkImageView(Source);
 TVkImageView(Source):=TVkImageView(Destination);
 TVkImageView(Destination):=Temporary;
end;

function TVkImageViewList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkImageView(Source)-TVkImageView(Destination);
end;

function TVkImageViewList.Add(const Item:TVkImageView):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkImageViewList.Find(const Item:TVkImageView):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkImageViewList.Insert(const Index:TVkSizeInt;const Item:TVkImageView);
begin
 inherited Insert(Index,Item);
end;

procedure TVkImageViewList.Remove(const Item:TVkImageView);
begin
 inherited Remove(Item);
end;

constructor TVkSamplerList.Create;
begin
 inherited Create(SizeOf(TVkSampler));
end;

destructor TVkSamplerList.Destroy;
begin
 inherited Destroy;
end;

function TVkSamplerList.GetItem(const Index:TVkSizeInt):TVkSampler;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkSampler(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkSamplerList.SetItem(const Index:TVkSizeInt;const Item:TVkSampler);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkSampler(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkSamplerList.InitializeItem(var Item);
begin
 TVkSampler(Item):=0;
end;

procedure TVkSamplerList.FinalizeItem(var Item);
begin
 TVkSampler(Item):=0;
end;

procedure TVkSamplerList.CopyItem(const Source;var Destination);
begin
 TVkSampler(Destination):=TVkSampler(Source);
end;

procedure TVkSamplerList.ExchangeItem(var Source,Destination);
var Temporary:TVkSampler;
begin
 Temporary:=TVkSampler(Source);
 TVkSampler(Source):=TVkSampler(Destination);
 TVkSampler(Destination):=Temporary;
end;

function TVkSamplerList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkSampler(Source)-TVkSampler(Destination);
end;

function TVkSamplerList.Add(const Item:TVkSampler):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkSamplerList.Find(const Item:TVkSampler):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkSamplerList.Insert(const Index:TVkSizeInt;const Item:TVkSampler);
begin
 inherited Insert(Index,Item);
end;

procedure TVkSamplerList.Remove(const Item:TVkSampler);
begin
 inherited Remove(Item);
end;

constructor TVkDescriptorSetLayoutList.Create;
begin
 inherited Create(SizeOf(TVkDescriptorSetLayout));
end;

destructor TVkDescriptorSetLayoutList.Destroy;
begin
 inherited Destroy;
end;

function TVkDescriptorSetLayoutList.GetItem(const Index:TVkSizeInt):TVkDescriptorSetLayout;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkDescriptorSetLayout(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkDescriptorSetLayoutList.SetItem(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkDescriptorSetLayout(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkDescriptorSetLayoutList.InitializeItem(var Item);
begin
 TVkDescriptorSetLayout(Item):=0;
end;

procedure TVkDescriptorSetLayoutList.FinalizeItem(var Item);
begin
 TVkDescriptorSetLayout(Item):=0;
end;

procedure TVkDescriptorSetLayoutList.CopyItem(const Source;var Destination);
begin
 TVkDescriptorSetLayout(Destination):=TVkDescriptorSetLayout(Source);
end;

procedure TVkDescriptorSetLayoutList.ExchangeItem(var Source,Destination);
var Temporary:TVkDescriptorSetLayout;
begin
 Temporary:=TVkDescriptorSetLayout(Source);
 TVkDescriptorSetLayout(Source):=TVkDescriptorSetLayout(Destination);
 TVkDescriptorSetLayout(Destination):=Temporary;
end;

function TVkDescriptorSetLayoutList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkDescriptorSetLayout(Source)-TVkDescriptorSetLayout(Destination);
end;

function TVkDescriptorSetLayoutList.Add(const Item:TVkDescriptorSetLayout):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkDescriptorSetLayoutList.Find(const Item:TVkDescriptorSetLayout):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkDescriptorSetLayoutList.Insert(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
begin
 inherited Insert(Index,Item);
end;

procedure TVkDescriptorSetLayoutList.Remove(const Item:TVkDescriptorSetLayout);
begin
 inherited Remove(Item);
end;

constructor TVkSampleMaskList.Create;
begin
 inherited Create(SizeOf(TVkSampleMask));
end;

destructor TVkSampleMaskList.Destroy;
begin
 inherited Destroy;
end;

function TVkSampleMaskList.GetItem(const Index:TVkSizeInt):TVkSampleMask;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkSampleMask(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkSampleMaskList.SetItem(const Index:TVkSizeInt;const Item:TVkSampleMask);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkSampleMask(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkSampleMaskList.InitializeItem(var Item);
begin
 TVkSampleMask(Item):=0;
end;

procedure TVkSampleMaskList.FinalizeItem(var Item);
begin
 TVkSampleMask(Item):=0;
end;

procedure TVkSampleMaskList.CopyItem(const Source;var Destination);
begin
 TVkSampleMask(Destination):=TVkSampleMask(Source);
end;

procedure TVkSampleMaskList.ExchangeItem(var Source,Destination);
var Temporary:TVkSampleMask;
begin
 Temporary:=TVkSampleMask(Source);
 TVkSampleMask(Source):=TVkSampleMask(Destination);
 TVkSampleMask(Destination):=Temporary;
end;

function TVkSampleMaskList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkSampleMask(Source)-TVkSampleMask(Destination);
end;

function TVkSampleMaskList.Add(const Item:TVkSampleMask):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkSampleMaskList.Find(const Item:TVkSampleMask):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkSampleMaskList.Insert(const Index:TVkSizeInt;const Item:TVkSampleMask);
begin
 inherited Insert(Index,Item);
end;

procedure TVkSampleMaskList.Remove(const Item:TVkSampleMask);
begin
 inherited Remove(Item);
end;

constructor TVkDynamicStateList.Create;
begin
 inherited Create(SizeOf(TVkDynamicState));
end;

destructor TVkDynamicStateList.Destroy;
begin
 inherited Destroy;
end;

function TVkDynamicStateList.GetItem(const Index:TVkSizeInt):TVkDynamicState;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkDynamicState(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=TVkDynamicState(0);
 end;
end;

procedure TVkDynamicStateList.SetItem(const Index:TVkSizeInt;const Item:TVkDynamicState);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkDynamicState(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkDynamicStateList.InitializeItem(var Item);
begin
 Initialize(TVkDynamicState(Item));
end;

procedure TVkDynamicStateList.FinalizeItem(var Item);
begin
 Finalize(TVkDynamicState(Item));
end;

procedure TVkDynamicStateList.CopyItem(const Source;var Destination);
begin
 TVkDynamicState(Destination):=TVkDynamicState(Source);
end;

procedure TVkDynamicStateList.ExchangeItem(var Source,Destination);
var Temporary:TVkDynamicState;
begin
 Temporary:=TVkDynamicState(Source);
 TVkDynamicState(Source):=TVkDynamicState(Destination);
 TVkDynamicState(Destination):=Temporary;
end;

function TVkDynamicStateList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkSize(TVkDynamicState(Source))-TVkSize(TVkDynamicState(Destination));
end;

function TVkDynamicStateList.Add(const Item:TVkDynamicState):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkDynamicStateList.Find(const Item:TVkDynamicState):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkDynamicStateList.Insert(const Index:TVkSizeInt;const Item:TVkDynamicState);
begin
 inherited Insert(Index,Item);
end;

procedure TVkDynamicStateList.Remove(const Item:TVkDynamicState);
begin
 inherited Remove(Item);
end;

constructor TVkBufferViewList.Create;
begin
 inherited Create(SizeOf(TVkBufferView));
end;

destructor TVkBufferViewList.Destroy;
begin
 inherited Destroy;
end;

function TVkBufferViewList.GetItem(const Index:TVkSizeInt):TVkBufferView;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkBufferView(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  result:=TVkBufferView(0);
 end;
end;

procedure TVkBufferViewList.SetItem(const Index:TVkSizeInt;const Item:TVkBufferView);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkBufferView(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkBufferViewList.InitializeItem(var Item);
begin
 Initialize(TVkBufferView(Item));
end;

procedure TVkBufferViewList.FinalizeItem(var Item);
begin
 Finalize(TVkBufferView(Item));
end;

procedure TVkBufferViewList.CopyItem(const Source;var Destination);
begin
 TVkBufferView(Destination):=TVkBufferView(Source);
end;

procedure TVkBufferViewList.ExchangeItem(var Source,Destination);
var Temporary:TVkBufferView;
begin
 Temporary:=TVkBufferView(Source);
 TVkBufferView(Source):=TVkBufferView(Destination);
 TVkBufferView(Destination):=Temporary;
end;

function TVkBufferViewList.CompareItem(const Source,Destination):longint;
begin
 result:=TVkSize(TVkBufferView(Source))-TVkSize(TVkBufferView(Destination));
end;

function TVkBufferViewList.Add(const Item:TVkBufferView):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkBufferViewList.Find(const Item:TVkBufferView):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkBufferViewList.Insert(const Index:TVkSizeInt;const Item:TVkBufferView);
begin
 inherited Insert(Index,Item);
end;

procedure TVkBufferViewList.Remove(const Item:TVkBufferView);
begin
 inherited Remove(Item);
end;

constructor TVkClearValueList.Create;
begin
 inherited Create(SizeOf(TVkClearValue));
end;

destructor TVkClearValueList.Destroy;
begin
 inherited Destroy;
end;

function TVkClearValueList.GetItem(const Index:TVkSizeInt):TVkClearValue;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkClearValue(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^);
 end else begin
  FillChar(result,SizeOf(TVkClearValue),#0);
 end;
end;

procedure TVkClearValueList.SetItem(const Index:TVkSizeInt;const Item:TVkClearValue);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkClearValue(pointer(TVkPtrUInt(TVkPtrUInt(fMemory)+(TVkPtrUInt(Index)*TVkPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkClearValueList.InitializeItem(var Item);
begin
 Initialize(TVkClearValue(Item));
end;

procedure TVkClearValueList.FinalizeItem(var Item);
begin
 Finalize(TVkClearValue(Item));
end;

procedure TVkClearValueList.CopyItem(const Source;var Destination);
begin
 TVkClearValue(Destination):=TVkClearValue(Source);
end;

procedure TVkClearValueList.ExchangeItem(var Source,Destination);
var Temporary:TVkClearValue;
begin
 Temporary:=TVkClearValue(Source);
 TVkClearValue(Source):=TVkClearValue(Destination);
 TVkClearValue(Destination):=Temporary;
end;

function TVkClearValueList.CompareItem(const Source,Destination):longint;
begin
 result:=inherited CompareItem(Source,Destination);
end;

function TVkClearValueList.Add(const Item:TVkClearValue):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkClearValueList.Find(const Item:TVkClearValue):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkClearValueList.Insert(const Index:TVkSizeInt;const Item:TVkClearValue);
begin
 inherited Insert(Index,Item);
end;

procedure TVkClearValueList.Remove(const Item:TVkClearValue);
begin
 inherited Remove(Item);
end;

constructor TVulkanHandle.Create;
begin
 inherited Create;
end;

destructor TVulkanHandle.Destroy;
begin
 inherited Destroy;
end;

function VulkanAllocationCallback(UserData:PVkVoid;Size:TVkSize;Alignment:TVkSize;Scope:TVkSystemAllocationScope):PVkVoid; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TVulkanAllocationManager(UserData).AllocationCallback(Size,Alignment,Scope);
end;

function VulkanReallocationCallback(UserData,Original:PVkVoid;Size:TVkSize;Alignment:TVkSize;Scope:TVkSystemAllocationScope):PVkVoid; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TVulkanAllocationManager(UserData).ReallocationCallback(Original,Size,Alignment,Scope);
end;

procedure VulkanFreeCallback(UserData,Memory:PVkVoid); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TVulkanAllocationManager(UserData).FreeCallback(Memory);
end;
                                         
procedure VulkanInternalAllocationCallback(UserData:PVkVoid;Size:TVkSize;Type_:TVkInternalAllocationType;Scope:TVkSystemAllocationScope); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TVulkanAllocationManager(UserData).InternalAllocationCallback(Size,Type_,Scope);
end;

procedure VulkanInternalFreeCallback(UserData:PVkVoid;Size:TVkSize;Type_:TVkInternalAllocationType;Scope:TVkSystemAllocationScope); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TVulkanAllocationManager(UserData).InternalFreeCallback(Size,Type_,Scope);
end;

constructor TVulkanAllocationManager.Create;
begin
 inherited Create;
 FillChar(fAllocationCallbacks,SizeOf(TVkAllocationCallbacks),#0);
 fAllocationCallbacks.pUserData:=self;
 fAllocationCallbacks.pfnAllocation:=VulkanAllocationCallback;
 fAllocationCallbacks.pfnReallocation:=VulkanReallocationCallback;
 fAllocationCallbacks.pfnFree:=VulkanFreeCallback;
 fAllocationCallbacks.pfnInternalAllocation:=VulkanInternalAllocationCallback;
 fAllocationCallbacks.pfnInternalFree:=VulkanInternalFreeCallback;
end;

destructor TVulkanAllocationManager.Destroy;
begin
 inherited Destroy;
end;

function TVulkanAllocationManager.AllocationCallback(const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid;
begin
 GetMem(result,Size);
end;

function TVulkanAllocationManager.ReallocationCallback(const Original:PVkVoid;const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid;
begin
 result:=Original;
 ReallocMem(result,Size);
end;

procedure TVulkanAllocationManager.FreeCallback(const Memory:PVkVoid);
begin
 FreeMem(Memory);
end;

procedure TVulkanAllocationManager.InternalAllocationCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
begin
end;

procedure TVulkanAllocationManager.InternalFreeCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
begin
end;

constructor TVulkanInstance.Create(const pApplicationName:TVulkanCharString='Vulkan application';
                                      const pApplicationVersion:TVkUInt32=1;
                                      const pEngineName:TVulkanCharString='Vulkan engine';
                                      const pEngineVersion:TVkUInt32=1;
                                      const pAPIVersion:TVkUInt32=VK_API_VERSION_1_0;
                                      const pValidation:boolean=false;
                                      const pAllocationManager:TVulkanAllocationManager=nil);
var Index,SubIndex:TVkInt32;
    Count,SubCount:TVkUInt32;
    LayerProperties:TVkLayerPropertiesArray;
    LayerProperty:PVulkanAvailableLayer;
    ExtensionProperties:TVkExtensionPropertiesArray;
    ExtensionProperty:PVulkanAvailableExtension;
begin
 inherited Create;

 if not Vulkan.LoadVulkanLibrary then begin
  raise EVulkanException.Create('Vulkan load error');
 end;

 if not Vulkan.LoadVulkanGlobalCommands then begin
  raise EVulkanException.Create('Vulkan load error');
 end;

 fVulkan:=vk;

 fApplicationName:=pApplicationName;
 fEngineName:=pEngineName;

 fEnabledLayerNameStrings:=nil;
 fEnabledExtensionNameStrings:=nil;

 fRawEnabledLayerNameStrings:=nil;
 fRawEnabledExtensionNameStrings:=nil;

 fInstanceHandle:=VK_NULL_INSTANCE;

 fDebugReportCallbackEXT:=VK_NULL_HANDLE;

 fOnInstanceDebugReportCallback:=nil;

 fInstanceVulkan:=nil;

 fPhysicalDevices:=TVulkanPhysicalDeviceList.Create;
 fNeedToEnumeratePhysicalDevices:=false;

 FillChar(fApplicationInfo,SizeOf(TVkApplicationInfo),#0);
 fApplicationInfo.sType:=VK_STRUCTURE_TYPE_APPLICATION_INFO;
 fApplicationInfo.pNext:=nil;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
 fApplicationInfo.applicationVersion:=pApplicationVersion;
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
 fApplicationInfo.engineVersion:=pEngineVersion;
 fApplicationInfo.apiVersion:=pAPIVersion;

 fValidation:=pValidation;

 fAllocationManager:=pAllocationManager;

 if assigned(pAllocationManager) then begin
  fAllocationCallbacks:=@pAllocationManager.fAllocationCallbacks;
 end else begin
  fAllocationCallbacks:=nil;
 end;

 fAvailableLayerNames:=TStringList.Create;
 fAvailableExtensionNames:=TStringList.Create;

 fEnabledLayerNames:=TStringList.Create;
 fEnabledExtensionNames:=TStringList.Create;

 LayerProperties:=nil;
 try
  fAvailableLayers:=nil;
  HandleResultCode(fVulkan.EnumerateInstanceLayerProperties(@Count,nil));
  if Count>0 then begin
   SetLength(LayerProperties,Count);
   SetLength(fAvailableLayers,Count);
   HandleResultCode(fVulkan.EnumerateInstanceLayerProperties(@Count,@LayerProperties[0]));
   for Index:=0 to Count-1 do begin
    LayerProperty:=@fAvailableLayers[Index];
    LayerProperty^.LayerName:=LayerProperties[Index].layerName;
    LayerProperty^.SpecVersion:=LayerProperties[Index].specVersion;
    LayerProperty^.ImplementationVersion:=LayerProperties[Index].implementationVersion;
    LayerProperty^.Description:=LayerProperties[Index].description;
    fAvailableLayerNames.Add(LayerProperty^.LayerName);
   end;
  end;
 finally
  SetLength(LayerProperties,0);
 end;

 ExtensionProperties:=nil;
 try
  fAvailableExtensions:=nil;
  Count:=0;
  for Index:=0 to length(fAvailableLayers)-1 do begin
   HandleResultCode(fVulkan.EnumerateInstanceExtensionProperties(PVkChar(fAvailableLayers[Index].layerName),@SubCount,nil));
   if SubCount>0 then begin
    if SubCount>TVkUInt32(length(ExtensionProperties)) then begin
     SetLength(ExtensionProperties,SubCount);
    end;
    SetLength(fAvailableExtensions,Count+SubCount);
    HandleResultCode(fVulkan.EnumerateInstanceExtensionProperties(PVkChar(fAvailableLayers[Index].layerName),@SubCount,@ExtensionProperties[0]));
    for SubIndex:=0 to SubCount-1 do begin
     ExtensionProperty:=@fAvailableExtensions[Count+TVkUInt32(SubIndex)];
     ExtensionProperty^.LayerIndex:=Index;
     ExtensionProperty^.ExtensionName:=ExtensionProperties[SubIndex].extensionName;
     ExtensionProperty^.SpecVersion:=ExtensionProperties[SubIndex].SpecVersion;
     if fAvailableExtensionNames.IndexOf(ExtensionProperty^.ExtensionName)<0 then begin
      fAvailableExtensionNames.Add(ExtensionProperty^.ExtensionName);
     end;
    end;
    inc(Count,SubCount);
   end;
  end;
 finally
  SetLength(ExtensionProperties,0);
 end;

 if fValidation then begin
{ if fAvailableExtensionNames.IndexOf('VK_LAYER_LUNARG_standard_validation')>=0 then begin
   fEnabledExtensionNames.Add(VK_EXT_DEBUG_REPORT_EXTENSION_NAME);
   fEnabledLayerNames.Add('VK_LAYER_LUNARG_standard_validation');
  end;{}
 end;

end;

destructor TVulkanInstance.Destroy;
begin
 if fDebugReportCallbackEXT<>VK_NULL_HANDLE then begin
  fInstanceVulkan.DestroyDebugReportCallbackEXT(fInstanceHandle,fDebugReportCallbackEXT,fAllocationCallbacks);
 end;
 fPhysicalDevices.Free;
 if fInstanceHandle<>VK_NULL_INSTANCE then begin
  fVulkan.DestroyInstance(fInstanceHandle,fAllocationCallbacks);
 end;
 fInstanceVulkan.Free;
 fApplicationName:='';
 fEngineName:='';
 fAvailableLayerNames.Free;
 fAvailableExtensionNames.Free;
 fEnabledLayerNames.Free;
 fEnabledExtensionNames.Free;
 SetLength(fAvailableLayers,0);
 SetLength(fAvailableExtensions,0);
 SetLength(fEnabledLayerNameStrings,0);
 SetLength(fRawEnabledLayerNameStrings,0);
 SetLength(fEnabledExtensionNameStrings,0);
 SetLength(fRawEnabledExtensionNameStrings,0);
 inherited Destroy;
end;

procedure TVulkanInstance.SetApplicationInfo(const NewApplicationInfo:TVkApplicationInfo);
begin
 fApplicationInfo:=NewApplicationInfo;
 fApplicationName:=fApplicationInfo.pApplicationName;
 fEngineName:=fApplicationInfo.pEngineName;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
end;

function TVulkanInstance.GetApplicationName:TVulkanCharString;
begin
 result:=fApplicationName;
end;

procedure TVulkanInstance.SetApplicationName(const NewApplicationName:TVulkanCharString);
begin
 fApplicationName:=NewApplicationName;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
end;

function TVulkanInstance.GetApplicationVersion:TVkUInt32;
begin
 result:=fApplicationInfo.applicationVersion;
end;

procedure TVulkanInstance.SetApplicationVersion(const NewApplicationVersion:TVkUInt32);
begin
 fApplicationInfo.applicationVersion:=NewApplicationVersion;
end;

function TVulkanInstance.GetEngineName:TVulkanCharString;
begin
 result:=fEngineName;
end;

procedure TVulkanInstance.SetEngineName(const NewEngineName:TVulkanCharString);
begin
 fEngineName:=NewEngineName;
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
end;

function TVulkanInstance.GetEngineVersion:TVkUInt32;
begin
 result:=fApplicationInfo.engineVersion;
end;

procedure TVulkanInstance.SetEngineVersion(const NewEngineVersion:TVkUInt32);
begin
 fApplicationInfo.engineVersion:=NewEngineVersion;
end;

function TVulkanInstance.GetAPIVersion:TVkUInt32;
begin
 result:=fApplicationInfo.apiVersion;
end;

procedure TVulkanInstance.SetAPIVersion(const NewAPIVersion:TVkUInt32);
begin
 fApplicationInfo.apiVersion:=NewAPIVersion;
end;

procedure TVulkanInstance.Initialize;
var i:TVkInt32;
    InstanceCommands:PVulkanCommands;
begin

 if fInstanceHandle=VK_NULL_INSTANCE then begin

  SetLength(fEnabledLayerNameStrings,fEnabledLayerNames.Count);
  SetLength(fRawEnabledLayerNameStrings,fEnabledLayerNames.Count);
  for i:=0 to fEnabledLayerNames.Count-1 do begin
   fEnabledLayerNameStrings[i]:=fEnabledLayerNames.Strings[i];
   fRawEnabledLayerNameStrings[i]:=PVkChar(fEnabledLayerNameStrings[i]);
  end;

  SetLength(fEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  SetLength(fRawEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  for i:=0 to fEnabledExtensionNames.Count-1 do begin
   fEnabledExtensionNameStrings[i]:=fEnabledExtensionNames.Strings[i];
   fRawEnabledExtensionNameStrings[i]:=PVkChar(fEnabledExtensionNameStrings[i]);
  end;

  FillChar(fInstanceCreateInfo,SizeOf(TVkInstanceCreateInfo),#0);
  fInstanceCreateInfo.sType:=VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  if length(fEnabledLayerNameStrings)>0 then begin
   fInstanceCreateInfo.enabledLayerCount:=length(fEnabledLayerNameStrings);
   fInstanceCreateInfo.ppEnabledLayerNames:=@fRawEnabledLayerNameStrings[0];
  end;
  if length(fEnabledExtensionNameStrings)>0 then begin
   fInstanceCreateInfo.enabledExtensionCount:=length(fEnabledExtensionNameStrings);
   fInstanceCreateInfo.ppEnabledExtensionNames:=@fRawEnabledExtensionNameStrings[0];
  end;

  HandleResultCode(fVulkan.CreateInstance(@fInstanceCreateInfo,fAllocationCallbacks,@fInstanceHandle));

  GetMem(InstanceCommands,SizeOf(TVulkanCommands));
  try
   FillChar(InstanceCommands^,SizeOf(TVulkanCommands),#0);
   if LoadVulkanInstanceCommands(fVulkan.Commands.GetInstanceProcAddr,fInstanceHandle,InstanceCommands^) then begin
    fInstanceVulkan:=TVulkan.Create(InstanceCommands^);
   end else begin
    raise EVulkanException.Create('Couldn''t load vulkan instance commands');
   end;
  finally
   FreeMem(InstanceCommands);
  end;

  EnumeratePhysicalDevices;

 end;
end;

procedure TVulkanInstance.EnumeratePhysicalDevices;
var Index,SubIndex:TVkInt32;
    Count:TVkUInt32;
    PhysicalDevices:TVkPhysicalDeviceArray;
    PhysicalDevice:TVulkanPhysicalDevice;
    Found:boolean;
begin
 PhysicalDevices:=nil;
 try
  Count:=0;
  HandleResultCode(fInstanceVulkan.EnumeratePhysicalDevices(fInstanceHandle,@Count,nil));
  if Count>0 then begin
   SetLength(PhysicalDevices,Count);
   HandleResultCode(fInstanceVulkan.EnumeratePhysicalDevices(fInstanceHandle,@Count,@PhysicalDevices[0]));
   for Index:=fPhysicalDevices.Count-1 downto 0 do begin
    Found:=false;
    for SubIndex:=0 to Count-1 do begin
     if fPhysicalDevices[Index].fPhysicalDeviceHandle=PhysicalDevices[SubIndex] then begin
      Found:=true;
      break;
     end;
    end;
    if not Found then begin
     fPhysicalDevices.Delete(Index);
    end;
   end;
   for Index:=0 to Count-1 do begin
    Found:=false;
    for SubIndex:=0 to fPhysicalDevices.Count-1 do begin
     if fPhysicalDevices[SubIndex].fPhysicalDeviceHandle=PhysicalDevices[Index] then begin
      Found:=true;
      break;
     end;
    end;
    if not Found then begin
     PhysicalDevice:=TVulkanPhysicalDevice.Create(self,PhysicalDevices[Index]);
     fPhysicalDevices.Add(PhysicalDevice);
    end;
   end;
  end;
 finally
  SetLength(PhysicalDevices,0);
 end;
end;

function TVulkanInstanceDebugReportCallbackFunction(flags:TVkDebugReportFlagsEXT;objectType:TVkDebugReportObjectTypeEXT;object_:TVkUInt64;location:TVkSize;messageCode:TVkInt32;const pLayerPrefix:PVkChar;const pMessage:PVkChar;pUserData:PVkVoid):TVkBool32; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TVulkanInstance(pUserData).DebugReportCallback(flags,objectType,object_,location,messageCode,pLayerPrefix,pMessage);
end;

function TVulkanInstance.DebugReportCallback(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TVkInt32;const pLayerPrefix:TVulkaNCharString;const pMessage:TVulkanCharString):TVkBool32;
begin
 if assigned(fOnInstanceDebugReportCallback) then begin
  result:=fOnInstanceDebugReportCallback(flags,objectType,object_,location,messageCode,pLayerPrefix,pMessage);
 end else begin
  result:=VK_FALSE;
 end;
end;

procedure TVulkanInstance.InstallDebugReportCallback;
begin
 if (fDebugReportCallbackEXT=VK_NULL_HANDLE) and assigned(fInstanceVulkan.Commands.CreateDebugReportCallbackEXT) then begin
  FillChar(fDebugReportCallbackCreateInfoEXT,SizeOf(TVkDebugReportCallbackCreateInfoEXT),#0);
  fDebugReportCallbackCreateInfoEXT.sType:=VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
  fDebugReportCallbackCreateInfoEXT.flags:=TVkUInt32(VK_DEBUG_REPORT_ERROR_BIT_EXT) or TVkUInt32(VK_DEBUG_REPORT_WARNING_BIT_EXT) or TVkUInt32(VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT);
  fDebugReportCallbackCreateInfoEXT.pfnCallback:=@TVulkanInstanceDebugReportCallbackFunction;
  fDebugReportCallbackCreateInfoEXT.pUserData:=self;
  HandleResultCode(fInstanceVulkan.CreateDebugReportCallbackEXT(fInstanceHandle,@fDebugReportCallbackCreateInfoEXT,fAllocationCallbacks,@fDebugReportCallbackEXT));
 end;
end;

constructor TVulkanPhysicalDevice.Create(const pInstance:TVulkanInstance;const pPhysicalDevice:TVkPhysicalDevice);
var Index,SubIndex:TVkInt32;
    Count,SubCount:TVkUInt32;
    LayerProperties:TVkLayerPropertiesArray;
    LayerProperty:PVulkanAvailableLayer;
    ExtensionProperties:TVkExtensionPropertiesArray;
    ExtensionProperty:PVulkanAvailableExtension;
begin
 inherited Create;

 fInstance:=pInstance;

 fPhysicalDeviceHandle:=pPhysicalDevice;

 fInstance.Commands.GetPhysicalDeviceProperties(fPhysicalDeviceHandle,@fProperties);

 fDeviceName:=fProperties.deviceName;

 fInstance.Commands.GetPhysicalDeviceMemoryProperties(fPhysicalDeviceHandle,@fMemoryProperties);

 fInstance.Commands.GetPhysicalDeviceFeatures(fPhysicalDeviceHandle,@fFeatures);

 fQueueFamilyProperties:=nil;
 Count:=0;
 fInstance.Commands.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@Count,nil);
 if Count>0 then begin
  try
   SetLength(fQueueFamilyProperties,Count);
   fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@Count,@fQueueFamilyProperties[0]);
  except
   SetLength(fQueueFamilyProperties,0);
   raise;
  end;
 end;

 fAvailableLayerNames:=TStringList.Create;
 fAvailableExtensionNames:=TStringList.Create;

 LayerProperties:=nil;
 try
  fAvailableLayers:=nil;
  HandleResultCode(fInstance.fVulkan.EnumerateDeviceLayerProperties(fPhysicalDeviceHandle,@Count,nil));
  if Count>0 then begin
   SetLength(LayerProperties,Count);
   SetLength(fAvailableLayers,Count);
   HandleResultCode(fInstance.fVulkan.EnumerateDeviceLayerProperties(fPhysicalDeviceHandle,@Count,@LayerProperties[0]));
   for Index:=0 to Count-1 do begin
    LayerProperty:=@fAvailableLayers[Index];
    LayerProperty^.LayerName:=LayerProperties[Index].layerName;
    LayerProperty^.SpecVersion:=LayerProperties[Index].specVersion;
    LayerProperty^.ImplementationVersion:=LayerProperties[Index].implementationVersion;
    LayerProperty^.Description:=LayerProperties[Index].description;
    fAvailableLayerNames.Add(LayerProperty^.LayerName);
   end;
  end;
 finally
  SetLength(LayerProperties,0);
 end;

 ExtensionProperties:=nil;
 try
  fAvailableExtensions:=nil;
  Count:=0;
  for Index:=0 to length(fAvailableLayers)-1 do begin
   HandleResultCode(fInstance.fVulkan.EnumerateDeviceExtensionProperties(fPhysicalDeviceHandle,PVkChar(fAvailableLayers[Index].layerName),@SubCount,nil));
   if SubCount>0 then begin
    if SubCount>TVkUInt32(length(ExtensionProperties)) then begin
     SetLength(ExtensionProperties,SubCount);
    end;
    SetLength(fAvailableExtensions,Count+SubCount);
    HandleResultCode(fInstance.fVulkan.EnumerateDeviceExtensionProperties(fPhysicalDeviceHandle,PVkChar(fAvailableLayers[Index].layerName),@SubCount,@ExtensionProperties[0]));
    for SubIndex:=0 to SubCount-1 do begin
     ExtensionProperty:=@fAvailableExtensions[Count+TVkUInt32(SubIndex)];
     ExtensionProperty^.LayerIndex:=Index;
     ExtensionProperty^.ExtensionName:=ExtensionProperties[SubIndex].extensionName;
     ExtensionProperty^.SpecVersion:=ExtensionProperties[SubIndex].SpecVersion;
     if fAvailableExtensionNames.IndexOf(ExtensionProperty^.ExtensionName)<0 then begin
      fAvailableExtensionNames.Add(ExtensionProperty^.ExtensionName);
     end;
    end;
    inc(Count,SubCount);
   end;
  end;
 finally
  SetLength(ExtensionProperties,0);
 end;

end;

destructor TVulkanPhysicalDevice.Destroy;
begin
 SetLength(fQueueFamilyProperties,0);
 fAvailableLayerNames.Free;
 fAvailableExtensionNames.Free;
 SetLength(fAvailableLayers,0);
 SetLength(fAvailableExtensions,0);
 inherited Destroy;
end;

function TVulkanPhysicalDevice.GetFormatProperties(const pFormat:TVkFormat):TVkFormatProperties;
begin
 fInstance.Commands.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,pFormat,@result);
end;

function TVulkanPhysicalDevice.GetImageFormatProperties(const pFormat:TVkFormat;
                                                        const pType:TVkImageType;
                                                        const pTiling:TVkImageTiling;
                                                        const pUsageFlags:TVkImageUsageFlags;
                                                        const pCreateFlags:TVkImageCreateFlags):TVkImageFormatProperties;
begin
 fInstance.Commands.GetPhysicalDeviceImageFormatProperties(fPhysicalDeviceHandle,pFormat,pType,pTiling,pUsageFlags,pCreateFlags,@result);
end;

function TVulkanPhysicalDevice.GetSparseImageFormatProperties(const pFormat:TVkFormat;
                                                              const pType:TVkImageType;
                                                              const pSamples:TVkSampleCountFlagBits;
                                                              const pUsageFlags:TVkImageUsageFlags;
                                                              const pTiling:TVkImageTiling):TVkSparseImageFormatPropertiesArray;
var Count:TVkUInt32;
begin
 result:=nil;
 Count:=0;
 fInstance.Commands.GetPhysicalDeviceSparseImageFormatProperties(fPhysicalDeviceHandle,pFormat,pType,pSamples,pUsageFlags,pTiling,@Count,nil);
 if Count>0 then begin
  SetLength(result,Count);
  fInstance.Commands.GetPhysicalDeviceSparseImageFormatProperties(fPhysicalDeviceHandle,pFormat,pType,pSamples,pUsageFlags,pTiling,@Count,@result[0]);
 end;
end;

function TVulkanPhysicalDevice.GetSurfaceSupport(const pQueueFamilyIndex:TVkUInt32;const pSurface:TVulkanSurface):boolean;
var Supported:TVkBool32;
begin
 Supported:=0;
 fInstance.Commands.GetPhysicalDeviceSurfaceSupportKHR(fPhysicalDeviceHandle,pQueueFamilyIndex,pSurface.fSurfaceHandle,@Supported);
 result:=Supported<>0;
end;

function TVulkanPhysicalDevice.GetSurfaceCapabilities(const pSurface:TVulkanSurface):TVkSurfaceCapabilitiesKHR;
begin
 fInstance.Commands.GetPhysicalDeviceSurfaceCapabilitiesKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@result);
end;

function TVulkanPhysicalDevice.GetSurfaceFormats(const pSurface:TVulkanSurface):TVkSurfaceFormatKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetSurfacePresentModes(const pSurface:TVulkanSurface):TVkPresentModeKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceSurfacePresentModesKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceSurfacePresentModesKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetDisplayProperties:TVkDisplayPropertiesKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceDisplayPropertiesKHR(fPhysicalDeviceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceDisplayPropertiesKHR(fPhysicalDeviceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetDisplayPlaneProperties:TVkDisplayPlanePropertiesKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceDisplayPlanePropertiesKHR(fPhysicalDeviceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceDisplayPlanePropertiesKHR(fPhysicalDeviceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetDisplayPlaneSupportedDisplays(const pPlaneIndex:TVkUInt32):TVkDisplayKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetDisplayPlaneSupportedDisplaysKHR(fPhysicalDeviceHandle,pPlaneIndex,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetDisplayPlaneSupportedDisplaysKHR(fPhysicalDeviceHandle,pPlaneIndex,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetDisplayModeProperties(const pDisplay:TVkDisplayKHR):TVkDisplayModePropertiesKHRArray;
var Count:TVKUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetDisplayModePropertiesKHR(fPhysicalDeviceHandle,pDisplay,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetDisplayModePropertiesKHR(fPhysicalDeviceHandle,pDisplay,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetMemoryType(const pTypeBits:TVkUInt32;const pProperties:TVkFlags):TVkUInt32;
var i:TVkUInt32;
    DeviceMemoryProperties:TVkPhysicalDeviceMemoryProperties;
begin
 result:=TVkUInt32(TVkInt32(-1));
 vkGetPhysicalDeviceMemoryProperties(fPhysicalDeviceHandle,@DeviceMemoryProperties);
 for i:=0 to 31 do begin
  if (pTypeBits and (TVkUInt32(1) shl i))<>0 then begin
   if (DeviceMemoryProperties.MemoryTypes[i].PropertyFlags and pProperties)=pProperties then begin
    result:=i;
    exit;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetBestSupportedDepthFormat(const pWithStencil:boolean):TVkFormat;
const Formats:array[0..4] of TVkFormat=(VK_FORMAT_D32_SFLOAT_S8_UINT,
                                        VK_FORMAT_D32_SFLOAT,
                                        VK_FORMAT_D24_UNORM_S8_UINT,
                                        VK_FORMAT_D16_UNORM_S8_UINT,
                                        VK_FORMAT_D16_UNORM);
      WithStencilFormats:array[0..2] of TVkFormat=(VK_FORMAT_D32_SFLOAT_S8_UINT,
                                                   VK_FORMAT_D24_UNORM_S8_UINT,
                                                   VK_FORMAT_D16_UNORM_S8_UINT);
var i:TVkInt32;
    Format:TVkFormat;
    FormatProperties:TVkFormatProperties;
begin
 result:=VK_FORMAT_UNDEFINED;
 if pWithStencil then begin
  for i:=low(WithStencilFormats) to high(WithStencilFormats) do begin
   Format:=WithStencilFormats[i];
   fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,Format,@FormatProperties);
   if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
    result:=Format;
    exit;
   end;
  end;
 end else begin
  for i:=low(Formats) to high(Formats) do begin
   Format:=Formats[i];
   fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,Format,@FormatProperties);
   if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
    result:=Format;
    exit;
   end;
  end;
 end;
end;

function TVulkanPhysicalDevice.GetQueueNodeIndex(const pSurface:TVulkanSurface;const pQueueFlagBits:TVkQueueFlagBits):TVkInt32;
var Index:TVkInt32;
    QueueCount:TVkUInt32;
    QueueProperties:array of TVkQueueFamilyProperties;
    SupportsPresent:TVkBool32;
begin
 result:=-1;
 fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@QueueCount,nil);
 QueueProperties:=nil;
 SetLength(QueueProperties,QueueCount);
 try
  fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@QueueCount,@QueueProperties[0]);
  for Index:=0 to QueueCount-1 do begin
   fInstance.fVulkan.GetPhysicalDeviceSurfaceSupportKHR(fPhysicalDeviceHandle,Index,pSurface.fSurfaceHandle,@SupportsPresent);
   if ((QueueProperties[Index].QueueFlags and TVkQueueFlags(pQueueFlagBits))<>0) and (SupportsPresent=VK_TRUE) then begin
    result:=Index;
    break;
   end;
  end;
 finally
  SetLength(QueueProperties,0);
 end;
end;

function TVulkanPhysicalDevice.GetSurfaceFormat(const pSurface:TVulkanSurface):TVkSurfaceFormatKHR;
var FormatCount:TVkUInt32;
    SurfaceFormats:TVkSurfaceFormatKHRArray;
begin
 SurfaceFormats:=nil;
 try

  FormatCount:=0;
  HandleResultCode(vkGetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@FormatCount,nil));

  if FormatCount>0 then begin
   SetLength(SurfaceFormats,FormatCount);
   HandleResultCode(vkGetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,pSurface.fSurfaceHandle,@FormatCount,@SurfaceFormats[0]));
  end;

  if (FormatCount=0) or ((FormatCount=1) and (SurfaceFormats[0].Format=VK_FORMAT_UNDEFINED)) then begin
   result.Format:=VK_FORMAT_B8G8R8A8_UNORM;
   result.ColorSpace:=VK_COLORSPACE_SRGB_NONLINEAR_KHR;
  end else begin
   result:=SurfaceFormats[0];
  end;

 finally
  SetLength(SurfaceFormats,0);
 end;

end;

function TVulkanPhysicalDeviceList.GetItem(const Index:TVkSizeInt):TVulkanPhysicalDevice;
begin
 result:=TVulkanPhysicalDevice(inherited Items[Index]);
end;

procedure TVulkanPhysicalDeviceList.SetItem(const Index:TVkSizeInt;const Item:TVulkanPhysicalDevice);
begin
 inherited Items[Index]:=Item;
end;

constructor TVulkanSurface.Create(const pInstance:TVulkanInstance;
{$if defined(Android)}
                                  const pWindow:PANativeWindow
{$elseif defined(Mir)}
                                  const pConnection:PMirConnection;const pMirSurface:PMirSurface
{$elseif defined(Wayland)}
                                  const pDisplay:Pwl_display;const pSurface:Pwl_surface
{$elseif defined(Windows)}
                                  const pInstanceHandle,pWindowHandle:THandle
{$elseif defined(X11)}
                                  const pDisplay:PDisplay;const pWindow:TWindow
{$elseif defined(XCB)}
                                  const pConnection:Pxcb_connection;pWindow:Pxcb_window
{$ifend}
                                 );
begin
 inherited Create;

 fInstance:=pInstance;

 fSurfaceHandle:=VK_NULL_HANDLE;

 FillChar(fSurfaceCreateInfo,SizeOf(TVulkanSurfaceCreateInfo),#0);
{$if defined(Android)}
 fSurfaceCreateInfo.sType:=VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
 fSurfaceCreateInfo.window:=pWindow;
{$elseif defined(Mir)}
 fSurfaceCreateInfo.sType:=VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR;
 fSurfaceCreateInfo.connection:=pConnection;
 fSurfaceCreateInfo.mirSurface:=pMirSurface;
{$elseif defined(Wayland)}
 fSurfaceCreateInfo.sType:=VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR;
 fSurfaceCreateInfo.display:=pDisplay;
 fSurfaceCreateInfo.surface:=pSurface;
{$elseif defined(Windows)}
 fSurfaceCreateInfo.sType:=VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
 fSurfaceCreateInfo.hinstance_:=pInstanceHandle;
 fSurfaceCreateInfo.hwnd_:=pWindowHandle;
{$elseif defined(X11)}
 fSurfaceCreateInfo.sType:=VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
 fSurfaceCreateInfo.dpy:=pDisplay;
 fSurfaceCreateInfo.window:=pWindow;
{$elseif defined(XCB)}
 fSurfaceCreateInfo.connection:=pConnection;
 fSurfaceCreateInfo.window:=pWindow;
{$ifend}

{$if defined(Android)}
 HandleResultCode(fInstance.fVulkan.CreateAndroidSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$elseif defined(Mir)}
 HandleResultCode(fInstance.fVulkan.CreateMirSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$elseif defined(Wayland)}
 HandleResultCode(fInstance.fVulkan.CreateWaylandSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$elseif defined(Windows)}
 HandleResultCode(fInstance.fVulkan.CreateWin32SurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$elseif defined(X11)}
 HandleResultCode(fInstance.fVulkan.CreateX11SurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$elseif defined(XCB)}
 HandleResultCode(fInstance.fVulkan.CreateXCBSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo,fInstance.fAllocationCallbacks,@fSurfaceHandle));
{$else}
 HandleResultCode(VK_ERROR_INCOMPATIBLE_DRIVER);
{$ifend}

end;

destructor TVulkanSurface.Destroy;
begin
 if fSurfaceHandle<>VK_NULL_HANDLE then begin
  fInstance.fVulkan.DestroySurfaceKHR(fInstance.fInstanceHandle,fSurfaceHandle,fInstance.fAllocationCallbacks);
  fSurfaceHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TVulkanDevice.Create(const pInstance:TVulkanInstance;
                                 const pPhysicalDevice:TVulkanPhysicalDevice=nil;
                                 const pSurface:TVulkanSurface=nil;
                                 const pAllocationManager:TVulkanAllocationManager=nil);
var Index,SubIndex:TVkInt32;
    BestPhysicalDevice,CurrentPhysicalDevice:TVulkanPhysicalDevice;
    BestScore,CurrentScore,Temp:int64;
    OK:boolean;
begin
 inherited Create;

 fInstance:=pInstance;

 fDeviceQueueCreateInfoList:=TVulkanDeviceQueueCreateInfoList.Create;

 fDeviceQueueCreateInfos:=nil;

 fEnabledLayerNameStrings:=nil;
 fEnabledExtensionNameStrings:=nil;

 fRawEnabledLayerNameStrings:=nil;
 fRawEnabledExtensionNameStrings:=nil;

 if assigned(pAllocationManager) then begin
  fAllocationManager:=pAllocationManager;
 end else begin
  fAllocationManager:=fInstance.fAllocationManager;
 end;

 if assigned(fAllocationManager) then begin
  fAllocationCallbacks:=@fAllocationManager.fAllocationCallbacks;
 end else begin
  fAllocationCallbacks:=nil;
 end;

 fSurface:=pSurface;

 fDeviceHandle:=VK_NULL_HANDLE;

 fDeviceVulkan:=nil;

 fGraphicQueueFamilyIndex:=-1;
 fComputeQueueFamilyIndex:=-1;
 fTransferQueueFamilyIndex:=-1;
 fSparseBindingQueueFamilyIndex:=-1;

 fGraphicQueue:=nil;
 fComputeQueue:=nil;
 fTransferQueue:=nil;

 if assigned(pPhysicalDevice) then begin
  fPhysicalDevice:=pPhysicalDevice;
 end else begin
  BestPhysicalDevice:=nil;
  BestScore:=-$7fffffffffffffff;
  for Index:=0 to fInstance.fPhysicalDevices.Count-1 do begin
   CurrentPhysicalDevice:=fInstance.fPhysicalDevices[Index];
   CurrentScore:=0;
   case CurrentPhysicalDevice.fProperties.deviceType of
    VK_PHYSICAL_DEVICE_TYPE_OTHER:begin
     CurrentScore:=CurrentScore or (int64(1) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:begin
     CurrentScore:=CurrentScore or (int64(3) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:begin
     CurrentScore:=CurrentScore or (int64(4) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU:begin
     CurrentScore:=CurrentScore or (int64(2) shl 60);
    end;
    else begin
     CurrentScore:=CurrentScore or (int64(0) shl 60);
    end;
   end;
   OK:=false;
   for SubIndex:=0 to length(CurrentPhysicalDevice.fQueueFamilyProperties)-1 do begin
    if assigned(pSurface) and not CurrentPhysicalDevice.GetSurfaceSupport(SubIndex,pSurface) then begin
     continue;
    end;
    OK:=true;
    Temp:=0;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TVkInt32(VK_QUEUE_GRAPHICS_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TVkInt32(VK_QUEUE_COMPUTE_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TVkInt32(VK_QUEUE_TRANSFER_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TVkInt32(VK_QUEUE_SPARSE_BINDING_BIT))<>0 then begin
     inc(Temp);
    end;
    CurrentScore:=CurrentScore or (int64(Temp) shl 55);
   end;
   if not OK then begin
    continue;
   end;
   if (BestScore>CurrentScore) or not assigned(BestPhysicalDevice) then begin
    BestPhysicalDevice:=CurrentPhysicalDevice;
    BestScore:=CurrentScore;
   end;
  end;
  if assigned(BestPhysicalDevice) then begin
   fPhysicalDevice:=BestPhysicalDevice;
  end else begin
   raise EVulkanException.Create('No suitable vulkan device found');
  end;
 end;

 fEnabledLayerNames:=TStringList.Create;
 fEnabledExtensionNames:=TStringList.Create;

 fEnabledFeatures:=fPhysicalDevice.fProperties.limits;

 fPointerToEnabledFeatures:=@fEnabledFeatures;

 fMemoryManager:=TVulkanDeviceMemoryManager.Create(self);

end;

destructor TVulkanDevice.Destroy;
begin
 fGraphicQueue.Free;
 fComputeQueue.Free;
 fTransferQueue.Free;
 fMemoryManager.Free;
 fDeviceVulkan.Free;
 if fDeviceHandle<>VK_NULL_HANDLE then begin
  fInstance.Commands.DestroyDevice(fDeviceHandle,fAllocationCallbacks);
 end;
 SetLength(fDeviceQueueCreateInfos,0);
 fDeviceQueueCreateInfoList.Free;
 fEnabledLayerNames.Free;
 fEnabledExtensionNames.Free;
 SetLength(fEnabledLayerNameStrings,0);
 SetLength(fRawEnabledLayerNameStrings,0);
 SetLength(fEnabledExtensionNameStrings,0);
 SetLength(fRawEnabledExtensionNameStrings,0);
 inherited Destroy;
end;

procedure TVulkanDevice.AddQueue(const pQueueFamilyIndex:TVkUInt32;const pQueuePriorities:array of TVkFloat);
var QueueFamilyProperties:PVkQueueFamilyProperties;
begin           
 if pQueueFamilyIndex<TVkUInt32(length(fPhysicalDevice.fQueueFamilyProperties)) then begin
  if assigned(fSurface) and not fPhysicalDevice.GetSurfaceSupport(pQueueFamilyIndex,fSurface) then begin
   raise EVulkanException.Create('Surface doesn''t support queue family index '+IntToStr(pQueueFamilyIndex));
  end;
  QueueFamilyProperties:=@fPhysicalDevice.fQueueFamilyProperties[pQueueFamilyIndex];
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_GRAPHICS_BIT))<>0) and (fGraphicQueueFamilyIndex<0) then begin
   fGraphicQueueFamilyIndex:=pQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_COMPUTE_BIT))<>0) and (fComputeQueueFamilyIndex<0) then begin
   fComputeQueueFamilyIndex:=pQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_TRANSFER_BIT))<>0) and (fTransferQueueFamilyIndex<0) then begin
   fTransferQueueFamilyIndex:=pQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_SPARSE_BINDING_BIT))<>0) and (fSparseBindingQueueFamilyIndex<0) then begin
   fSparseBindingQueueFamilyIndex:=pQueueFamilyIndex;
  end;
  fDeviceQueueCreateInfoList.Add(TVulkanDeviceQueueCreateInfo.Create(pQueueFamilyIndex,pQueuePriorities));
 end else begin
  raise EVulkanException.Create('Queue family index out of bounds');
 end;
end;

procedure TVulkanDevice.AddQueues(const pGraphic:boolean=true;
                                  const pCompute:boolean=true;
                                  const pTransfer:boolean=true;
                                  const pSparseBinding:boolean=false);
var Index:TVkInt32;
    DoAdd:boolean;
    QueueFamilyProperties:PVkQueueFamilyProperties;
begin
 for Index:=0 to length(fPhysicalDevice.fQueueFamilyProperties)-1 do begin
  DoAdd:=false;
  QueueFamilyProperties:=@fPhysicalDevice.fQueueFamilyProperties[Index];
  if assigned(fSurface) and not fPhysicalDevice.GetSurfaceSupport(Index,fSurface) then begin
   continue;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_GRAPHICS_BIT))<>0) and (fGraphicQueueFamilyIndex<0) then begin
   fGraphicQueueFamilyIndex:=Index;
   if pGraphic then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_COMPUTE_BIT))<>0) and (fComputeQueueFamilyIndex<0) then begin
   fComputeQueueFamilyIndex:=Index;
   if pCompute then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_TRANSFER_BIT))<>0) and (fTransferQueueFamilyIndex<0) then begin
   fTransferQueueFamilyIndex:=Index;
   if pTransfer then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TVKUInt32(VK_QUEUE_SPARSE_BINDING_BIT))<>0) and (fSparseBindingQueueFamilyIndex<0) then begin
   fSparseBindingQueueFamilyIndex:=Index;
   if pSparseBinding then begin
    DoAdd:=true;
   end;
  end;
  if DoAdd then begin
   fDeviceQueueCreateInfoList.Add(TVulkanDeviceQueueCreateInfo.Create(Index,[1.0]));
  end;
 end;
 if ((fGraphicQueueFamilyIndex<0) and pGraphic) or
    ((fComputeQueueFamilyIndex<0) and pCompute) or
    ((fTransferQueueFamilyIndex<0) and pTransfer) or
    ((fSparseBindingQueueFamilyIndex<0) and pSparseBinding) then begin
  raise EVulkanException.Create('Only unsatisfactory device queue families available');
 end;
end;

procedure TVulkanDevice.Initialize;
var Index:TVkInt32;
    DeviceQueueCreateInfo:PVkDeviceQueueCreateInfo;
    SrcDeviceQueueCreateInfo:TVulkanDeviceQueueCreateInfo;
    DeviceCommands:PVulkanCommands;
    Queue:TVkQueue;
begin
 if fDeviceHandle=VK_NULL_HANDLE then begin

  SetLength(fEnabledLayerNameStrings,fEnabledLayerNames.Count);
  SetLength(fRawEnabledLayerNameStrings,fEnabledLayerNames.Count);
  for Index:=0 to fEnabledLayerNames.Count-1 do begin
   fEnabledLayerNameStrings[Index]:=fEnabledLayerNames.Strings[Index];
   fRawEnabledLayerNameStrings[Index]:=PVkChar(fEnabledLayerNameStrings[Index]);
  end;

  SetLength(fEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  SetLength(fRawEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  for Index:=0 to fEnabledExtensionNames.Count-1 do begin
   fEnabledExtensionNameStrings[Index]:=fEnabledExtensionNames.Strings[Index];
   fRawEnabledExtensionNameStrings[Index]:=PVkChar(fEnabledExtensionNameStrings[Index]);
  end;

  SetLength(fDeviceQueueCreateInfos,fDeviceQueueCreateInfoList.Count);
  for Index:=0 to fDeviceQueueCreateInfoList.Count-1 do begin
   SrcDeviceQueueCreateInfo:=fDeviceQueueCreateInfoList[Index];
   DeviceQueueCreateInfo:=@fDeviceQueueCreateInfos[Index];
   FillChar(DeviceQueueCreateInfo^,SizeOf(TVkDeviceQueueCreateInfo),#0);
   DeviceQueueCreateInfo^.sType:=VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
   DeviceQueueCreateInfo^.queueFamilyIndex:=SrcDeviceQueueCreateInfo.fQueueFamilyIndex;
   DeviceQueueCreateInfo^.queueCount:=length(SrcDeviceQueueCreateInfo.fQueuePriorities);
   if DeviceQueueCreateInfo^.queueCount>0 then begin
    DeviceQueueCreateInfo^.pQueuePriorities:=@SrcDeviceQueueCreateInfo.fQueuePriorities[0];
   end;
  end;

  FillChar(fDeviceCreateInfo,SizeOf(TVkDeviceCreateInfo),#0);
  fDeviceCreateInfo.sType:=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  if length(fDeviceQueueCreateInfos)>0 then begin
   fDeviceCreateInfo.queueCreateInfoCount:=length(fDeviceQueueCreateInfos);
   fDeviceCreateInfo.pQueueCreateInfos:=@fDeviceQueueCreateInfos[0];
  end;
  if length(fEnabledLayerNameStrings)>0 then begin
   fDeviceCreateInfo.enabledLayerCount:=length(fEnabledLayerNameStrings);
   fDeviceCreateInfo.ppEnabledLayerNames:=@fRawEnabledLayerNameStrings[0];
  end;
  if length(fEnabledExtensionNameStrings)>0 then begin
   fDeviceCreateInfo.enabledExtensionCount:=length(fEnabledExtensionNameStrings);
   fDeviceCreateInfo.ppEnabledExtensionNames:=@fRawEnabledExtensionNameStrings[0];
  end;
  fDeviceCreateInfo.pEnabledFeatures:=@fEnabledFeatures;
  HandleResultCode(fInstance.Commands.CreateDevice(fPhysicalDevice.fPhysicalDeviceHandle,@fDeviceCreateInfo,fAllocationCallbacks,@fDeviceHandle));

  GetMem(DeviceCommands,SizeOf(TVulkanCommands));
  try
   FillChar(DeviceCommands^,SizeOf(TVulkanCommands),#0);
   if LoadVulkanDeviceCommands(fInstance.Commands.Commands.GetDeviceProcAddr,fDeviceHandle,DeviceCommands^) then begin
    fDeviceVulkan:=TVulkan.Create(DeviceCommands^);
   end else begin
    raise EVulkanException.Create('Couldn''t load vulkan device commands');
   end;
  finally
   FreeMem(DeviceCommands);
  end;

  if fGraphicQueueFamilyIndex>=0 then begin
   fDeviceVulkan.GetDeviceQueue(fDeviceHandle,fGraphicQueueFamilyIndex,0,@Queue);
   fGraphicQueue:=TVulkanQueue.Create(self,Queue);
  end;
  if fComputeQueueFamilyIndex>=0 then begin
   fDeviceVulkan.GetDeviceQueue(fDeviceHandle,fComputeQueueFamilyIndex,0,@Queue);
   fComputeQueue:=TVulkanQueue.Create(self,Queue);
  end;
  if fTransferQueueFamilyIndex>=0 then begin
   fDeviceVulkan.GetDeviceQueue(fDeviceHandle,fTransferQueueFamilyIndex,0,@Queue);
   fTransferQueue:=TVulkanQueue.Create(self,Queue);
  end;

 end;
end;

procedure TVulkanDevice.WaitIdle;
begin
 fDeviceVulkan.DeviceWaitIdle(fDeviceHandle);
end;

constructor TVulkanDeviceQueueCreateInfo.Create(const pQueueFamilyIndex:TVkUInt32;const pQueuePriorities:array of TVkFloat);
begin
 inherited Create;
 fQueueFamilyIndex:=pQueueFamilyIndex;
 SetLength(fQueuePriorities,length(pQueuePriorities));
 if length(pQueuePriorities)>0 then begin
  Move(pQueuePriorities[0],fQueuePriorities[0],length(pQueuePriorities)*SizeOf(TVkFloat));
 end;
end;

destructor TVulkanDeviceQueueCreateInfo.Destroy;
begin
 SetLength(fQueuePriorities,0);
 inherited Destroy;
end;

function TVulkanDeviceQueueCreateInfoList.GetItem(const Index:TVkSizeInt):TVulkanDeviceQueueCreateInfo;
begin
 result:=TVulkanDeviceQueueCreateInfo(inherited Items[Index]);
end;

procedure TVulkanDeviceQueueCreateInfoList.SetItem(const Index:TVkSizeInt;const Item:TVulkanDeviceQueueCreateInfo);
begin
 inherited Items[Index]:=Item;
end;

constructor TVulkanResource.Create;
begin
 inherited Create;
 fDevice:=nil;
 fOwnsResource:=false;
end;

destructor TVulkanResource.Destroy;
begin
 inherited Destroy;
end;

procedure TVulkanResource.Clear;
begin
 fDevice:=nil;
 fOwnsResource:=false;
end;

constructor TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Create(const pKey:TVkUInt64=0;
                                                                 const pValue:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue=nil;
                                                                 const pLeft:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                 const pRight:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                 const pParent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                 const pColor:boolean=false);
begin
 inherited Create;
 fKey:=pKey;
 fValue:=pValue;
 fLeft:=pLeft;
 fRight:=pRight;
 fParent:=pParent;
 fColor:=pColor;
end;

destructor TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Destroy;
begin
 FreeAndNil(fLeft);
 FreeAndNil(fRight);
 inherited Destroy;
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Clear;
begin
 fKey:=0;
 fLeft:=nil;
 fRight:=nil;
 fParent:=nil;
 fColor:=false;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Minimum:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=self;
 while assigned(result.fLeft) do begin
  result:=result.fLeft;
 end;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Maximum:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=self;
 while assigned(result.fRight) do begin
  result:=result.fRight;
 end;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Predecessor:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var Last:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 if assigned(fLeft) then begin
  result:=fLeft;
  while assigned(result) and assigned(result.fRight) do begin
   result:=result.fRight;
  end;
 end else begin
  Last:=self;
  result:=Parent;
  while assigned(result) and (result.fLeft=Last) do begin
   Last:=result;
   result:=result.Parent;
  end;
 end;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Successor:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var Last:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 if assigned(fRight) then begin
  result:=fRight;
  while assigned(result) and assigned(result.fLeft) do begin
   result:=result.fLeft;
  end;
 end else begin
  Last:=self;
  result:=Parent;
  while assigned(result) and (result.fRight=Last) do begin
   Last:=result;
   result:=result.Parent;
  end;
 end;
end;

constructor TVulkanDeviceMemoryChunkBlockRedBlackTree.Create;
begin
 inherited Create;
 fRoot:=nil;
end;

destructor TVulkanDeviceMemoryChunkBlockRedBlackTree.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTree.Clear;
begin
 FreeAndNil(fRoot);
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTree.RotateLeft(x:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var y:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 y:=x.fRight;
 x.fRight:=y.fLeft;
 if assigned(y.fLeft) then begin
  y.fLeft.fParent:=x;
 end;
 y.fParent:=x.fParent;
 if x=fRoot then begin
  fRoot:=y;
 end else if x=x.fParent.fLeft then begin
  x.fparent.fLeft:=y;
 end else begin
  x.fParent.fRight:=y;
 end;
 y.fLeft:=x;
 x.fParent:=y;
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTree.RotateRight(x:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var y:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 y:=x.fLeft;
 x.fLeft:=y.fRight;
 if assigned(y.fRight) then begin
  y.fRight.fParent:=x;
 end;
 y.fParent:=x.fParent;
 if x=fRoot then begin
  fRoot:=y;
 end else if x=x.fParent.fRight then begin
  x.fParent.fRight:=y;
 end else begin
  x.fParent.fLeft:=y;
 end;
 y.fRight:=x;
 x.fParent:=y;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTree.Find(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey):TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) do begin
  if pKey<result.fKey then begin
   result:=result.fLeft;
  end else if pKey>result.fKey then begin
   result:=result.fRight;
  end else begin
   exit;
  end;
 end;
 result:=nil;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTree.Insert(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
                                                          const pValue:TVulkanDeviceMemoryChunkBlockRedBlackTreeValue):TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var x,y,xParentParent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 x:=fRoot;
 y:=nil;
 while assigned(x) do begin
  y:=x;
  if pKey<x.fKey then begin
   x:=x.fLeft;
  end else begin
   x:=x.fRight;
  end;
 end;
 result:=TVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Create(pKey,pValue,nil,nil,y,true);
 if assigned(y) then begin
  if pKey<y.fKey then begin
   y.Left:=result;
  end else begin
   y.Right:=result;
  end;
 end else begin
  fRoot:=result;
 end;
 x:=result;
 while (x<>fRoot) and assigned(x.fParent) and assigned(x.fParent.fParent) and x.fParent.fColor do begin
  xParentParent:=x.fParent.fParent;
  if x.fParent=xParentParent.fLeft then begin
   y:=xParentParent.fRight;
   if assigned(y) and y.fColor then begin
    x.fParent.fColor:=false;
    y.fColor:=false;
    xParentParent.fColor:=true;
    x:=xParentParent;
   end else begin
    if x=x.fParent.fRight then begin
     x:=x.fParent;
     RotateLeft(x);
    end;
    x.fParent.fColor:=false;
    xParentParent.fColor:=true;
    RotateRight(xParentParent);
   end;
  end else begin
   y:=xParentParent.fLeft;
   if assigned(y) and y.fColor then begin
    x.fParent.fColor:=false;
    y.fColor:=false;
    x.fParent.fParent.fColor:=true;
    x:=x.fParent.fParent;
   end else begin
    if x=x.fParent.fLeft then begin
     x:=x.fParent;
     RotateRight(x);
    end;
    x.fParent.fColor:=false;
    xParentParent.fColor:=true;
    RotateLeft(xParentParent);
   end;
  end;
 end;
 fRoot.fColor:=false;
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTree.Remove(const pNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var w,x,y,z,xParent:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    TemporaryColor:boolean;
begin
 z:=pNode;
 y:=z;
 x:=nil;
 xParent:=nil;
 if assigned(x) and assigned(xParent) then begin
  // For to suppress "Value assigned to '*' never used" hints
 end;
 if assigned(y.fLeft) then begin
  if assigned(y.fRight) then begin
   y:=y.fRight;
   while assigned(y.fLeft) do begin
    y:=y.fLeft;
   end;
   x:=y.fRight;
  end else begin
   x:=y.fLeft;
  end;
 end else begin
  x:=y.fRight;
 end;
 if y<>z then begin
  z.fLeft.fParent:=y;
  y.fLeft:=z.fLeft;
  if y<>z.fRight then begin
   xParent:=y.fParent;
   if assigned(x) then begin
    x.fParent:=y.fParent;
   end;
   y.fParent.fLeft:=x;
   y.fRight:=z.fRight;
   z.fRight.fParent:=y;
  end else begin
   xParent:=y;
  end;
  if fRoot=z then begin
   fRoot:=y;
  end else if z.fParent.fLeft=z then begin
   z.fParent.fLeft:=y;
  end else begin
   z.fParent.fRight:=y;
  end;
  y.fParent:=z.fParent;
  TemporaryColor:=y.fColor;
  y.fColor:=z.fColor;
  z.fColor:=TemporaryColor;
  y:=z;
 end else begin
  xParent:=y.fParent;
  if assigned(x) then begin
   x.fParent:=y.fParent;
  end;
  if fRoot=z then begin
   fRoot:=x;
  end else if z.fParent.fLeft=z then begin
   z.fParent.fLeft:=x;
  end else begin
   z.fParent.fRight:=x;
  end;
 end;
 if assigned(y) then begin
  if not y.fColor then begin
   while (x<>fRoot) and not (assigned(x) and x.fColor) do begin
    if x=xParent.fLeft then begin
     w:=xParent.fRight;
     if w.fColor then begin
      w.fColor:=false;
      xParent.fColor:=true;
      RotateLeft(xParent);
      w:=xParent.fRight;
     end;
     if not ((assigned(w.fLeft) and w.fLeft.fColor) or (assigned(w.fRight) and w.fRight.fColor)) then begin
      w.fColor:=true;
      x:=xParent;
      xParent:=xParent.fParent;
     end else begin
      if not (assigned(w.fRight) and w.fRight.fColor) then begin
       w.fLeft.fColor:=false;
       w.fColor:=true;
       RotateRight(w);
       w:=xParent.fRight;
      end;
      w.fColor:=xParent.fColor;
      xParent.fColor:=false;
      if assigned(w.fRight) then begin
       w.fRight.fColor:=false;
      end;
      RotateLeft(xParent);
      x:=fRoot;
     end;
    end else begin
     w:=xParent.fLeft;
     if w.fColor then begin
      w.fColor:=false;
      xParent.fColor:=true;
      RotateRight(xParent);
      w:=xParent.fLeft;
     end;
     if not ((assigned(w.fLeft) and w.fLeft.fColor) or (assigned(w.fRight) and w.fRight.fColor)) then begin
      w.fColor:=true;
      x:=xParent;
      xParent:=xParent.fParent;
     end else begin
      if not (assigned(w.fLeft) and w.fLeft.fColor) then begin
       w.fRight.fColor:=false;
       w.fColor:=true;
       RotateLeft(w);
       w:=xParent.fLeft;
      end;
      w.fColor:=xParent.fColor;
      xParent.fColor:=false;
      if assigned(w.fLeft) then begin
       w.fLeft.fColor:=false;
      end;
      RotateRight(xParent);
      x:=fRoot;
     end;
    end;
   end;
   if assigned(x) then begin
    x.fColor:=false;
   end;
  end;
  y.Clear;
  y.Free;
 end;
end;

procedure TVulkanDeviceMemoryChunkBlockRedBlackTree.Delete(const pKey:TVulkanDeviceMemoryChunkBlockRedBlackTreeKey);
var Node:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 Node:=Find(pKey);
 if assigned(Node) then begin
  Remove(Node);
 end;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTree.LeftMost:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) and assigned(result.fLeft) do begin
  result:=result.fLeft;
 end;
end;

function TVulkanDeviceMemoryChunkBlockRedBlackTree.RightMost:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) and assigned(result.fRight) do begin
  result:=result.fRight;
 end;
end;

constructor TVulkanDeviceMemoryChunkBlock.Create(const pMemoryChunk:TVulkanDeviceMemoryChunk;
                                                 const pOffset:TVkDeviceSize;
                                                 const pSize:TVkDeviceSize;
                                                 const pUsed:boolean);
begin
 inherited Create;
 fMemoryChunk:=pMemoryChunk;
 fOffset:=pOffset;
 fSize:=pSize;
 fUsed:=pUsed;
 fOffsetRedBlackTreeNode:=fMemoryChunk.fOffsetRedBlackTree.Insert(pOffset,self);
 if not fUsed then begin
  fSizeRedBlackTreeNode:=fMemoryChunk.fSizeRedBlackTree.Insert(pSize,self);
 end;
end;

destructor TVulkanDeviceMemoryChunkBlock.Destroy;
begin
 fMemoryChunk.fOffsetRedBlackTree.Remove(fOffsetRedBlackTreeNode);
 if not fUsed then begin
  fMemoryChunk.fSizeRedBlackTree.Remove(fSizeRedBlackTreeNode);
 end;
 inherited Destroy;
end;

procedure TVulkanDeviceMemoryChunkBlock.Update(const pOffset:TVkDeviceSize;
                                               const pSize:TVkDeviceSize;
                                               const pUsed:boolean);
begin
 if fOffset<>pOffset then begin
  fMemoryChunk.fOffsetRedBlackTree.Remove(fOffsetRedBlackTreeNode);
  fOffsetRedBlackTreeNode:=fMemoryChunk.fOffsetRedBlackTree.Insert(pOffset,self);
 end;
 if (fUsed<>pUsed) or (fSize<>pSize) then begin
  if not fUsed then begin
   fMemoryChunk.fSizeRedBlackTree.Remove(fSizeRedBlackTreeNode);
  end;
  if not pUsed then begin
   fSizeRedBlackTreeNode:=fMemoryChunk.fSizeRedBlackTree.Insert(pSize,self);
  end;
 end;
 fOffset:=pOffset;
 fSize:=pSize;
 fUsed:=pUsed;
 inherited Destroy;
end;

constructor TVulkanDeviceMemoryChunk.Create(const pMemoryManager:TVulkanDeviceMemoryManager;
                                            const pSize:TVkDeviceSize;
                                            const pAlignment:TVkDeviceSize;
                                            const pMemoryTypeBits:TVkUInt32;
                                            const pMemoryPropertyFlags:TVkMemoryPropertyFlags;
                                            const pMemoryChunkList:PVulkanDeviceMemoryManagerChunkList;
                                            const pMemoryHeapFlags:TVkMemoryHeapFlags=0);
var Index,HeapIndex:TVkInt32;
    MemoryAllocateInfo:TVkMemoryAllocateInfo;
    PhysicalDevice:TVulkanPhysicalDevice;
    CurrentSize,BestSize:TVkDeviceSize;
    Found:boolean;
begin
 inherited Create;

 fMemoryManager:=pMemoryManager;

 fSize:=pSize;

 fAlignment:=pAlignment;

 fMemoryChunkList:=pMemoryChunkList;

 fUsed:=0;

 fMappedOffset:=0;

 fMappedSize:=fSize;

 fMemoryPropertyFlags:=pMemoryPropertyFlags;

 fMemoryHandle:=VK_NULL_HANDLE;

 fMemory:=nil;

 fMemoryTypeIndex:=0;
 fMemoryTypeBits:=0;
 fMemoryHeapIndex:=0;
 PhysicalDevice:=fMemoryManager.fDevice.fPhysicalDevice;
 BestSize:=0;
 Found:=false;
 for Index:=0 to length(PhysicalDevice.fMemoryProperties.memoryTypes)-1 do begin
  if ((pMemoryTypeBits and (TVkUInt32(1) shl Index))<>0) and
     ((PhysicalDevice.fMemoryProperties.memoryTypes[Index].propertyFlags and pMemoryPropertyFlags)=pMemoryPropertyFlags) then begin
   HeapIndex:=PhysicalDevice.fMemoryProperties.memoryTypes[Index].heapIndex;
   CurrentSize:=PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].size;
   if ((PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].flags and pMemoryHeapFlags)=pMemoryHeapFlags) and
      (pSize<=CurrentSize) and (CurrentSize>BestSize) then begin
    BestSize:=CurrentSize;
    fMemoryTypeIndex:=Index;
    fMemoryTypeBits:=TVkUInt32(1) shl Index;
    fMemoryHeapIndex:=PhysicalDevice.fMemoryProperties.memoryTypes[Index].heapIndex;
    Found:=true;
   end;
  end;
 end;
 if not Found then begin
  raise EVulkanException.Create('No suitable device memory heap available');
 end;

 FillChar(MemoryAllocateInfo,SizeOf(TVkMemoryAllocateInfo),#0);
 MemoryAllocateInfo.sType:=VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
 MemoryAllocateInfo.pNext:=nil;
 MemoryAllocateInfo.allocationSize:=fSize;
 MemoryAllocateInfo.memoryTypeIndex:=fMemoryTypeIndex;

 HandleResultCode(fMemoryManager.fDevice.Commands.AllocateMemory(fMemoryManager.fDevice.fDeviceHandle,@MemoryAllocateInfo,fMemoryManager.fDevice.fAllocationCallbacks,@fMemoryHandle));

 fOffsetRedBlackTree:=TVulkanDeviceMemoryChunkBlockRedBlackTree.Create;
 fSizeRedBlackTree:=TVulkanDeviceMemoryChunkBlockRedBlackTree.Create;

 TVulkanDeviceMemoryChunkBlock.Create(self,0,pSize,false);

 fLock:=TCriticalSection.Create;

 if assigned(fMemoryChunkList^.First) then begin
  fMemoryChunkList^.First.fPreviousMemoryChunk:=self;
  fNextMemoryChunk:=fMemoryChunkList^.First;
 end else begin
  fMemoryChunkList^.Last:=self;
  fNextMemoryChunk:=nil;
 end;
 fMemoryChunkList^.First:=self;
 fPreviousMemoryChunk:=nil;

end;

destructor TVulkanDeviceMemoryChunk.Destroy;
begin

 if assigned(fOffsetRedBlackTree) then begin
  while assigned(fOffsetRedBlackTree.fRoot) do begin
   fOffsetRedBlackTree.fRoot.fValue.Free;
  end;
 end;

 if assigned(fPreviousMemoryChunk) then begin
  fPreviousMemoryChunk.fNextMemoryChunk:=fNextMemoryChunk;
 end else if fMemoryChunkList^.First=self then begin
  fMemoryChunkList^.First:=fNextMemoryChunk;
 end;
 if assigned(fNextMemoryChunk) then begin
  fNextMemoryChunk.fPreviousMemoryChunk:=fPreviousMemoryChunk;
 end else if fMemoryChunkList^.Last=self then begin
  fMemoryChunkList^.Last:=fPreviousMemoryChunk;
 end;

 if fMemoryHandle<>VK_NULL_HANDLE then begin
  if ((fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0) and assigned(fMemory) then begin
   fMemoryManager.fDevice.Commands.UnmapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle);
   fMemory:=nil;
  end;
  fMemoryManager.fDevice.Commands.FreeMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle,fMemoryManager.fDevice.fAllocationCallbacks);
 end;

 fOffsetRedBlackTree.Free;
 fSizeRedBlackTree.Free;

 FreeAndNil(fLock);

 fMemoryHandle:=VK_NULL_HANDLE;

 inherited Destroy;
end;

function TVulkanDeviceMemoryChunk.AllocateMemory(out pOffset:TVkDeviceSize;const pSize:TVkDeviceSize):boolean;
var Node,OtherNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock:TVulkanDeviceMemoryChunkBlock;
    TempOffset,TempSize,Size:TVkDeviceSize;
begin
 result:=false;

 fLock.Acquire;
 try

  Size:=pSize;

  // Ensure alignment
  if (fAlignment>1) and ((Size and (fAlignment-1))<>0) then begin
   inc(Size,fAlignment-(Size and (fAlignment-1)));
  end;

  // Best-fit search
  Node:=fSizeRedBlackTree.fRoot;
  while assigned(Node) do begin
   if Size<Node.fKey then begin
    if assigned(Node.fLeft) then begin
     // If free block is too big, then go to left
     Node:=Node.fLeft;
     continue;
    end else begin
     // If free block is too big and there is no left children node, then try to find suitable smaller but not to small free blocks
     while assigned(Node) and (Node.fKey>Size) do begin
      OtherNode:=Node.Predecessor;
      if assigned(OtherNode) and (OtherNode.fKey>=Size) then begin
       Node:=OtherNode;
      end else begin
       break;
      end;
     end;
     break;
    end;
   end else if Size>Node.fKey then begin
    if assigned(Node.fRight) then begin
     // If free block is too small, go to right
     Node:=Node.fRight;
     continue;
    end else begin
     // If free block is too small and there is no right children node, Try to find suitable bigger but not to small free blocks
     while assigned(Node) and (Node.fKey<Size) do begin
      OtherNode:=Node.Successor;
      if assigned(OtherNode) then begin
       Node:=OtherNode;
      end else begin
       break;
      end;
     end;
     break;
    end;
   end else begin
    // Perfect match
    break;
   end;
  end;

  if assigned(Node) and (Node.fKey>=Size) then begin
   MemoryChunkBlock:=Node.fValue;
   TempOffset:=MemoryChunkBlock.Offset;
   TempSize:=MemoryChunkBlock.Size;
   if TempSize=Size then begin
    MemoryChunkBlock.Update(MemoryChunkBlock.Offset,MemoryChunkBlock.Size,true);
   end else begin
    MemoryChunkBlock.Update(TempOffset,Size,true);
    TVulkanDeviceMemoryChunkBlock.Create(self,TempOffset+Size,TempSize-Size,false);
   end;
   pOffset:=TempOffset;
   inc(fUsed,Size);
   result:=true;
  end;

 finally
  fLock.Release;
 end;

end;

function TVulkanDeviceMemoryChunk.ReallocateMemory(var pOffset:TVkDeviceSize;const pSize:TVkDeviceSize):boolean;
var Node,OtherNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock,OtherMemoryChunkBlock:TVulkanDeviceMemoryChunkBlock;
    Size,TempOffset,TempSize:TVkDeviceSize;
begin
 result:=false;

 fLock.Acquire;
 try

  Size:=pSize;

  // Ensure alignment
  if (Size and (fAlignment-1))<>0 then begin
   inc(Size,fAlignment-(Size and (fAlignment-1)));
  end;

  Node:=fOffsetRedBlackTree.Find(pOffset);
  if assigned(Node) then begin
   MemoryChunkBlock:=Node.fValue;
   if MemoryChunkBlock.fUsed then begin
    dec(fUsed,MemoryChunkBlock.Size);
    if Size=0 then begin
     result:=FreeMemory(pOffset);
    end else if MemoryChunkBlock.fSize=Size then begin
     result:=true;
    end else begin
     if MemoryChunkBlock.fSize<Size then begin
      OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
      if assigned(OtherNode) and
         (MemoryChunkBlock.fOffsetRedBlackTreeNode<>OtherNode) then begin
       OtherMemoryChunkBlock:=OtherNode.fValue;
       if not OtherMemoryChunkBlock.fUsed then begin
        if (MemoryChunkBlock.fOffset+Size)<(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize) then begin
         MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,Size,true);
         OtherMemoryChunkBlock.Update(MemoryChunkBlock.fOffset+Size,(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-(MemoryChunkBlock.fOffset+Size),false);
         result:=true;
        end else if (MemoryChunkBlock.fOffset+Size)=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize) then begin
         MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,Size,true);
         OtherMemoryChunkBlock.Free;
         result:=true;
        end;
       end;
      end;
     end else if MemoryChunkBlock.fSize>Size then begin
      OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
      if assigned(OtherNode) and
         (MemoryChunkBlock.fOffsetRedBlackTreeNode<>OtherNode) and
         not OtherNode.fValue.fUsed then begin
       OtherMemoryChunkBlock:=OtherNode.fValue;
       TempOffset:=MemoryChunkBlock.fOffset+Size;
       TempSize:=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-TempOffset;
       MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,Size,true);
       OtherMemoryChunkBlock.Update(TempOffset,TempSize,false);
       result:=true;
      end else begin
       TempOffset:=MemoryChunkBlock.fOffset+Size;
       TempSize:=(MemoryChunkBlock.fOffset+MemoryChunkBlock.fSize)-TempOffset;
       MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,Size,true);
       TVulkanDeviceMemoryChunkBlock.Create(self,TempOffset,TempSize,false);
       result:=true;
      end;
     end;
    end;
    if result then begin
     inc(fUsed,Size);
    end;
   end;
  end;

 finally
  fLock.Release;
 end;

end;

function TVulkanDeviceMemoryChunk.FreeMemory(const pOffset:TVkDeviceSize):boolean;
var Node,OtherNode:TVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock,OtherMemoryChunkBlock:TVulkanDeviceMemoryChunkBlock;
    TempOffset,TempSize:TVkDeviceSize;
begin
 result:=false;

 fLock.Acquire;
 try

  Node:=fOffsetRedBlackTree.Find(pOffset);
  if assigned(Node) then begin

   MemoryChunkBlock:=Node.fValue;
   if MemoryChunkBlock.fUsed then begin

    dec(fUsed,MemoryChunkBlock.fSize);

    // Freeing including coalescing free blocks
    while assigned(Node) do begin

     // Coalescing previous free block with current block
     OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Predecessor;
     if assigned(OtherNode) and not OtherNode.fValue.fUsed then begin
      OtherMemoryChunkBlock:=OtherNode.fValue;
      TempOffset:=OtherMemoryChunkBlock.fOffset;
      TempSize:=(MemoryChunkBlock.fOffset+MemoryChunkBlock.fSize)-TempOffset;
      MemoryChunkBlock.Free;
      OtherMemoryChunkBlock.Update(TempOffset,TempSize,false);
      MemoryChunkBlock:=OtherMemoryChunkBlock;
      Node:=OtherNode;
      continue;
     end;

     // Coalescing current block with next free block
     OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
     if assigned(OtherNode) and not OtherNode.fValue.fUsed then begin
      OtherMemoryChunkBlock:=OtherNode.fValue;
      TempOffset:=MemoryChunkBlock.fOffset;
      TempSize:=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-TempOffset;
      OtherMemoryChunkBlock.Free;
      MemoryChunkBlock.Update(TempOffset,TempSize,false);
      continue;
     end;

     if MemoryChunkBlock.fUsed then begin
      // Mark block as free
      MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,MemoryChunkBlock.fSize,false);
     end;
     break;

    end;

    result:=true;
    
   end;

  end;
  
 finally
  fLock.Release;
 end;
end;

function TVulkanDeviceMemoryChunk.MapMemory(const pOffset:TVkDeviceSize=0;const pSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
begin
 result:=nil;
 fLock.Acquire;
 try
  if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
   if assigned(fMemory) then begin
    raise EVulkanException.Create('Memory is already mapped');
   end else begin
    fMappedOffset:=pOffset;
    fMappedSize:=pSize;
    HandleResultCode(fMemoryManager.fDevice.Commands.MapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle,pOffset,pSize,0,@result));
    fMemory:=result;
   end;
  end else begin
   raise EVulkanException.Create('Memory can''t mapped');
  end;
 finally
  fLock.Release;
 end;
end;

procedure TVulkanDeviceMemoryChunk.UnmapMemory;
begin
 fLock.Acquire;
 try
  if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
   if assigned(fMemory) then begin
    fMemoryManager.fDevice.Commands.UnmapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle);
    fMemory:=nil;
   end else begin
    raise EVulkanException.Create('Non-mapped memory can''t unmapped');
   end;
  end;
 finally
  fLock.Release;
 end;
end;

procedure TVulkanDeviceMemoryChunk.FlushMappedMemory;
var MappedMemoryRange:TVkMappedMemoryRange;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=fMappedOffset;
   MappedMemoryRange.size:=fMappedSize;
   HandleResultCode(vkFlushMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EVulkanException.Create('Non-mapped memory can''t be flushed');
  end;
 finally
  fLock.Release;
 end;
end;

procedure TVulkanDeviceMemoryChunk.InvalidateMappedMemory;
var MappedMemoryRange:TVkMappedMemoryRange;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=fMappedOffset;
   MappedMemoryRange.size:=fMappedSize;
   HandleResultCode(vkInvalidateMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EVulkanException.Create('Non-mapped memory can''t be invalidated');
  end;
 finally
  fLock.Release;
 end;
end;

constructor TVulkanDeviceMemoryBlock.Create(const pMemoryManager:TVulkanDeviceMemoryManager;
                                            const pMemoryChunk:TVulkanDeviceMemoryChunk;
                                            const pOffset:TVkDeviceSize;
                                            const pSize:TVkDeviceSize);
begin

 inherited Create;

 fMemoryManager:=pMemoryManager;

 fMemoryChunk:=pMemoryChunk;

 fOffset:=pOffset;

 fSize:=pSize;

 if assigned(fMemoryManager.fLastMemoryBlock) then begin
  fMemoryManager.fLastMemoryBlock.fNextMemoryBlock:=self;
  fPreviousMemoryBlock:=fMemoryManager.fLastMemoryBlock;
 end else begin
  fMemoryManager.fFirstMemoryBlock:=self;
  fPreviousMemoryBlock:=nil;
 end;
 fMemoryManager.fLastMemoryBlock:=self;
 fNextMemoryBlock:=nil;

end;

destructor TVulkanDeviceMemoryBlock.Destroy;
begin
 if assigned(fPreviousMemoryBlock) then begin
  fPreviousMemoryBlock.fNextMemoryBlock:=fNextMemoryBlock;
 end else if fMemoryManager.fFirstMemoryBlock=self then begin
  fMemoryManager.fFirstMemoryBlock:=fNextMemoryBlock;
 end;
 if assigned(fNextMemoryBlock) then begin
  fNextMemoryBlock.fPreviousMemoryBlock:=fPreviousMemoryBlock;
 end else if fMemoryManager.fLastMemoryBlock=self then begin
  fMemoryManager.fLastMemoryBlock:=fPreviousMemoryBlock;
 end;
 inherited Destroy;
end;

function TVulkanDeviceMemoryBlock.MapMemory(const pOffset:TVkDeviceSize=0;const pSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
var Offset,Size:TVkDeviceSize;
begin
 Offset:=fOffset+pOffset;
 if pSize=TVkDeviceSize(VK_WHOLE_SIZE) then begin
  Size:=TVkInt64(Max(0,TVkInt64((fOffset+fSize)-Offset)));
 end else begin
  Size:=Min(Max(pSize,0),TVkInt64(Max(0,TVkInt64((fOffset+fSize)-Offset))));
 end;
 result:=fMemoryChunk.MapMemory(Offset,Size);
end;

procedure TVulkanDeviceMemoryBlock.UnmapMemory;
begin
 fMemoryChunk.UnmapMemory;
end;

procedure TVulkanDeviceMemoryBlock.FlushMappedMemory;
begin
 fMemoryChunk.FlushMappedMemory;
end;

procedure TVulkanDeviceMemoryBlock.InvalidateMappedMemory;
begin
 fMemoryChunk.InvalidateMappedMemory;
end;

function TVulkanDeviceMemoryBlock.Fill(const pData:PVkVoid;const pSize:TVkDeviceSize):TVkDeviceSize;
var Memory:PVkVoid;
begin
 if pSize<=0 then begin
  result:=0;
 end else if pSize>fSize then begin
  result:=fSize;
 end else begin
  result:=pSize;
 end;
 Memory:=MapMemory;
 try
  Move(pData^,Memory^,result);
 finally
  UnmapMemory;
 end;
end;

constructor TVulkanDeviceMemoryManager.Create(const pDevice:TVulkanDevice);
begin
 inherited Create;

 fDevice:=pDevice;

 fLock:=TCriticalSection.Create;

 FillChar(fMemoryChunkLists,SizeOf(TVulkanDeviceMemoryManagerChunkLists),#0);

 fFirstMemoryBlock:=nil;
 fLastMemoryBlock:=nil;

end;

destructor TVulkanDeviceMemoryManager.Destroy;
var Index:TVkInt32;
    MemoryChunkList:PVulkanDeviceMemoryManagerChunkList;
begin
 while assigned(fFirstMemoryBlock) do begin
  fFirstMemoryBlock.Free;
 end;
 for Index:=low(TVulkanDeviceMemoryManagerChunkLists) to high(TVulkanDeviceMemoryManagerChunkLists) do begin
  MemoryChunkList:=@fMemoryChunkLists[Index];
  while assigned(MemoryChunkList^.First) do begin
   MemoryChunkList^.First.Free;
  end;
 enD;
 fLock.Free;
 inherited Destroy;
end;

function TVulkanDeviceMemoryManager.AllocateMemoryBlock(const pSize:TVkDeviceSize;
                                                        const pMemoryTypeBits:TVkUInt32;
                                                        const pMemoryPropertyFlags:TVkMemoryPropertyFlags;
                                                        const pAlignment:TVkDeviceSize=16;
                                                        const pOwnSingleMemoryChunk:boolean=false):TVulkanDeviceMemoryBlock;
var MemoryChunkList:PVulkanDeviceMemoryManagerChunkList;
    MemoryChunk:TVulkanDeviceMemoryChunk;
    Offset,Alignment:TVkDeviceSize;
begin

 result:=nil;

 if pSize=0 then begin
  raise EVulkanMemoryAllocation.Create('Can''t allocate zero-sized memory block');
 end;

 if pOwnSingleMemoryChunk then begin

  Alignment:=1;

  MemoryChunkList:=@fMemoryChunkLists[0];

  fLock.Acquire;
  try
   // Allocate a block inside a new chunk
   MemoryChunk:=TVulkanDeviceMemoryChunk.Create(self,pSize,Alignment,pMemoryTypeBits,pMemoryPropertyFlags,MemoryChunkList);
   if MemoryChunk.AllocateMemory(Offset,pSize) then begin
    result:=TVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,pSize);
   end;
  finally
   fLock.Release;
  end;

 end else begin

  Alignment:=pAlignment-1;
  Alignment:=Alignment or (Alignment shr 1);
  Alignment:=Alignment or (Alignment shr 2);
  Alignment:=Alignment or (Alignment shr 4);
  Alignment:=Alignment or (Alignment shr 8);
  Alignment:=Alignment or (Alignment shr 16);
  Alignment:=(Alignment or (Alignment shr 32))+1;

  MemoryChunkList:=@fMemoryChunkLists[CTZDWord(Alignment) and (high(TVulkanDeviceMemoryManagerChunkLists)-1)];

  fLock.Acquire;
  try

   // Try first to allocate a block inside already existent chunks
   MemoryChunk:=MemoryChunkList^.First;
   while assigned(MemoryChunk) do begin
    if ((pMemoryTypeBits and MemoryChunk.fMemoryTypeBits)<>0) and
       ((MemoryChunk.fMemoryPropertyFlags and pMemoryPropertyFlags)=pMemoryPropertyFlags) and
       ((MemoryChunk.fSize-MemoryChunk.fUsed)>=pSize) then begin
     if MemoryChunk.AllocateMemory(Offset,pSize) then begin
      result:=TVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,pSize);
      break;
     end;
    end;
    MemoryChunk:=MemoryChunk.fNextMemoryChunk;
   end;

   if not assigned(result) then begin
    // Otherwise allocate a block inside a new chunk
    MemoryChunk:=TVulkanDeviceMemoryChunk.Create(self,VulkanDeviceSizeRoundUpToPowerOfTwo(Max(1 shl 24,pSize shl 1)),Alignment,pMemoryTypeBits,pMemoryPropertyFlags,MemoryChunkList);
    if MemoryChunk.AllocateMemory(Offset,pSize) then begin
     result:=TVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,pSize);
    end;
   end;

  finally
   fLock.Release;
  end;

 end;

 if not assigned(result) then begin
  raise EVulkanMemoryAllocation.Create('Couldn''t allocate memory block');
 end;
 
end;

function TVulkanDeviceMemoryManager.FreeMemoryBlock(const pMemoryBlock:TVulkanDeviceMemoryBlock):boolean;
var MemoryChunk:TVulkanDeviceMemoryChunk;
begin
 result:=assigned(pMemoryBlock);
 if result then begin
  fLock.Acquire;
  try
   MemoryChunk:=pMemoryBlock.fMemoryChunk;
   result:=MemoryChunk.FreeMemory(pMemoryBlock.fOffset);
   if result then begin
    pMemoryBlock.Free;
    if assigned(MemoryChunk.fOffsetRedBlackTree.fRoot) and
       (MemoryChunk.fOffsetRedBlackTree.fRoot.fValue.fOffset=0) and
       (MemoryChunk.fOffsetRedBlackTree.fRoot.fValue.fSize=MemoryChunk.fSize) and
       not (assigned(MemoryChunk.fOffsetRedBlackTree.fRoot.fLeft) or assigned(MemoryChunk.fOffsetRedBlackTree.fRoot.fRight)) then begin
     MemoryChunk.Free;
    end;
   end;
  finally
   fLock.Release;
  end;
 end;
end;

constructor TVulkanBuffer.Create(const pDevice:TVulkanDevice;
                                 const pSize:TVkDeviceSize;
                                 const pUsage:TVkBufferUsageFlags;
                                 const pSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                                 const pQueueFamilyIndices:TVkUInt32List=nil;
                                 const pMemoryProperties:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
                                 const pOwnSingleMemoryChunk:boolean=false);
var Index:TVkInt32;
begin
 inherited Create;

 fDevice:=pDevice;

 fSize:=pSize;

 fMemoryProperties:=pMemoryProperties;

 fOwnSingleMemoryChunk:=pOwnSingleMemoryChunk;

 fBufferHandle:=VK_NULL_HANDLE;

 fMemoryBlock:=nil;

 fQueueFamilyIndices:=nil;
 if assigned(pQueueFamilyIndices) then begin
  fCountQueueFamilyIndices:=pQueueFamilyIndices.Count;
  SetLength(fQueueFamilyIndices,fCountQueueFamilyIndices);
  for Index:=0 to fCountQueueFamilyIndices-1 do begin
   fQueueFamilyIndices[Index]:=pQueueFamilyIndices.Items[Index];
  end;
 end else begin
  fCountQueueFamilyIndices:=0;
 end;

 FillChar(fBufferCreateInfo,SizeOf(TVkBufferCreateInfo),#0);
 fBufferCreateInfo.sType:=VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
 fBufferCreateInfo.size:=fSize;
 fBufferCreateInfo.usage:=pUsage;
 fBufferCreateInfo.sharingMode:=pSharingMode;
 if fCountQueueFamilyIndices>0 then begin
  fBufferCreateInfo.pQueueFamilyIndices:=@fQueueFamilyIndices[0];
  fBufferCreateInfo.queueFamilyIndexCount:=fCountQueueFamilyIndices;
 end;

 try

  HandleResultCode(fDevice.Commands.CreateBuffer(fDevice.fDeviceHandle,@fBufferCreateInfo,fDevice.fAllocationCallbacks,@fBufferHandle));

  fDevice.Commands.GetBufferMemoryRequirements(fDevice.fDeviceHandle,fBufferHandle,@fMemoryRequirements);

  fMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock(fMemoryRequirements.Size,
                                                           fMemoryRequirements.memoryTypeBits,
                                                           fMemoryProperties,
                                                           fMemoryRequirements.Alignment,
                                                           fOwnSingleMemoryChunk);
 except

  if fBufferHandle<>VK_NULL_HANDLE then begin
   fDevice.Commands.DestroyBuffer(fDevice.fDeviceHandle,fBufferHandle,fDevice.fAllocationCallbacks);
   fBufferHandle:=VK_NULL_HANDLE;
  end;

  if assigned(fMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
   fMemoryBlock:=nil;
  end;

  SetLength(fQueueFamilyIndices,0);

  raise;

 end;

end;

destructor TVulkanBuffer.Destroy;
begin
 if fBufferHandle<>VK_NULL_HANDLE then begin
  fDevice.Commands.DestroyBuffer(fDevice.fDeviceHandle,fBufferHandle,fDevice.fAllocationCallbacks);
  fBufferHandle:=VK_NULL_HANDLE;
 end;
 if assigned(fMemoryBlock) then begin
  fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
  fMemoryBlock:=nil;
 end;
 SetLength(fQueueFamilyIndices,0);
 inherited Destroy;
end;

procedure TVulkanBuffer.Bind;
begin
 HandleResultCode(fDevice.Commands.BindBufferMemory(fDevice.fDeviceHandle,fBufferHandle,fMemoryBlock.fMemoryChunk.fMemoryHandle,fMemoryBlock.fOffset));
end;

constructor TVulkanEvent.Create(const pDevice:TVulkanDevice;
                                const pFlags:TVkEventCreateFlags=TVkEventCreateFlags(0));
begin
 inherited Create;

 fDevice:=pDevice;

 fEventHandle:=VK_NULL_HANDLE;

 FillChar(fEventCreateInfo,SizeOf(TVkEventCreateInfo),#0);
 fEventCreateInfo.sType:=VK_STRUCTURE_TYPE_Event_CREATE_INFO;
 fEventCreateInfo.pNext:=nil;
 fEventCreateInfo.flags:=pFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateEvent(fDevice.fDeviceHandle,@fEventCreateInfo,fDevice.fAllocationCallbacks,@fEventHandle));

end;

destructor TVulkanEvent.Destroy;
begin
 if fEventHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyEvent(fDevice.fDeviceHandle,fEventHandle,fDevice.fAllocationCallbacks);
  fEventHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

function TVulkanEvent.GetStatus:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.GetEventStatus(fDevice.fDeviceHandle,fEventHandle);
end;

function TVulkanEvent.SetEvent:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.SetEvent(fDevice.fDeviceHandle,fEventHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

function TVulkanEvent.Reset:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.ResetEvent(fDevice.fDeviceHandle,fEventHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

constructor TVulkanFence.Create(const pDevice:TVulkanDevice;
                                const pFlags:TVkFenceCreateFlags=TVkFenceCreateFlags(0));
begin
 inherited Create;

 fDevice:=pDevice;

 fFenceHandle:=VK_NULL_HANDLE;

 FillChar(fFenceCreateInfo,SizeOf(TVkFenceCreateInfo),#0);
 fFenceCreateInfo.sType:=VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
 fFenceCreateInfo.pNext:=nil;
 fFenceCreateInfo.flags:=pFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateFence(fDevice.fDeviceHandle,@fFenceCreateInfo,fDevice.fAllocationCallbacks,@fFenceHandle));

end;

destructor TVulkanFence.Destroy;
begin
 if fFenceHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyFence(fDevice.fDeviceHandle,fFenceHandle,fDevice.fAllocationCallbacks);
  fFenceHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

function TVulkanFence.GetStatus:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.GetFenceStatus(fDevice.fDeviceHandle,fFenceHandle);
end;

function TVulkanFence.Reset:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.ResetFences(fDevice.fDeviceHandle,1,@fFenceHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

class function TVulkanFence.Reset(const pFences:array of TVulkanFence):TVkResult;
var Index:TVkInt32;
    Handles:array of TVkFence;
begin
 Handles:=nil;
 result:=VK_SUCCESS;
 if length(pFences)>0 then begin
  try
   SetLength(Handles,length(pFences));
   for Index:=0 to length(pFences)-1 do begin
    Handles[Index]:=pFences[Index].fFenceHandle;
   end;
   result:=pFences[0].fDevice.fDeviceVulkan.ResetFences(pFences[0].fDevice.fDeviceHandle,length(pFences),@Handles[0]);
  finally
   SetLength(Handles,0);
  end;
  if result<VK_SUCCESS then begin
   HandleResultCode(result);
  end;
 end;
end;

function TVulkanFence.WaitFor(const pTimeOut:TVkUInt64=TVKUInt64(TVKInt64(-1))):TVkResult;
begin
 result:=fDevice.fDeviceVulkan.WaitForFences(fDevice.fDeviceHandle,1,@fFenceHandle,VK_TRUE,pTimeOut);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

class function TVulkanFence.WaitFor(const pFences:array of TVulkanFence;const pWaitAll:boolean=true;const pTimeOut:TVkUInt64=TVKUInt64(TVKInt64(-1))):TVkResult;
var Index:TVkInt32;
    Handles:array of TVkFence;
begin
 Handles:=nil;
 result:=VK_SUCCESS;
 if length(pFences)>0 then begin
  try
   SetLength(Handles,length(pFences));
   for Index:=0 to length(pFences)-1 do begin
    Handles[Index]:=pFences[Index].fFenceHandle;
   end;
   if pWaitAll then begin
    result:=pFences[0].fDevice.fDeviceVulkan.WaitForFences(pFences[0].fDevice.fDeviceHandle,length(pFences),@Handles[0],VK_TRUE,pTimeOut);
   end else begin
    result:=pFences[0].fDevice.fDeviceVulkan.WaitForFences(pFences[0].fDevice.fDeviceHandle,length(pFences),@Handles[0],VK_FALSE,pTimeOut);
   end;
  finally
   SetLength(Handles,0);
  end;
  if result<VK_SUCCESS then begin
   HandleResultCode(result);
  end;
 end;
end;

constructor TVulkanSemaphore.Create(const pDevice:TVulkanDevice;
                                    const pFlags:TVkSemaphoreCreateFlags=TVkSemaphoreCreateFlags(0));
begin
 inherited Create;

 fDevice:=pDevice;

 fSemaphoreHandle:=VK_NULL_HANDLE;

 FillChar(fSemaphoreCreateInfo,SizeOf(TVkSemaphoreCreateInfo),#0);
 fSemaphoreCreateInfo.sType:=VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
 fSemaphoreCreateInfo.pNext:=nil;
 fSemaphoreCreateInfo.flags:=pFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateSemaphore(fDevice.fDeviceHandle,@fSemaphoreCreateInfo,fDevice.fAllocationCallbacks,@fSemaphoreHandle));

end;

destructor TVulkanSemaphore.Destroy;
begin
 if fSemaphoreHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroySemaphore(fDevice.fDeviceHandle,fSemaphoreHandle,fDevice.fAllocationCallbacks);
  fSemaphoreHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TVulkanQueue.Create(const pDevice:TVulkanDevice;
                                const pQueue:TVkQueue);
begin
 inherited Create;

 fDevice:=pDevice;

 fQueueHandle:=pQueue;

end;

destructor TVulkanQueue.Destroy;
begin
 inherited Destroy;
end;

procedure TVulkanQueue.Submit(const pSubmitCount:TVkUInt32;const pSubmits:PVkSubmitInfo;const pFence:TVulkanFence);
begin
 HandleResultCode(fDevice.fDeviceVulkan.QueueSubmit(fQueueHandle,pSubmitCount,pSubmits,pFence.fFenceHandle));
end;

procedure TVulkanQueue.BindSparse(const pBindInfoCount:TVkUInt32;const pBindInfo:PVkBindSparseInfo;const pFence:TVulkanFence);
begin
 HandleResultCode(fDevice.fDeviceVulkan.QueueBindSparse(fQueueHandle,pBindInfoCount,pBindInfo,pFence.fFenceHandle));
end;

procedure TVulkanQueue.WaitIdle;
begin
 HandleResultCode(fDevice.fDeviceVulkan.QueueWaitIdle(fQueueHandle));
end;

constructor TVulkanCommandPool.Create(const pDevice:TVulkanDevice;
                                      const pQueueFamilyIndex:TVkUInt32;
                                      const pFlags:TVkCommandPoolCreateFlags=TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
begin
 inherited Create;

 fDevice:=pDevice;

 fQueueFamilyIndex:=pQueueFamilyIndex;

 fFlags:=pFlags;

 fCommandPoolHandle:=VK_NULL_HANDLE;

 FillChar(fCommandPoolCreateInfo,SizeOf(TVkCommandPoolCreateInfo),#0);
 fCommandPoolCreateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
 fCommandPoolCreateInfo.queueFamilyIndex:=fQueueFamilyIndex;
 fCommandPoolCreateInfo.flags:=fFlags;
 HandleResultCode(fDevice.fDeviceVulkan.CreateCommandPool(fDevice.fDeviceHandle,@fCommandPoolCreateInfo,fDevice.fAllocationCallbacks,@fCommandPoolHandle));

end;

destructor TVulkanCommandPool.Destroy;
begin
 if fCommandPoolHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyCommandPool(fDevice.fDeviceHandle,fCommandPoolHandle,fDevice.fAllocationCallbacks);
  fCommandPoolHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TVulkanCommandBuffer.Create(const pCommandPool:TVulkanCommandPool;
                                        const pLevel:TVkCommandBufferLevel;
                                        const pCommandBufferHandle:TVkCommandBuffer);
begin

 fDevice:=pCommandPool.fDevice;

 fCommandPool:=pCommandPool;

 fLevel:=pLevel;

 fCommandBufferHandle:=pCommandBufferHandle;

{if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  fFence:=TVulkanFence.Create(fDevice);
 end else begin
  fFence:=nil;
 end;{}

end;

constructor TVulkanCommandBuffer.Create(const pCommandPool:TVulkanCommandPool;
                                        const pLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY);
var CommandBufferAllocateInfo:TVkCommandBufferAllocateInfo;
begin
 inherited Create;

 fDevice:=pCommandPool.fDevice;

 fCommandPool:=pCommandPool;

 fLevel:=pLevel;

 fCommandBufferHandle:=VK_NULL_HANDLE;

{if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  fFence:=TVulkanFence.Create(fDevice);
 end else begin
  fFence:=nil;
 end;{}

 FillChar(CommandBufferAllocateInfo,SizeOf(TVkCommandBufferAllocateInfo),#0);
 CommandBufferAllocateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
 CommandBufferAllocateInfo.commandPool:=fCommandPool.fCommandPoolHandle;
 CommandBufferAllocateInfo.level:=pLevel;
 CommandBufferAllocateInfo.commandBufferCount:=1;

 HandleResultCode(fDevice.fDeviceVulkan.AllocateCommandBuffers(fDevice.fDeviceHandle,@CommandBufferAllocateInfo,@fCommandBufferHandle));

end;

destructor TVulkanCommandBuffer.Destroy;
begin
 if fCommandBufferHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.FreeCommandBuffers(fDevice.fDeviceHandle,fCommandPool.fCommandPoolHandle,1,@fCommandBufferHandle);
  fCommandBufferHandle:=VK_NULL_HANDLE;
 end;
//FreeAndNil(fFence);
 inherited Destroy;
end;

class function TVulkanCommandBuffer.Allocate(const pCommandPool:TVulkanCommandPool;
                                             const pLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY;
                                             const pCommandBufferCount:TVkUInt32=1):TVulkanObjectList;
var Index:TVkInt32;
    CommandBufferHandles:array of TVkCommandBuffer;
    CommandBufferAllocateInfo:TVkCommandBufferAllocateInfo;
begin
 result:=nil;
 CommandBufferHandles:=nil;
 try
  SetLength(CommandBufferHandles,pCommandBufferCount);

  FillChar(CommandBufferAllocateInfo,SizeOf(TVkCommandBufferAllocateInfo),#0);
  CommandBufferAllocateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  CommandBufferAllocateInfo.commandPool:=pCommandPool.fCommandPoolHandle;
  CommandBufferAllocateInfo.level:=pLevel;
  CommandBufferAllocateInfo.commandBufferCount:=pCommandBufferCount;

  HandleResultCode(pCommandPool.fDevice.fDeviceVulkan.AllocateCommandBuffers(pCommandPool.fDevice.fDeviceHandle,@CommandBufferAllocateInfo,@CommandBufferHandles[0]));

  result:=TVulkanObjectList.Create;
  for Index:=0 to pCommandBufferCount-1 do begin
   result.Add(TVulkanCommandBuffer.Create(pCommandPool,pLevel,CommandBufferHandles[Index]));
  end;

 finally
  SetLength(CommandBufferHandles,0);
 end;
end;

procedure TVulkanCommandBuffer.BeginRecording(const pFlags:TVkCommandBufferUsageFlags=0;const pInheritanceInfo:PVkCommandBufferInheritanceInfo=nil);
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
begin
 FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
 CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
 CommandBufferBeginInfo.pNext:=nil;
 CommandBufferBeginInfo.flags:=pFlags;
 CommandBufferBeginInfo.pInheritanceInfo:=pInheritanceInfo;
 HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
end;

procedure TVulkanCommandBuffer.BeginRecordingPrimary;
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
  CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  CommandBufferBeginInfo.pNext:=nil;
  CommandBufferBeginInfo.flags:=0;
  CommandBufferBeginInfo.pInheritanceInfo:=nil;
  HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
 end else begin
  raise EVulkanException.Create('BeginRecordingPrimary called from a non-primary command buffer!');
 end;
end;

procedure TVulkanCommandBuffer.BeginRecordingSecondary(const pRenderPass:TVkRenderPass;const pSubPass:TVkUInt32;const pFrameBuffer:TVkFramebuffer;const pOcclusionQueryEnable:boolean;const pQueryFlags:TVkQueryControlFlags;const pPipelineStatistics:TVkQueryPipelineStatisticFlags);
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
    InheritanceInfo:TVkCommandBufferInheritanceInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_SECONDARY then begin
  FillChar(InheritanceInfo,SizeOf(TVkCommandBufferInheritanceInfo),#0);
  InheritanceInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
  InheritanceInfo.pNext:=nil;
  InheritanceInfo.renderPass:=pRenderPass;
  InheritanceInfo.subpass:=pSubPass;
  InheritanceInfo.framebuffer:=pFrameBuffer;
  if pOcclusionQueryEnable then begin
   InheritanceInfo.occlusionQueryEnable:=VK_TRUE;
  end else begin
   InheritanceInfo.occlusionQueryEnable:=VK_FALSE;
  end;
  InheritanceInfo.queryFlags:=pQueryFlags;
  InheritanceInfo.pipelineStatistics:=pPipelineStatistics;
  FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
  CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  CommandBufferBeginInfo.pNext:=nil;
  CommandBufferBeginInfo.flags:=TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT);
  CommandBufferBeginInfo.pInheritanceInfo:=@InheritanceInfo;
  HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
 end else begin
  raise EVulkanException.Create('BeginRecordingSecondary called from a non-secondary command buffer!');
 end;
end;

procedure TVulkanCommandBuffer.EndRecording;
begin
 HandleResultCode(fDevice.fDeviceVulkan.EndCommandBuffer(fCommandBufferHandle));
end;

procedure TVulkanCommandBuffer.Reset(const pFlags:TVkCommandBufferResetFlags=TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
begin
 HandleResultCode(fDevice.fDeviceVulkan.ResetCommandBuffer(fCommandBufferHandle,pFlags));
end;

procedure TVulkanCommandBuffer.CmdBindPipeline(pipelineBindPoint:TVkPipelineBindPoint;pipeline:TVkPipeline);
begin
 fDevice.fDeviceVulkan.CmdBindPipeline(fCommandBufferHandle,pipelineBindPoint,pipeline);
end;

procedure TVulkanCommandBuffer.CmdSetViewport(firstViewport:TVkUInt32;viewportCount:TVkUInt32;const pViewports:PVkViewport);
begin
 fDevice.fDeviceVulkan.CmdSetViewport(fCommandBufferHandle,firstViewport,viewportCount,pViewports);
end;

procedure TVulkanCommandBuffer.CmdSetScissor(firstScissor:TVkUInt32;scissorCount:TVkUInt32;const pScissors:PVkRect2D);
begin
 fDevice.fDeviceVulkan.CmdSetScissor(fCommandBufferHandle,firstScissor,scissorCount,pScissors);
end;

procedure TVulkanCommandBuffer.CmdSetLineWidth(lineWidth:TVkFloat);
begin
 fDevice.fDeviceVulkan.CmdSetLineWidth(fCommandBufferHandle,lineWidth);
end;

procedure TVulkanCommandBuffer.CmdSetDepthBias(depthBiasConstantFactor:TVkFloat;depthBiasClamp:TVkFloat;depthBiasSlopeFactor:TVkFloat);
begin
 fDevice.fDeviceVulkan.CmdSetDepthBias(fCommandBufferHandle,depthBiasConstantFactor,depthBiasClamp,depthBiasSlopeFactor);
end;

procedure TVulkanCommandBuffer.CmdSetBlendConstants(const blendConstants:TVkFloat);
begin
 fDevice.fDeviceVulkan.CmdSetBlendConstants(fCommandBufferHandle,blendConstants);
end;

procedure TVulkanCommandBuffer.CmdSetDepthBounds(minDepthBounds:TVkFloat;maxDepthBounds:TVkFloat);
begin
 fDevice.fDeviceVulkan.CmdSetDepthBounds(fCommandBufferHandle,minDepthBounds,maxDepthBounds);
end;

procedure TVulkanCommandBuffer.CmdSetStencilCompareMask(faceMask:TVkStencilFaceFlags;compareMask:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilCompareMask(fCommandBufferHandle,faceMask,compareMask);
end;

procedure TVulkanCommandBuffer.CmdSetStencilWriteMask(faceMask:TVkStencilFaceFlags;writeMask:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilWriteMask(fCommandBufferHandle,faceMask,writeMask);
end;

procedure TVulkanCommandBuffer.CmdSetStencilReference(faceMask:TVkStencilFaceFlags;reference:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilReference(fCommandBufferHandle,faceMask,reference);
end;

procedure TVulkanCommandBuffer.CmdBindDescriptorSets(pipelineBindPoint:TVkPipelineBindPoint;layout:TVkPipelineLayout;firstSet:TVkUInt32;descriptorSetCount:TVkUInt32;const pDescriptorSets:PVkDescriptorSet;dynamicOffsetCount:TVkUInt32;const pDynamicOffsets:PVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdBindDescriptorSets(fCommandBufferHandle,pipelineBindPoint,layout,firstSet,descriptorSetCount,pDescriptorSets,dynamicOffsetCount,pDynamicOffsets);
end;

procedure TVulkanCommandBuffer.CmdBindIndexBuffer(buffer:TVkBuffer;offset:TVkDeviceSize;indexType:TVkIndexType);
begin
 fDevice.fDeviceVulkan.CmdBindIndexBuffer(fCommandBufferHandle,buffer,offset,indexType);
end;

procedure TVulkanCommandBuffer.CmdBindVertexBuffers(firstBinding:TVkUInt32;bindingCount:TVkUInt32;const pBuffers:PVkBuffer;const pOffsets:PVkDeviceSize);
begin
 fDevice.fDeviceVulkan.CmdBindVertexBuffers(fCommandBufferHandle,firstBinding,bindingCount,pBuffers,pOffsets);
end;

procedure TVulkanCommandBuffer.CmdDraw(vertexCount:TVkUInt32;instanceCount:TVkUInt32;firstVertex:TVkUInt32;firstInstance:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdDraw(fCommandBufferHandle,vertexCount,instanceCount,firstVertex,firstInstance);
end;

procedure TVulkanCommandBuffer.CmdDrawIndexed(indexCount:TVkUInt32;instanceCount:TVkUInt32;firstIndex:TVkUInt32;vertexOffset:TVkInt32;firstInstance:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndexed(fCommandBufferHandle,indexCount,instanceCount,firstIndex,vertexOffset,firstInstance);
end;

procedure TVulkanCommandBuffer.CmdDrawIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TVkUInt32;stride:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndirect(fCommandBufferHandle,buffer,offset,drawCount,stride);
end;

procedure TVulkanCommandBuffer.CmdDrawIndexedIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TVkUInt32;stride:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndexedIndirect(fCommandBufferHandle,buffer,offset,drawCount,stride);
end;

procedure TVulkanCommandBuffer.CmdDispatch(x:TVkUInt32;y:TVkUInt32;z:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdDispatch(fCommandBufferHandle,x,y,z);
end;

procedure TVulkanCommandBuffer.CmdDispatchIndirect(buffer:TVkBuffer;offset:TVkDeviceSize);
begin
 fDevice.fDeviceVulkan.CmdDispatchIndirect(fCommandBufferHandle,buffer,offset);
end;

procedure TVulkanCommandBuffer.CmdCopyBuffer(srcBuffer:TVkBuffer;dstBuffer:TVkBuffer;regionCount:TVkUInt32;const pRegions:PVkBufferCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyBuffer(fCommandBufferHandle,srcBuffer,dstBuffer,regionCount,pRegions);
end;

procedure TVulkanCommandBuffer.CmdCopyImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,pRegions);
end;

procedure TVulkanCommandBuffer.CmdBlitImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageBlit;filter:TVkFilter);
begin
 fDevice.fDeviceVulkan.CmdBlitImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,pRegions,filter);
end;

procedure TVulkanCommandBuffer.CmdCopyBufferToImage(srcBuffer:TVkBuffer;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkBufferImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyBufferToImage(fCommandBufferHandle,srcBuffer,dstImage,dstImageLayout,regionCount,pRegions);
end;

procedure TVulkanCommandBuffer.CmdCopyImageToBuffer(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstBuffer:TVkBuffer;regionCount:TVkUInt32;const pRegions:PVkBufferImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyImageToBuffer(fCommandBufferHandle,srcImage,srcImageLayout,dstBuffer,regionCount,pRegions);
end;

procedure TVulkanCommandBuffer.CmdUpdateBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;dataSize:TVkDeviceSize;const pData:PVkVoid);
begin
 fDevice.fDeviceVulkan.CmdUpdateBuffer(fCommandBufferHandle,dstBuffer,dstOffset,dataSize,pData);
end;

procedure TVulkanCommandBuffer.CmdFillBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;size:TVkDeviceSize;data:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdFillBuffer(fCommandBufferHandle,dstBuffer,dstOffset,size,data);
end;

procedure TVulkanCommandBuffer.CmdClearColorImage(image:TVkImage;imageLayout:TVkImageLayout;const pColor:PVkClearColorValue;rangeCount:TVkUInt32;const pRanges:PVkImageSubresourceRange);
begin
 fDevice.fDeviceVulkan.CmdClearColorImage(fCommandBufferHandle,image,imageLayout,pColor,rangeCount,pRanges);
end;

procedure TVulkanCommandBuffer.CmdClearDepthStencilImage(image:TVkImage;imageLayout:TVkImageLayout;const pDepthStencil:PVkClearDepthStencilValue;rangeCount:TVkUInt32;const pRanges:PVkImageSubresourceRange);
begin
 fDevice.fDeviceVulkan.CmdClearDepthStencilImage(fCommandBufferHandle,image,imageLayout,pDepthStencil,rangeCount,pRanges);
end;

procedure TVulkanCommandBuffer.CmdClearAttachments(attachmentCount:TVkUInt32;const pAttachments:PVkClearAttachment;rectCount:TVkUInt32;const pRects:PVkClearRect);
begin
 fDevice.fDeviceVulkan.CmdClearAttachments(fCommandBufferHandle,attachmentCount,pAttachments,rectCount,pRects);
end;

procedure TVulkanCommandBuffer.CmdResolveImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TVkUInt32;const pRegions:PVkImageResolve);
begin
 fDevice.fDeviceVulkan.CmdResolveImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,pRegions);
end;

procedure TVulkanCommandBuffer.CmdSetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
begin
 fDevice.fDeviceVulkan.CmdSetEvent(fCommandBufferHandle,event,stageMask);
end;

procedure TVulkanCommandBuffer.CmdResetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
begin
 fDevice.fDeviceVulkan.CmdResetEvent(fCommandBufferHandle,event,stageMask);
end;

procedure TVulkanCommandBuffer.CmdWaitEvents(eventCount:TVkUInt32;const pEvents:PVkEvent;srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;memoryBarrierCount:TVkUInt32;const pMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TVkUInt32;const pBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TVkUInt32;const pImageMemoryBarriers:PVkImageMemoryBarrier);
begin
 fDevice.fDeviceVulkan.CmdWaitEvents(fCommandBufferHandle,eventCount,pEvents,srcStageMask,dstStageMask,memoryBarrierCount,pMemoryBarriers,bufferMemoryBarrierCount,pBufferMemoryBarriers,imageMemoryBarrierCount,pImageMemoryBarriers);
end;

procedure TVulkanCommandBuffer.CmdPipelineBarrier(srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;dependencyFlags:TVkDependencyFlags;memoryBarrierCount:TVkUInt32;const pMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TVkUInt32;const pBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TVkUInt32;const pImageMemoryBarriers:PVkImageMemoryBarrier);
begin
 fDevice.fDeviceVulkan.CmdPipelineBarrier(fCommandBufferHandle,srcStageMask,dstStageMask,dependencyFlags,memoryBarrierCount,pMemoryBarriers,bufferMemoryBarrierCount,pBufferMemoryBarriers,imageMemoryBarrierCount,pImageMemoryBarriers);
end;

procedure TVulkanCommandBuffer.CmdBeginQuery(queryPool:TVkQueryPool;query:TVkUInt32;flags:TVkQueryControlFlags);
begin
 fDevice.fDeviceVulkan.CmdBeginQuery(fCommandBufferHandle,queryPool,query,flags);
end;

procedure TVulkanCommandBuffer.CmdEndQuery(queryPool:TVkQueryPool;query:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdEndQuery(fCommandBufferHandle,queryPool,query);
end;

procedure TVulkanCommandBuffer.CmdResetQueryPool(queryPool:TVkQueryPool;firstQuery:TVkUInt32;queryCount:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdResetQueryPool(fCommandBufferHandle,queryPool,firstQuery,queryCount);
end;

procedure TVulkanCommandBuffer.CmdWriteTimestamp(pipelineStage:TVkPipelineStageFlagBits;queryPool:TVkQueryPool;query:TVkUInt32);
begin
 fDevice.fDeviceVulkan.CmdWriteTimestamp(fCommandBufferHandle,pipelineStage,queryPool,query);
end;

procedure TVulkanCommandBuffer.CmdCopyQueryPoolResults(queryPool:TVkQueryPool;firstQuery:TVkUInt32;queryCount:TVkUInt32;dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;stride:TVkDeviceSize;flags:TVkQueryResultFlags);
begin
 fDevice.fDeviceVulkan.CmdCopyQueryPoolResults(fCommandBufferHandle,queryPool,firstQuery,queryCount,dstBuffer,dstOffset,stride,flags);
end;

procedure TVulkanCommandBuffer.CmdPushConstants(layout:TVkPipelineLayout;stageFlags:TVkShaderStageFlags;offset:TVkUInt32;size:TVkUInt32;const pValues:PVkVoid);
begin
 fDevice.fDeviceVulkan.CmdPushConstants(fCommandBufferHandle,layout,stageFlags,offset,size,pValues);
end;

procedure TVulkanCommandBuffer.CmdBeginRenderPass(const pRenderPassBegin:PVkRenderPassBeginInfo;contents:TVkSubpassContents);
begin
 fDevice.fDeviceVulkan.CmdBeginRenderPass(fCommandBufferHandle,pRenderPassBegin,contents);
end;

procedure TVulkanCommandBuffer.CmdNextSubpass(contents:TVkSubpassContents);
begin
 fDevice.fDeviceVulkan.CmdNextSubpass(fCommandBufferHandle,contents);
end;

procedure TVulkanCommandBuffer.CmdEndRenderPass;
begin
 fDevice.fDeviceVulkan.CmdEndRenderPass(fCommandBufferHandle);
end;

procedure TVulkanCommandBuffer.CmdExecuteCommands(commandBufferCount:TVkUInt32;const pCommandBuffers:PVkCommandBuffer);
begin
 fDevice.fDeviceVulkan.CmdExecuteCommands(fCommandBufferHandle,commandBufferCount,pCommandBuffers);
end;

procedure TVulkanCommandBuffer.CmdExecute(const pCommandBuffer:TVulkanCommandBuffer);
begin
 CmdExecuteCommands(1,@pCommandBuffer.fCommandBufferHandle);
end;

procedure TVulkanCommandBuffer.MetaCmdPresentImageBarrier(const pImage:TVkImage);
var ImageMemoryBarrier:TVkImageMemoryBarrier;
begin
 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.pNext:=nil;
 ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
 ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
 ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
 ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
 ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.image:=pImage;
 ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
 ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
 ImageMemoryBarrier.subresourceRange.levelCount:=1;
 ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
 ImageMemoryBarrier.subresourceRange.layerCount:=1;
 CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_ALL_COMMANDS_BIT),TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                    0,
                    0,nil,
                    0,nil,
                    1,@ImageMemoryBarrier);
end;

procedure TVulkanCommandBuffer.Execute(const pQueue:TVulkanQueue;const pFence:TVulkanFence;const pFlags:TVkPipelineStageFlags;const pWaitSemaphore:TVulkanSemaphore=nil;const pSignalSemaphore:TVulkanSemaphore=nil);
var SubmitInfo:TVkSubmitInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin

  FillChar(SubmitInfo,SizeOf(TVkSubmitInfo),#0);
  SubmitInfo.sType:=VK_STRUCTURE_TYPE_SUBMIT_INFO;
  SubmitInfo.pNext:=nil;
  if assigned(pWaitSemaphore) then begin
   SubmitInfo.waitSemaphoreCount:=1;
   SubmitInfo.pWaitSemaphores:=@pWaitSemaphore.fSemaphoreHandle;
  end else begin
   SubmitInfo.waitSemaphoreCount:=0;
   SubmitInfo.pWaitSemaphores:=nil;
  end;
  SubmitInfo.pWaitDstStageMask:=@pFlags;
  SubmitInfo.commandBufferCount:=1;
  SubmitInfo.pCommandBuffers:=@fCommandBufferHandle;
  if assigned(pSignalSemaphore) then begin
   SubmitInfo.signalSemaphoreCount:=1;
   SubmitInfo.pSignalSemaphores:=@pSignalSemaphore.fSemaphoreHandle;
  end else begin
   SubmitInfo.signalSemaphoreCount:=0;
   SubmitInfo.pSignalSemaphores:=nil;
  end;

  pQueue.Submit(1,@Submitinfo,pFence);

  pFence.WaitFor;
  pFence.Reset;

  Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));

 end else begin
  raise EVulkanException.Create('Execute called from a non-primary command buffer!');
 end;
end;

constructor TVulkanRenderPass.Create(const pDevice:TVulkanDevice);
begin
 inherited Create;

 fDevice:=pDevice;

 fRenderPassHandle:=VK_NULL_HANDLE;

 fAttachmentDescriptions:=nil;
 fCountAttachmentDescriptions:=0;

 fAttachmentReferences:=nil;
 fCountAttachmentReferences:=0;

 fRenderPassSubpassDescriptions:=nil;
 fSubpassDescriptions:=nil;
 fCountSubpassDescriptions:=0;

 fSubpassDependencies:=nil;
 fCountSubpassDependencies:=0;

 fClearValues:=nil;

 FillChar(fRenderPassCreateInfo,Sizeof(TVkRenderPassCreateInfo),#0);
 fRenderPassCreateInfo.sType:=VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;

end;

destructor TVulkanRenderPass.Destroy;
begin
 if fRenderPassHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyRenderPass(fDevice.fDeviceHandle,fRenderPassHandle,fDevice.fAllocationCallbacks);
  fRenderPassHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fAttachmentDescriptions,0);
 SetLength(fAttachmentReferences,0);
 SetLength(fRenderPassSubpassDescriptions,0);
 SetLength(fSubpassDescriptions,0);
 SetLength(fSubpassDependencies,0);
 SetLength(fClearValues,0);
 inherited Destroy;
end;

function TVulkanRenderPass.GetClearValue(const Index:TVkUInt32):PVkClearValue;
begin
 result:=@fClearValues[Index];
end;

function TVulkanRenderPass.AddAttachmentDescription(const pFlags:TVkAttachmentDescriptionFlags;
                                                    const pFormat:TVkFormat;
                                                    const pSamples:TVkSampleCountFlagBits;
                                                    const pLoadOp:TVkAttachmentLoadOp;
                                                    const pStoreOp:TVkAttachmentStoreOp;
                                                    const pStencilLoadOp:TVkAttachmentLoadOp;
                                                    const pStencilStoreOp:TVkAttachmentStoreOp;
                                                    const pInitialLayout:TVkImageLayout;
                                                    const pFinalLayout:TVkImageLayout):TVkUInt32;
var AttachmentDescription:PVkAttachmentDescription;
begin
 result:=fCountAttachmentDescriptions;
 inc(fCountAttachmentDescriptions);
 if fCountAttachmentDescriptions>length(fAttachmentDescriptions) then begin
  SetLength(fAttachmentDescriptions,fCountAttachmentDescriptions*2);
 end;
 AttachmentDescription:=@fAttachmentDescriptions[result];
 AttachmentDescription^.flags:=pFlags;
 AttachmentDescription^.format:=pFormat;
 AttachmentDescription^.samples:=pSamples;
 AttachmentDescription^.loadOp:=pLoadOp;
 AttachmentDescription^.storeOp:=pStoreOp;
 AttachmentDescription^.stencilLoadOp:=pStencilLoadOp;
 AttachmentDescription^.stencilStoreOp:=pStencilStoreOp;
 AttachmentDescription^.initialLayout:=pInitialLayout;
 AttachmentDescription^.finalLayout:=pFinalLayout;
end;

function TVulkanRenderPass.AddAttachmentReference(const pAttachment:TVkUInt32;
                                                  const pLayout:TVkImageLayout):TVkUInt32;
var AttachmentReference:PVkAttachmentReference;
begin
 result:=fCountAttachmentReferences;
 inc(fCountAttachmentReferences);
 if fCountAttachmentReferences>length(fAttachmentReferences) then begin
  SetLength(fAttachmentReferences,fCountAttachmentReferences*2);
 end;
 AttachmentReference:=@fAttachmentReferences[result];
 AttachmentReference^.attachment:=pAttachment;
 AttachmentReference^.layout:=pLayout;
end;

function TVulkanRenderPass.AddSubpassDescription(const pFlags:TVkSubpassDescriptionFlags;
                                                 const pPipelineBindPoint:TVkPipelineBindPoint;
                                                 const pInputAttachments:array of TVkInt32;
                                                 const pColorAttachments:array of TVkInt32;
                                                 const pResolveAttachments:array of TVkInt32;
                                                 const pDepthStencilAttachment:TVkInt32;
                                                 const pPreserveAttachments:array of TVkUInt32):TVkUInt32;
var RenderPassSubpassDescription:PVulkanRenderPassSubpassDescription;
begin
 result:=fCountSubpassDescriptions;
 inc(fCountSubpassDescriptions);
 if fCountSubpassDescriptions>length(fRenderPassSubpassDescriptions) then begin
  SetLength(fRenderPassSubpassDescriptions,fCountSubpassDescriptions*2);
 end;
 RenderPassSubpassDescription:=@fRenderPassSubpassDescriptions[result];
 RenderPassSubpassDescription^.Flags:=pFlags;
 RenderPassSubpassDescription^.PipelineBindPoint:=pPipelineBindPoint;
 begin
  SetLength(RenderPassSubpassDescription^.InputAttachments,length(pInputAttachments));
  if length(pInputAttachments)>0 then begin
   Move(pInputAttachments[0],RenderPassSubpassDescription^.InputAttachments[0],length(pInputAttachments)*SizeOf(TVkInt32));
  end;
 end;
 begin
  SetLength(RenderPassSubpassDescription^.ColorAttachments,length(pColorAttachments));
  if length(pColorAttachments)>0 then begin
   Move(pColorAttachments[0],RenderPassSubpassDescription^.ColorAttachments[0],length(pColorAttachments)*SizeOf(TVkInt32));
  end;
 end;
 begin
  SetLength(RenderPassSubpassDescription^.ResolveAttachments,length(pResolveAttachments));
  if length(pResolveAttachments)>0 then begin
   Move(pResolveAttachments[0],RenderPassSubpassDescription^.ResolveAttachments[0],length(pResolveAttachments)*SizeOf(TVkInt32));
  end;
 end;
 RenderPassSubpassDescription^.DepthStencilAttachment:=pDepthStencilAttachment;
 begin
  SetLength(RenderPassSubpassDescription^.PreserveAttachments,length(pPreserveAttachments));
  if length(pPreserveAttachments)>0 then begin
   Move(pPreserveAttachments[0],RenderPassSubpassDescription^.PreserveAttachments[0],length(pPreserveAttachments)*SizeOf(TVkUInt32));
  end;
 end;
end;

function TVulkanRenderPass.AddSubpassDependency(const pSrcSubpass:TVkUInt32;
                                                const pDstSubpass:TVkUInt32;
                                                const pSrcStageMask:TVkPipelineStageFlags;
                                                const pDstStageMask:TVkPipelineStageFlags;
                                                const pSrcAccessMask:TVkAccessFlags;
                                                const pDstAccessMask:TVkAccessFlags;
                                                const pDependencyFlags:TVkDependencyFlags):TVkUInt32;
var SubpassDependency:PVkSubpassDependency;
begin
 result:=fCountSubpassDependencies;
 inc(fCountSubpassDependencies);
 if fCountSubpassDependencies>length(fSubpassDependencies) then begin
  SetLength(fSubpassDependencies,fCountSubpassDependencies*2);
 end;
 SubpassDependency:=@fSubpassDependencies[result];
 SubpassDependency^.srcSubpass:=pSrcSubpass;
 SubpassDependency^.dstSubpass:=pDstSubpass;
 SubpassDependency^.srcStageMask:=pSrcStageMask;
 SubpassDependency^.dstStageMask:=pDstStageMask;
 SubpassDependency^.srcAccessMask:=pSrcAccessMask;
 SubpassDependency^.dstAccessMask:=pDstAccessMask;
 SubpassDependency^.DependencyFlags:=pDependencyFlags;
end;

procedure TVulkanRenderPass.Initialize;
var Index,SubIndex:TVkInt32;
    AttachmentDescription:PVkAttachmentDescription;
    SubpassDescription:PVkSubpassDescription;
    RenderPassSubpassDescription:PVulkanRenderPassSubpassDescription;
    ClearValue:PVkClearValue;
begin
 SetLength(fAttachmentDescriptions,fCountAttachmentDescriptions);
 SetLength(fAttachmentReferences,fCountAttachmentReferences);
 SetLength(fRenderPassSubpassDescriptions,fCountSubpassDescriptions);
 SetLength(fSubpassDescriptions,fCountSubpassDescriptions);
 SetLength(fSubpassDependencies,fCountSubpassDependencies);

 SetLength(fClearValues,fCountAttachmentDescriptions);

 if fCountAttachmentDescriptions>0 then begin
  for Index:=0 to fCountAttachmentDescriptions-1 do begin
   AttachmentDescription:=@fAttachmentDescriptions[Index];
   ClearValue:=@fClearValues[Index];
   case AttachmentDescription^.format of
    VK_FORMAT_D32_SFLOAT_S8_UINT,
    VK_FORMAT_D32_SFLOAT,
    VK_FORMAT_D24_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM:begin
     ClearValue^.depthStencil.depth:=1.0;
     ClearValue^.depthStencil.stencil:=0;
    end;
    else begin
     ClearValue^.color.uint32[0]:=0;
     ClearValue^.color.uint32[1]:=0;
     ClearValue^.color.uint32[2]:=0;
     ClearValue^.color.uint32[3]:=0;
    end;
   end;
  end;
  fRenderPassCreateInfo.attachmentCount:=fCountAttachmentDescriptions;
  fRenderPassCreateInfo.pAttachments:=@fAttachmentDescriptions[0];
 end;

 if fCountSubpassDescriptions>0 then begin
  for Index:=0 to fCountSubpassDescriptions-1 do begin
   SubpassDescription:=@fSubpassDescriptions[Index];
   RenderPassSubpassDescription:=@fRenderPassSubpassDescriptions[Index];
   FillChar(SubpassDescription^,SizeOf(TVkSubpassDescription),#0);
   SubpassDescription^.flags:=RenderPassSubpassDescription^.Flags;
   SubpassDescription^.pipelineBindPoint:=RenderPassSubpassDescription^.PipelineBindPoint;
   begin
    SubpassDescription^.inputAttachmentCount:=length(RenderPassSubpassDescription^.InputAttachments);
    if SubpassDescription^.inputAttachmentCount>0 then begin
     SetLength(RenderPassSubpassDescription^.pInputAttachments,SubpassDescription^.inputAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.InputAttachments)-1 do begin
      RenderPassSubpassDescription^.pInputAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.InputAttachments[SubIndex]];
     end;
     SubpassDescription^.pInputAttachments:=@RenderPassSubpassDescription^.pInputAttachments[0];
    end;
   end;
   begin
    SubpassDescription^.ColorAttachmentCount:=length(RenderPassSubpassDescription^.ColorAttachments);
    if SubpassDescription^.ColorAttachmentCount>0 then begin
     SetLength(RenderPassSubpassDescription^.pColorAttachments,SubpassDescription^.ColorAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.ColorAttachments)-1 do begin
      RenderPassSubpassDescription^.pColorAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.ColorAttachments[SubIndex]];
     end;
     SubpassDescription^.pColorAttachments:=@RenderPassSubpassDescription^.pColorAttachments[0];
    end;
   end;
   begin
    if (SubpassDescription^.ColorAttachmentCount>0) and
       (SubpassDescription^.ColorAttachmentCount=TVkUInt32(length(RenderPassSubpassDescription^.ResolveAttachments))) then begin
     SetLength(RenderPassSubpassDescription^.pResolveAttachments,SubpassDescription^.ColorAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.ResolveAttachments)-1 do begin
      RenderPassSubpassDescription^.pResolveAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.ResolveAttachments[SubIndex]];
     end;
     SubpassDescription^.pResolveAttachments:=@RenderPassSubpassDescription^.pResolveAttachments[0];
    end;
   end;
   if RenderPassSubpassDescription^.DepthStencilAttachment>=0 then begin
    SubpassDescription^.pDepthStencilAttachment:=@fAttachmentReferences[RenderPassSubpassDescription^.DepthStencilAttachment];
   end;
   begin
    SubpassDescription^.PreserveAttachmentCount:=length(RenderPassSubpassDescription^.PreserveAttachments);
    if SubpassDescription^.PreserveAttachmentCount>0 then begin
     SubpassDescription^.pPreserveAttachments:=@RenderPassSubpassDescription^.PreserveAttachments[0];
    end;
   end;
  end;
  fRenderPassCreateInfo.subpassCount:=fCountSubpassDescriptions;
  fRenderPassCreateInfo.pSubpasses:=@fSubpassDescriptions[0];
 end;

 if fCountSubpassDependencies>0 then begin
  fRenderPassCreateInfo.dependencyCount:=fCountSubpassDependencies;
  fRenderPassCreateInfo.pDependencies:=@fSubpassDependencies[0];
 end;
 
 HandleResultCode(fDevice.fDeviceVulkan.CreateRenderPass(fDevice.fDeviceHandle,@fRenderPassCreateInfo,fDevice.fAllocationCallbacks,@fRenderPassHandle));

end;

procedure TVulkanRenderPass.BeginRenderpass(const pCommandBuffer:TVulkanCommandBuffer;
                                            const pFrameBuffer:TVkFrameBuffer;
                                            const pSubpassContents:TVkSubpassContents;
                                            const pOffsetX,pOffsetY,pWidth,pHeight:TVkUInt32);
var RenderPassBeginInfo:TVkRenderPassBeginInfo;
begin
 FillChar(RenderPassBeginInfo,SizeOf(TVkRenderPassBeginInfo),#0);
 RenderPassBeginInfo.sType:=VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
 RenderPassBeginInfo.renderPass:=fRenderPassHandle;
 RenderPassBeginInfo.framebuffer:=pFrameBuffer;
 RenderPassBeginInfo.renderArea.offset.x:=pOffsetX;
 RenderPassBeginInfo.renderArea.offset.y:=pOffsetY;
 RenderPassBeginInfo.renderArea.extent.width:=pWidth;
 RenderPassBeginInfo.renderArea.extent.height:=pHeight;
 RenderPassBeginInfo.clearValueCount:=length(fClearValues);
 if RenderPassBeginInfo.clearValueCount>0 then begin
  RenderPassBeginInfo.pClearValues:=@fClearValues[0];
 end;
 pCommandBuffer.CmdBeginRenderPass(@RenderPassBeginInfo,pSubpassContents);
end;

procedure TVulkanRenderPass.EndRenderpass(const pCommandBuffer:TVulkanCommandBuffer);
begin
 pCommandBuffer.CmdEndRenderPass;
end;

constructor TVulkanSwapChain.Create(const pDevice:TVulkanDevice;
                                    const pCommandBuffer:TVulkanCommandBuffer;
                                    const pCommandBufferFence:TVulkanFence;
                                    const pOldSwapChain:TVulkanSwapChain=nil;
                                    const pDesiredImageWidth:TVkUInt32=0;
                                    const pDesiredImageHeight:TVkUInt32=0;
                                    const pDesiredImageCount:TVkUInt32=2;
                                    const pImageArrayLayers:TVkUInt32=1;
                                    const pImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                                    const pImageColorSpace:TVkColorSpaceKHR=VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
                                    const pImageUsage:TVkImageUsageFlags=TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
                                    const pImageSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                                    const pDepthImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                                    const pDepthImageFormatWithStencil:boolean=false;
                                    const pQueueFamilyIndices:TVkUInt32List=nil;
                                    const pCompositeAlpha:TVkCompositeAlphaFlagBitsKHR=VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
                                    const pPresentMode:TVkPresentModeKHR=VK_PRESENT_MODE_MAILBOX_KHR;
                                    const pClipped:boolean=true;
                                    const pDesiredTransform:TVkSurfaceTransformFlagsKHR=TVkSurfaceTransformFlagsKHR($ffffffff));
var Index:TVkInt32;
    SwapChainImageCount:TVkUInt32;
    SurfaceCapabilities:TVkSurfaceCapabilitiesKHR;
    SurfacePresetModes:TVkPresentModeKHRArray;
    SurfaceFormat:TVkSurfaceFormatKHR;
    SwapChainImages:array of TVkImage;
    SwapChainBuffer:PVulkanSwapChainBuffer;
    ImageCreateInfo:TVkImageCreateInfo;
    ImageViewCreateInfo:TVkImageViewCreateInfo;
    Attachments:array[0..1] of TVkImageView;
    FramebufferCreateInfo:TVkFramebufferCreateInfo;
    FormatProperties:TVkFormatProperties;
    MemoryRequirements:TVkMemoryRequirements;
begin
 inherited Create;

 fDevice:=pDevice;

 fSwapChainHandle:=VK_NULL_HANDLE;

 fQueueFamilyIndices:=nil;

 fSwapChainBuffers:=nil;

 fFrameBuffers:=nil;

 fCurrentBuffer:=0;

 fDepthImage:=VK_NULL_HANDLE;

 fDepthMemoryBlock:=nil;

 fDepthImageView:=VK_NULL_HANDLE;

 fRenderPass:=nil;

 fWidth:=0;

 fHeight:=0;

 try

  if assigned(pQueueFamilyIndices) then begin
   fCountQueueFamilyIndices:=pQueueFamilyIndices.Count;
   SetLength(fQueueFamilyIndices,fCountQueueFamilyIndices);
   for Index:=0 to fCountQueueFamilyIndices-1 do begin
    fQueueFamilyIndices[Index]:=pQueueFamilyIndices.Items[Index];
   end;
  end else begin
   fCountQueueFamilyIndices:=0;
  end;

  SurfaceCapabilities:=fDevice.fPhysicalDevice.GetSurfaceCapabilities(fDevice.fSurface);

  FillChar(fSwapChainCreateInfo,SizeOf(TVkSwapChainCreateInfoKHR),#0);
  fSwapChainCreateInfo.sType:=VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;

  fSwapChainCreateInfo.surface:=fDevice.fSurface.fSurfaceHandle;

  if SurfaceCapabilities.minImageCount>pDesiredImageCount then begin
   fSwapChainCreateInfo.minImageCount:=SurfaceCapabilities.minImageCount;
  end else if (SurfaceCapabilities.maxImageCount<>0) and
              (SurfaceCapabilities.maxImageCount<pDesiredImageCount) then begin
   fSwapChainCreateInfo.minImageCount:=SurfaceCapabilities.maxImageCount;
  end else begin
   fSwapChainCreateInfo.minImageCount:=pDesiredImageCount;
  end;

  if pImageFormat=VK_FORMAT_UNDEFINED then begin
   SurfaceFormat:=fDevice.fPhysicalDevice.GetSurfaceFormat(fDevice.fSurface);
   fSwapChainCreateInfo.imageFormat:=SurfaceFormat.format;
   fSwapChainCreateInfo.imageColorSpace:=SurfaceFormat.colorSpace;
  end else begin
   fSwapChainCreateInfo.imageFormat:=pImageFormat;
   fSwapChainCreateInfo.imageColorSpace:=pImageColorSpace;
  end;

  fDevice.fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fDevice.fPhysicalDevice.fPhysicalDeviceHandle,fSwapChainCreateInfo.imageFormat,@FormatProperties);
  if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT))=0 then begin
   raise EVulkanException.Create('No suitable color image format!');
  end;

  if ((pDesiredImageWidth<>0) and (pDesiredImageHeight<>0)) or
     ((TVkInt32(SurfaceCapabilities.CurrentExtent.Width)<0) or (TVkInt32(SurfaceCapabilities.CurrentExtent.Height)<0)) then begin
   fSwapChainCreateInfo.imageExtent.width:=Min(Max(pDesiredImageWidth,SurfaceCapabilities.minImageExtent.width),SurfaceCapabilities.maxImageExtent.width);
   fSwapChainCreateInfo.imageExtent.height:=Min(Max(pDesiredImageHeight,SurfaceCapabilities.minImageExtent.height),SurfaceCapabilities.maxImageExtent.height);
  end else begin
   fSwapChainCreateInfo.imageExtent:=SurfaceCapabilities.CurrentExtent;
  end;

  fWidth:=fSwapChainCreateInfo.imageExtent.width;

  fHeight:=fSwapChainCreateInfo.imageExtent.height;

  fSwapChainCreateInfo.imageArrayLayers:=pImageArrayLayers;
  fSwapChainCreateInfo.imageUsage:=pImageUsage;
  fSwapChainCreateInfo.imageSharingMode:=pImageSharingMode;

  if fDepthImageFormat=VK_FORMAT_UNDEFINED then begin
   fDepthImageFormat:=fDevice.fPhysicalDevice.GetBestSupportedDepthFormat(pDepthImageFormatWithStencil);
  end else begin
   fDepthImageFormat:=pDepthImageFormat;
  end;

  fDevice.fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fDevice.fPhysicalDevice.fPhysicalDeviceHandle,fDepthImageFormat,@FormatProperties);
  if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))=0 then begin
   raise EVulkanException.Create('No suitable depth image format!');
  end;

  if fCountQueueFamilyIndices>0 then begin
   fSwapChainCreateInfo.pQueueFamilyIndices:=@fQueueFamilyIndices[0];
   fSwapChainCreateInfo.queueFamilyIndexCount:=fCountQueueFamilyIndices;
  end;

  if (pDesiredTransform<>TVkSurfaceTransformFlagsKHR($ffffffff)) and
     ((SurfaceCapabilities.SupportedTransforms and pDesiredTransform)<>0) then begin
   fSwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(pDesiredTransform);
  end else if (SurfaceCapabilities.SupportedTransforms and TVkSurfaceTransformFlagsKHR(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR))<>0 then begin
   fSwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR);
  end else begin
   fSwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(SurfaceCapabilities.currentTransform);
  end;

  fSwapChainCreateInfo.compositeAlpha:=pCompositeAlpha;

  SurfacePresetModes:=nil;
  try
   SurfacePresetModes:=fDevice.fPhysicalDevice.GetSurfacePresentModes(fDevice.fSurface);
   fSwapChainCreateInfo.presentMode:=VK_PRESENT_MODE_FIFO_KHR;
   for Index:=0 to length(SurfacePresetModes)-1 do begin
    if SurfacePresetModes[Index]=pPresentMode then begin
     fSwapChainCreateInfo.presentMode:=pPresentMode;
     break;
    end;
   end;
  finally
   SetLength(SurfacePresetModes,0);
  end;

  if pClipped then begin
   fSwapChainCreateInfo.clipped:=VK_TRUE;
  end else begin
   fSwapChainCreateInfo.clipped:=VK_FALSE;
  end;

  if assigned(pOldSwapChain) then begin
   fSwapChainCreateInfo.oldSwapchain:=pOldSwapChain.fSwapChainHandle;
  end else begin
   fSwapChainCreateInfo.oldSwapchain:=VK_NULL_HANDLE;
  end;

  HandleResultCode(fDevice.fDeviceVulkan.CreateSwapChainKHR(fDevice.fDeviceHandle,@fSwapChainCreateInfo,fDevice.fAllocationCallbacks,@fSwapChainHandle));

  HandleResultCode(fDevice.fDeviceVulkan.GetSwapchainImagesKHR(fDevice.fDeviceHandle,fSwapChainHandle,@SwapChainImageCount,nil));

  SwapChainImages:=nil;
  try
   SetLength(SwapChainImages,SwapChainImageCount);

   HandleResultCode(fDevice.fDeviceVulkan.GetSwapchainImagesKHR(fDevice.fDeviceHandle,fSwapChainHandle,@SwapChainImageCount,@SwapChainImages[0]));

   SetLength(fSwapChainBuffers,SwapChainImageCount);

   for Index:=0 to SwapChainImageCount-1 do begin
    SwapChainBuffer:=@fSwapChainBuffers[Index];
    SwapChainBuffer^.Image:=VK_NULL_HANDLE;
    SwapChainBuffer^.ImageView:=VK_NULL_HANDLE;
   end;

   for Index:=0 to SwapChainImageCount-1 do begin
    SwapChainBuffer:=@fSwapChainBuffers[Index];
    SwapChainBuffer^.Image:=SwapChainImages[Index];

    FillChar(ImageViewCreateInfo,SizeOf(TVkImageViewCreateInfo),#0);
    ImageViewCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    ImageViewCreateInfo.pNext:=nil;
    ImageViewCreateInfo.flags:=0;
    ImageViewCreateInfo.image:=SwapChainImages[Index];
    ImageViewCreateInfo.viewType:=VK_IMAGE_VIEW_TYPE_2D;
    ImageViewCreateInfo.format:=fSwapChainCreateInfo.imageFormat;
    ImageViewCreateInfo.components.r:=VK_COMPONENT_SWIZZLE_R;
    ImageViewCreateInfo.components.g:=VK_COMPONENT_SWIZZLE_G;
    ImageViewCreateInfo.components.b:=VK_COMPONENT_SWIZZLE_B;
    ImageViewCreateInfo.components.a:=VK_COMPONENT_SWIZZLE_A;
    ImageViewCreateInfo.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
    ImageViewCreateInfo.subresourceRange.baseMipLevel:=0;
    ImageViewCreateInfo.subresourceRange.levelCount:=1;
    ImageViewCreateInfo.subresourceRange.baseArrayLayer:=0;
    ImageViewCreateInfo.subresourceRange.layerCount:=1;

    HandleResultCode(fDevice.fDeviceVulkan.CreateImageView(fDevice.fDeviceHandle,@ImageViewCreateInfo,fDevice.fAllocationCallbacks,@SwapChainBuffer^.ImageView));

   end;

  finally
   SetLength(SwapChainImages,0);
  end;

  begin

   FillChar(ImageCreateInfo,SizeOf(TVkImageCreateInfo),#0);
   ImageCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
   ImageCreateInfo.pNext:=nil;
   ImageCreateInfo.flags:=0;
   ImageCreateInfo.imageType:=VK_IMAGE_TYPE_2D;
   ImageCreateInfo.format:=fDepthImageFormat;
   ImageCreateInfo.extent.width:=fSwapChainCreateInfo.imageExtent.width;
   ImageCreateInfo.extent.height:=fSwapChainCreateInfo.imageExtent.height;
   ImageCreateInfo.extent.depth:=1;
   ImageCreateInfo.mipLevels:=1;
   ImageCreateInfo.arrayLayers:=1;
   ImageCreateInfo.samples:=VK_SAMPLE_COUNT_1_BIT;
   ImageCreateInfo.tiling:=VK_IMAGE_TILING_OPTIMAL;
   ImageCreateInfo.usage:=TVkImageUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT);
   ImageCreateInfo.sharingMode:=VK_SHARING_MODE_EXCLUSIVE;
   ImageCreateInfo.queueFamilyIndexCount:=0;
   ImageCreateInfo.pQueueFamilyIndices:=nil;
   ImageCreateInfo.initialLayout:=VK_IMAGE_LAYOUT_UNDEFINED;

   HandleResultCode(fDevice.fDeviceVulkan.CreateImage(fDevice.fDeviceHandle,@ImageCreateInfo,fDevice.fAllocationCallbacks,@fDepthImage));

   FillChar(ImageViewCreateInfo,SizeOf(TVkImageViewCreateInfo),#0);
   ImageViewCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
   ImageViewCreateInfo.pNext:=nil;
   ImageViewCreateInfo.flags:=0;
   ImageViewCreateInfo.image:=fDepthImage;
   ImageViewCreateInfo.viewType:=VK_IMAGE_VIEW_TYPE_2D;
   ImageViewCreateInfo.format:=fDepthImageFormat;
   ImageViewCreateInfo.components.r:=VK_COMPONENT_SWIZZLE_R;
   ImageViewCreateInfo.components.g:=VK_COMPONENT_SWIZZLE_G;
   ImageViewCreateInfo.components.b:=VK_COMPONENT_SWIZZLE_B;
   ImageViewCreateInfo.components.a:=VK_COMPONENT_SWIZZLE_A;
   if fDepthImageFormat in [VK_FORMAT_D32_SFLOAT_S8_UINT,VK_FORMAT_D24_UNORM_S8_UINT,VK_FORMAT_D16_UNORM_S8_UINT] then begin
    ImageViewCreateInfo.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT) or TVkImageAspectFlags(VK_IMAGE_ASPECT_STENCIL_BIT);
   end else begin
    ImageViewCreateInfo.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
   end;
   ImageViewCreateInfo.subresourceRange.baseMipLevel:=0;
   ImageViewCreateInfo.subresourceRange.levelCount:=1;
   ImageViewCreateInfo.subresourceRange.baseArrayLayer:=0;
   ImageViewCreateInfo.subresourceRange.layerCount:=1;

   fDevice.fDeviceVulkan.GetImageMemoryRequirements(fDevice.fDeviceHandle,fDepthImage,@MemoryRequirements);

   fDepthMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock(MemoryRequirements.size,
                                                                 MemoryRequirements.memoryTypeBits,
                                                                 TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                                 MemoryRequirements.alignment);
   if not assigned(fDepthMemoryBlock) then begin
    raise EVulkanMemoryAllocation.Create('Memory for depth image couldn''t be allocated!');
   end;

   HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,fDepthImage,fDepthMemoryBlock.fMemoryChunk.fMemoryHandle,fDepthMemoryBlock.fOffset));

   VulkanSetImageLayout(fDepthImage,
                        ImageViewCreateInfo.subresourceRange.aspectMask,
                        VK_IMAGE_LAYOUT_UNDEFINED,
                        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                        nil,
                        pCommandBuffer,
                        fDevice,
                        fDevice.fGraphicQueue,
                        pCommandBufferFence,
                        true);

   HandleResultCode(fDevice.fDeviceVulkan.CreateImageView(fDevice.fDeviceHandle,@ImageViewCreateInfo,fDevice.fAllocationCallbacks,@fDepthImageView));

  end;

  begin

   fRenderPass:=TVulkanRenderPass.Create(fDevice);

   fRenderPass.AddSubpassDescription(0,
                                     VK_PIPELINE_BIND_POINT_GRAPHICS,
                                     [],
                                     [fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                              fSwapChainCreateInfo.imageFormat,
                                                                                                              VK_SAMPLE_COUNT_1_BIT,
                                                                                                              VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                              VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                              VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                              VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                              VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                                                                                              VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                                                             ),
                                                                         VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                        )],
                                     [],
                                     fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                             fDepthImageformat,
                                                                                                             VK_SAMPLE_COUNT_1_BIT,
                                                                                                             VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                             VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                             VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                             VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                             VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                                                                                             VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                                                            ),
                                                                        VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                       ),
                                     []);

   fRenderPass.Initialize;
                                     
  end;

  FillChar(FramebufferCreateInfo,SizeOf(TVkFramebufferCreateInfo),#0);
  FramebufferCreateInfo.sType:=VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
  FramebufferCreateInfo.pNext:=nil;
  FramebufferCreateInfo.flags:=0;
  FramebufferCreateInfo.renderPass:=fRenderPass.fRenderPassHandle;
  FramebufferCreateInfo.attachmentCount:=2;
  FramebufferCreateInfo.pAttachments:=@Attachments[0];
  FramebufferCreateInfo.width:=fSwapChainCreateInfo.imageExtent.width;
  FramebufferCreateInfo.height:=fSwapChainCreateInfo.imageExtent.height;
  FramebufferCreateInfo.layers:=1;

  SetLength(fFrameBuffers,SwapChainImageCount);
  for Index:=0 to SwapChainImageCount-1 do begin
   fFrameBuffers[Index]:=VK_NULL_HANDLE;
  end;
  for Index:=0 to SwapChainImageCount-1 do begin
   Attachments[0]:=fSwapChainBuffers[Index].ImageView;
   Attachments[1]:=fDepthImageView;
   HandleResultCode(fDevice.fDeviceVulkan.CreateFramebuffer(fDevice.fDeviceHandle,@FramebufferCreateInfo,fDevice.fAllocationCallbacks,@fFrameBuffers[Index]));
  end;

 except

  for Index:=0 to length(fFramebuffers)-1 do begin
   if fFrameBuffers[Index]<>VK_NULL_HANDLE then begin
    fDevice.fDeviceVulkan.DestroyFramebuffer(fDevice.fDeviceHandle,fFrameBuffers[Index],fDevice.fAllocationCallbacks);
    fFrameBuffers[Index]:=VK_NULL_HANDLE;
   end;
  end;

  FreeAndNil(fRenderPass);

  if fDepthImageView<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,fDepthImageView,fDevice.fAllocationCallbacks);
   fDepthImageView:=VK_NULL_HANDLE;
  end;

  if fDepthImage<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyImage(fDevice.fDeviceHandle,fDepthImage,fDevice.fAllocationCallbacks);
   fDepthImage:=VK_NULL_HANDLE;
  end;

  for Index:=0 to length(fSwapChainBuffers)-1 do begin
   SwapChainBuffer:=@fSwapChainBuffers[Index];
   if SwapChainBuffer^.ImageView<>VK_NULL_HANDLE then begin
    fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,SwapChainBuffer^.ImageView,fDevice.fAllocationCallbacks);
    SwapChainBuffer^.ImageView:=VK_NULL_HANDLE;
   end;
  end;

  if fSwapChainHandle<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroySwapChainKHR(fDevice.fDeviceHandle,fSwapChainHandle,fDevice.fAllocationCallbacks);
   fSwapChainHandle:=VK_NULL_HANDLE;
  end;

  if assigned(fDepthMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fDepthMemoryBlock);
   fDepthMemoryBlock:=nil;
  end;

  SetLength(fQueueFamilyIndices,0);

  SetLength(fSwapChainBuffers,0);

  SetLength(fFrameBuffers,0);

  raise;

 end;
end;

destructor TVulkanSwapChain.Destroy;
var Index:TVkInt32;
    SwapChainBuffer:PVulkanSwapChainBuffer;
begin

 for Index:=0 to length(fFramebuffers)-1 do begin
  if fFrameBuffers[Index]<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyFramebuffer(fDevice.fDeviceHandle,fFrameBuffers[Index],fDevice.fAllocationCallbacks);
   fFrameBuffers[Index]:=VK_NULL_HANDLE;
  end;
 end;

 FreeAndNil(fRenderPass);

 if fDepthImageView<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,fDepthImageView,fDevice.fAllocationCallbacks);
  fDepthImageView:=VK_NULL_HANDLE;
 end;

 if fDepthImage<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyImage(fDevice.fDeviceHandle,fDepthImage,fDevice.fAllocationCallbacks);
  fDepthImage:=VK_NULL_HANDLE;
 end;

 for Index:=0 to length(fSwapChainBuffers)-1 do begin
  SwapChainBuffer:=@fSwapChainBuffers[Index];
  if SwapChainBuffer^.ImageView<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,SwapChainBuffer^.ImageView,fDevice.fAllocationCallbacks);
   SwapChainBuffer^.ImageView:=VK_NULL_HANDLE;
  end;
 end;

 if fSwapChainHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroySwapChainKHR(fDevice.fDeviceHandle,fSwapChainHandle,fDevice.fAllocationCallbacks);
  fSwapChainHandle:=VK_NULL_HANDLE;
 end;

 if assigned(fDepthMemoryBlock) then begin
  fDevice.fMemoryManager.FreeMemoryBlock(fDepthMemoryBlock);
  fDepthMemoryBlock:=nil;
 end;

 SetLength(fQueueFamilyIndices,0);
 SetLength(fSwapChainBuffers,0);
 SetLength(fFrameBuffers,0);

 inherited Destroy;
end;

procedure TVulkanSwapChain.QueuePresent(const pQueue:TVulkanQueue;const pSemaphore:TVulkanSemaphore=nil);
var PresentInfo:TVkPresentInfoKHR;
begin
 FillChar(PresentInfo,SizeOf(TVkPresentInfoKHR),#0);
 PresentInfo.sType:=VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
 PresentInfo.swapchainCount:=1;
 PresentInfo.pSwapchains:=@fSwapChainHandle;
 PresentInfo.pImageIndices:=@fCurrentBuffer;
 if assigned(pSemaphore) then begin
  PresentInfo.waitSemaphoreCount:=1;
  PresentInfo.pWaitSemaphores:=@pSemaphore.fSemaphoreHandle;
 end;                             
 HandleResultCode(fDevice.fInstance.fInstanceVulkan.QueuePresentKHR(pQueue.fQueueHandle,@PresentInfo));
end;

function TVulkanSwapChain.AcquireNextImage(const pSemaphore:TVulkanSemaphore=nil;const pFence:TVulkanFence=nil;const pTimeOut:TVkUInt64=TVkUInt64(high(TVkUInt64))):TVkResult;
var SemaphoreHandle:TVkFence;
    FenceHandle:TVkFence;
begin
 if assigned(pSemaphore) then begin
  SemaphoreHandle:=pSemaphore.fSemaphoreHandle;
 end else begin
  SemaphoreHandle:=VK_NULL_HANDLE;
 end;
 if assigned(pFence) then begin
  FenceHandle:=pFence.fFenceHandle;
 end else begin
  FenceHandle:=VK_NULL_HANDLE;
 end;
 if assigned(pFence) then begin
  FenceHandle:=pFence.fFenceHandle;
 end else begin
  FenceHandle:=VK_NULL_HANDLE;
 end;
 result:=fDevice.fDeviceVulkan.AcquireNextImageKHR(fDevice.fDeviceHandle,fSwapChainHandle,pTimeOut,SemaphoreHandle,FenceHandle,@fCurrentBuffer);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

function TVulkanSwapChain.GetCurrentImage:TVkImage;
begin
 result:=fSwapChainBuffers[fCurrentBuffer].Image;
end;

function TVulkanSwapChain.GetCurrentFrameBuffer:TVkFrameBuffer;
begin
 result:=fFrameBuffers[fCurrentBuffer];
end;

constructor TVulkanFrameBufferAttachment.Create(const pDevice:TVulkanDevice;
                                                const pCommandBuffer:TVulkanCommandBuffer;
                                                const pCommandBufferFence:TVulkanFence;
                                                const pWidth:TVkUInt32;
                                                const pHeight:TVkUInt32;
                                                const pFormat:TVkFormat;
                                                const pUsage:TVkBufferUsageFlags);
var ImageCreateInfo:TVkImageCreateInfo;
    ImageViewCreateInfo:TVkImageViewCreateInfo;
    MemoryRequirements:TVkMemoryRequirements;
    AspectMask:TVkImageAspectFlags;
    ImageLayout:TVkImageLayout;
begin
 inherited Create;

 fDevice:=pDevice;

 fWidth:=pWidth;

 fHeight:=pHeight;

 fFormat:=pFormat;

 fImage:=VK_NULL_HANDLE;

 fImageView:=VK_NULL_HANDLE;

 fMemoryBlock:=nil;

 if (pUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT))<>0 then begin
  AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  ImageLayout:=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
 end else if (pUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
  if fFormat in [VK_FORMAT_D32_SFLOAT_S8_UINT,VK_FORMAT_D24_UNORM_S8_UINT,VK_FORMAT_D16_UNORM_S8_UINT] then begin
   AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT) or TVkImageAspectFlags(VK_IMAGE_ASPECT_STENCIL_BIT);
  end else begin
   AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  end;
  ImageLayout:=VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
 end else begin
  raise EVulkanException.Create('Invalid frame buffer attachment');
 end;

//fMemoryBlock:TVulkanDeviceMemoryBlock;
 try

  FillChar(ImageCreateInfo,SizeOf(TVkImageCreateInfo),#0);
  ImageCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
  ImageCreateInfo.pNext:=nil;
  ImageCreateInfo.flags:=0;
  ImageCreateInfo.imageType:=VK_IMAGE_TYPE_2D;
  ImageCreateInfo.format:=fFormat;
  ImageCreateInfo.extent.width:=pWidth;
  ImageCreateInfo.extent.height:=pHeight;
  ImageCreateInfo.extent.depth:=1;
  ImageCreateInfo.mipLevels:=1;
  ImageCreateInfo.arrayLayers:=1;
  ImageCreateInfo.samples:=VK_SAMPLE_COUNT_1_BIT;
  ImageCreateInfo.tiling:=VK_IMAGE_TILING_OPTIMAL;
  ImageCreateInfo.usage:=TVkImageUsageFlags(pUsage) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT);
  ImageCreateInfo.sharingMode:=VK_SHARING_MODE_EXCLUSIVE;
  ImageCreateInfo.queueFamilyIndexCount:=0;
  ImageCreateInfo.pQueueFamilyIndices:=nil;
  ImageCreateInfo.initialLayout:=VK_IMAGE_LAYOUT_UNDEFINED;

  HandleResultCode(fDevice.fDeviceVulkan.CreateImage(fDevice.fDeviceHandle,@ImageCreateInfo,fDevice.fAllocationCallbacks,@Image));

  FillChar(ImageViewCreateInfo,SizeOf(TVkImageViewCreateInfo),#0);
  ImageViewCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
  ImageViewCreateInfo.pNext:=nil;
  ImageViewCreateInfo.flags:=0;
  ImageViewCreateInfo.image:=fImage;
  ImageViewCreateInfo.viewType:=VK_IMAGE_VIEW_TYPE_2D;
  ImageViewCreateInfo.format:=fFormat;
  ImageViewCreateInfo.components.r:=VK_COMPONENT_SWIZZLE_R;
  ImageViewCreateInfo.components.g:=VK_COMPONENT_SWIZZLE_G;
  ImageViewCreateInfo.components.b:=VK_COMPONENT_SWIZZLE_B;
  ImageViewCreateInfo.components.a:=VK_COMPONENT_SWIZZLE_A;
  ImageViewCreateInfo.subresourceRange.aspectMask:=AspectMask;
  ImageViewCreateInfo.subresourceRange.baseMipLevel:=0;
  ImageViewCreateInfo.subresourceRange.levelCount:=1;
  ImageViewCreateInfo.subresourceRange.baseArrayLayer:=0;
  ImageViewCreateInfo.subresourceRange.layerCount:=1;

  fDevice.fDeviceVulkan.GetImageMemoryRequirements(fDevice.fDeviceHandle,fImage,@MemoryRequirements);

  fMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock(MemoryRequirements.size,
                                                           MemoryRequirements.memoryTypeBits,
                                                           TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                           MemoryRequirements.alignment);
  if not assigned(fMemoryBlock) then begin
   raise EVulkanMemoryAllocation.Create('Memory for frame buffer attachment couldn''t be allocated!');
  end;

  HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,fImage,fMemoryBlock.fMemoryChunk.fMemoryHandle,fMemoryBlock.fOffset));

  if (pUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT))<>0 then begin
   VulkanSetImageLayout(fImage,
                        ImageViewCreateInfo.subresourceRange.aspectMask,
                        VK_IMAGE_LAYOUT_UNDEFINED,
                        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                        nil,
                        pCommandBuffer,
                        fDevice,
                        fDevice.fGraphicQueue,
                        pCommandBufferFence,
                        true);
  end else begin
   VulkanSetImageLayout(fImage,
                        ImageViewCreateInfo.subresourceRange.aspectMask,
                        VK_IMAGE_LAYOUT_UNDEFINED,
                        ImageLayout,
                        nil,
                        pCommandBuffer,
                        fDevice,
                        fDevice.fGraphicQueue,
                        pCommandBufferFence,
                        true);
  end;

  HandleResultCode(fDevice.fDeviceVulkan.CreateImageView(fDevice.fDeviceHandle,@ImageViewCreateInfo,fDevice.fAllocationCallbacks,@fImageView));

 except

  if fImageView<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,fImageView,fDevice.fAllocationCallbacks);
   fImageView:=VK_NULL_HANDLE;
  end;

  if fImage<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroyImage(fDevice.fDeviceHandle,fImage,fDevice.fAllocationCallbacks);
   fImage:=VK_NULL_HANDLE;
  end;

  if assigned(fMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
   fMemoryBlock:=nil;
  end;

  raise;

 end;
end;

destructor TVulkanFrameBufferAttachment.Destroy;
begin

 if fImageView<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,fImageView,fDevice.fAllocationCallbacks);
  fImageView:=VK_NULL_HANDLE;
 end;

 if fImage<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyImage(fDevice.fDeviceHandle,fImage,fDevice.fAllocationCallbacks);
  fImage:=VK_NULL_HANDLE;
 end;

 if assigned(fMemoryBlock) then begin
  fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
  fMemoryBlock:=nil;
 end;

 inherited Destroy;
end;

end.

