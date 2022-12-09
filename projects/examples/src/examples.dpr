// DO NOT EDIT THIS FILE, EVEN NOT AS A FILE IN YOUR PROJECT !
// Because the PasVulkan-own project manager will overwrite it on most each operation  
{$ifdef fpc}
 {$ifdef android}
  {$define fpcandroid}
 {$endif}
{$endif}
{$ifdef fpcandroid}library{$else}program{$endif} examples;
{$ifdef fpc}
 {$mode delphi}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$if defined(win32) or defined(win64)}
 {$if defined(Debug) or not defined(Release)}
  {$apptype console}
 {$else}
  {$apptype gui}
 {$ifend}
 {$define Windows}
{$ifend}

(*{$if defined(fpc) and defined(Unix)}
   cthreads,
   BaseUnix,
  {$elseif defined(Windows)}
   Windows,
  {$ifend}*)

uses
  {$if defined(fpc) and defined(Unix)}
   cthreads,
   BaseUnix,
  {$elseif defined(Windows)}
   {$ifdef PasVulkanUseFastMM4}
    FastMM4,
   {$endif} 
   Windows,
  {$ifend}
  SysUtils,
  Classes,
  Vulkan,
  PasVulkan.Types,
  PasVulkan.Android,
{$if defined(PasVulkanUseSDL2)}
  PasVulkan.SDL2,
{$ifend}
  PasVulkan.Framework,
  PasVulkan.Application,  
  UnitApplication;

// {$if defined(fpc) and defined(android)}

{$if defined(fpc) and defined(android)}
function DumpExceptionCallStack(e:Exception):string;
var i:int32;
    Frames:PPointer;
begin
 result:='Program exception! '+LineEnding+'Stack trace:'+LineEnding+LineEnding;
 if assigned(e) then begin
  result:=result+'Exception class: '+e.ClassName+LineEnding+'Message: '+E.Message+LineEnding;
 end;
 result:=result+BackTraceStrFunc(ExceptAddr);
 Frames:=ExceptFrames;
 for i:=0 to ExceptFrameCount-1 do begin
  result:=result+LineEnding+BackTraceStrFunc(Frames);
  inc(Frames);
 end;
end;
{$ifend}

{$if defined(PasVulkanUseSDL2)}
{$if defined(fpc) and defined(android)}
procedure SDL_main(argc:TpvInt32;arcv:pointer); cdecl;
var s:string;
{$else}
procedure SDLMain;
{$ifend}
begin
{$if defined(fpc) and defined(android)}
 AndroidJavaEnv:=SDL_AndroidGetJNIEnv;
 AndroidJavaClass:=nil;
 AndroidJavaObject:=nil;
 AndroidDeviceName:=TpvUTF8String(AndroidGetDeviceName);
 //SDL_Android_Init(pJavaEnv,pJavaClass);
{$ifend}
{$if (defined(fpc) and defined(android)) and not defined(Release)}
 __android_log_write(ANDROID_LOG_VERBOSE,ApplicationTag,'Entering SDL_main . . .');
{$ifend}
{$if defined(fpc) and defined(android)}
 try
  AndroidGetAssetManager;
  try
{$ifend}  
  TApplication.Main;
{$if defined(fpc) and defined(android)}
  finally
   AndroidReleaseAssetManager;
  end; 
 except
  on e:Exception do begin
   s:=DumpExceptionCallStack(e);
   __android_log_write(ANDROID_LOG_FATAL,ApplicationTag,PAnsiChar(AnsiString(s)));
   SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR,ApplicationTag,PAnsiChar(AnsiString(s)),nil);
   raise;
  end;
 end;
{$ifend}
{$if (defined(fpc) and defined(android)) and not defined(Release)}
 __android_log_write(ANDROID_LOG_VERBOSE,ApplicationTag,'Leaving SDL_main . . .');
{$ifend}
{$if defined(fpc) and defined(android)}
 SDL_Quit;
{$ifend}
end;
{$ifend}

{$if defined(fpc) and defined(android)}
{$if defined(PasVulkanUseSDL2)}
exports JNI_OnLoad name 'JNI_OnLoad',
        JNI_OnUnload name 'JNI_OnUnload',
        SDL_main name 'SDL_main';
{$else}
procedure ANativeActivity_onCreate(aActivity:PANativeActivity;aSavedState:pointer;aSavedStateSize:TpvUint32); cdecl;
begin
 Android_ANativeActivity_onCreate(aActivity,aSavedState,aSavedStateSize,TApplication);
end;

exports ANativeActivity_onCreate name 'ANativeActivity_onCreate';
{$ifend}
{$ifend}

{$if defined(fpc) and defined(Windows)}
function IsDebuggerPresent:longbool; stdcall; external 'kernel32.dll' name 'IsDebuggerPresent';
{$ifend}

{$if defined(Windows)}
function AttachConsole(dwProcessId:DWord):Bool; stdcall; external 'kernel32.dll';

const ATTACH_PARENT_PROCESS=DWORD(-1);
{$ifend}

{$if not (defined(fpc) and defined(android))}
begin
{$if defined(Windows) and (defined(Debug) or not defined(Release))}
 // Workaround for a random-console-missing-issue with Delphi 10.2 Tokyo
 if (GetStdHandle(STD_OUTPUT_HANDLE)=0) and not AttachConsole(ATTACH_PARENT_PROCESS) then begin
  AllocConsole;
 end;
{$ifend}
{$if defined(PasVulkanUseSDL2)}
 SDLMain;
{$else}
 TApplication.Main;
{$ifend}
{$if defined(Windows) and (defined(Debug) or not defined(Release))}
 if {$ifdef fpc}IsDebuggerPresent{$else}DebugHook<>0{$endif} then begin
  writeln('Press return to exit . . . ');
  readln;
 end;
{$ifend}
{$if defined(PasVulkanUseSDL2)}
 SDL_Quit;
{$ifend}
{$if defined(fpc) and defined(Linux)}
 // Workaround for a segv-exception-issue with closed-source NVidia drivers on Linux at program exit
 fpkill(fpgetpid,9);
{$ifend}
{$ifend}
end.
