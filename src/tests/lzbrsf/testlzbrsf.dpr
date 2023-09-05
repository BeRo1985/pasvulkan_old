program testlzbrsf;
{$ifdef fpc}
 {$mode delphi}
{$endif}
{$if defined(Win32) or defined(Win64)}
 {$define Windows}
 {$apptype console}
{$endif}

(*{$ifdef Unix}
      cthreads,
     {$endif}*)

uses SysUtils,
     Classes,
     Math,
     PasVulkan.Types,
     PasVulkan.Compression.LZBRSF;

procedure TestLZBRSFCompress;
var InputFileStream:TFileStream;
    OutputFileStream:TFileStream;
    CompressedSize:TpvUInt64;
    UncompressedSize:TpvUInt64;
    CompressedData:Pointer;
    UncompressedData:Pointer;
begin

 Write('Compressing... ');

 InputFileStream:=TFileStream.Create('input.dat',fmOpenRead {or fmShareDenyNone});
 try
  UncompressedSize:=InputFileStream.Size;
  GetMem(UncompressedData,InputFileStream.Size);
  InputFileStream.ReadBuffer(UncompressedData^,InputFileStream.Size);
 finally
  FreeAndNil(InputFileStream);
 end;

 if LZBRSFCompress(UncompressedData,UncompressedSize,CompressedData,CompressedSize,TpvLZBRSFLevel(5)) then begin
 
  OutputFileStream:=TFileStream.Create('output.dat',fmCreate);
  try
   OutputFileStream.WriteBuffer(CompressedData^,CompressedSize);
  finally
   FreeAndNil(OutputFileStream);
  end;

  FreeMem(CompressedData);
  CompressedData:=nil;
  
 end; 

 FreeMem(UncompressedData);
 UncompressedData:=nil;

 WriteLn('done!');

end;

procedure TestLZBRSFDecompress;
var InputFileStream:TFileStream;
    OutputFileStream:TFileStream;
    CompressedSize:TpvUInt64;
    UncompressedSize:TpvUInt64;
    CompressedData:Pointer;
    UncompressedData:Pointer;
begin

 Write('Decompressing... ');
 
 InputFileStream:=TFileStream.Create('output.dat',fmOpenRead {or fmShareDenyNone});
 try
  CompressedSize:=InputFileStream.Size;
  GetMem(CompressedData,CompressedSize);
  InputFileStream.ReadBuffer(CompressedData^,CompressedSize);
 finally
  FreeAndNil(InputFileStream);
 end;

 if LZBRSFDecompress(CompressedData,CompressedSize,UncompressedData,UncompressedSize) then begin
 
  OutputFileStream:=TFileStream.Create('output2.dat',fmCreate);
  try
   OutputFileStream.WriteBuffer(UncompressedData^,UncompressedSize);
  finally
   FreeAndNil(OutputFileStream);
  end;

  FreeMem(UncompressedData);
  UncompressedData:=nil;
  
 end; 

 FreeMem(CompressedData);
 CompressedData:=nil;

 WriteLn('done!');

end;

procedure TestCompare;
var OriginalFileStream:TFileStream;
    UncompressedFileStream:TFileStream;
    OriginalSize:TpvUInt64;
    UncompressedSize:TpvUInt64;
    Index:TpvUInt64;
    OK:boolean;
    OriginalData:Pointer;
    UncompressedData:Pointer;
begin

 Write('Comparing... ');

 OriginalFileStream:=TFileStream.Create('input.dat',fmOpenRead {or fmShareDenyNone});
 try
  OriginalSize:=OriginalFileStream.Size;
  GetMem(OriginalData,OriginalFileStream.Size);
  OriginalFileStream.ReadBuffer(OriginalData^,OriginalFileStream.Size);
 finally
  FreeAndNil(OriginalFileStream);
 end;

 UncompressedFileStream:=TFileStream.Create('output2.dat',fmOpenRead {or fmShareDenyNone});
 try
  UncompressedSize:=UncompressedFileStream.Size;
  GetMem(UncompressedData,UncompressedFileStream.Size);
  UncompressedFileStream.ReadBuffer(UncompressedData^,UncompressedFileStream.Size);
 finally
  FreeAndNil(UncompressedFileStream);
 end;

 if OriginalSize=UncompressedSize then begin
  OK:=true;
  for Index:=1 to OriginalSize do begin
   if PByte(UncompressedData)[Index-1]<>PByte(OriginalData)[Index-1] then begin
     WriteLn('Failed because of different data at byte position ',Index-1,'!');
    OK:=false;
    break;
   end;
  end;
  if OK then begin
   WriteLn('OK!');
  end;
 end else begin
  WriteLn('Failed because of different sizes!');
 end;

 FreeMem(UncompressedData);
 UncompressedData:=nil;

 FreeMem(OriginalData);
 OriginalData:=nil;
  
end;

begin
 
 try

  TestLZBRSFCompress;
  TestLZBRSFDecompress;
  TestCompare;

 except
  on e:Exception do begin
   WriteLn('Exception: ',e.Message);
  end;
 end;

{WriteLn('Press enter to continue...');
 ReadLn;//}

end.
