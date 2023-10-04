unit HWMonitorUtils;

{$mode ObjFPC}{$H+}

interface

uses
  {$IFDEF WINDOWS}
    Windows, JwaWinBase, JwaPsApi,
  {$ENDIF}
  {$IFDEF LINUX}
    Unix, BaseUnix, process,
  {$ENDIF}
  Classes, SysUtils, LazUTF8;

type

  TRAMData = record
    TotalRAM: int64;
    FreeRAM: int64;
    UsedRAM: int64;
    FreeRAMPerc: double;
    UsedRamPerc: double;
    AppUsedRAM: int64;
    AppUsedRAMPerc: double;
  end;

  { THWMonitor }

  THWMonitor = class
  private
    LastSysKernelTime, LastSysUserTime, LastProcKernelTime, LastProcUserTime: int64;
  public
    constructor Create;
    function GetCPULoad: string;
    function GetRAMData: TRAMData;
  end;

implementation

{ THWMonitor }

constructor THWMonitor.Create;
begin
  LastSysKernelTime := 0;
  LastSysUserTime := 0;
  LastProcKernelTime := 0;
  LastProcUserTime := 0;
end;

{$IFDEF WINDOWS}
function THWMonitor.GetCPULoad: string;
var
  hProcess: THandle;

  NotUsed, SysKernelTime, ProcKernelTime, SysUserTime, ProcUserTime: FILETIME;
  DiffSysKernel, DiffSysUser, DiffProcKernel, DiffProcUser, TotalSysTime,
  TotalProcTime: int64;
  calc: double;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, GetCurrentProcessId);
  try
    GetSystemTimes(@NotUsed, @SysKernelTime, @SysUserTime);

    DiffSysKernel := int64(SysKernelTime) - LastSysKernelTime;
    DiffSysUser := int64(SysUserTime) - LastSysUserTime;
    TotalSysTime := DiffSysKernel + DiffSysUser;

    GetProcessTimes(hProcess, NotUsed, NotUsed, ProcKernelTime, ProcUserTime);

    DiffProcKernel := int64(ProcKernelTime) - LastProcKernelTime;
    DiffProcUser := int64(ProcUserTime) - LastProcUserTime;
    TotalProcTime := DiffProcKernel + DiffProcUser;

    calc := TotalProcTime / TotalSysTime * 100;

    LastSysKernelTime := int64(SysKernelTime);
    LastSysUserTime := int64(SysUserTime);
    LastProcKernelTime := int64(ProcKernelTime);
    LastProcUserTime := int64(ProcUserTime);

    Result := FloatToStrF(calc, ffFixed, 16, 2) + ' %';
  finally
    CloseHandle(hProcess);
  end;
end;

function THWMonitor.GetRAMData: TRAMData;
var
  MemoryStatusEx: TMemoryStatusEx;
  usedmem: int64;
  memcount: TProcessMemoryCounters;
begin
  // get system ram info
  MemoryStatusEx.dwLength := SizeOf(MemoryStatusEx);
  GlobalMemoryStatusEx(MemoryStatusEx);

  // get process ram info
  memcount.cb := SizeOf(memcount);
  GetProcessMemoryInfo(GetCurrentProcess, memcount, SizeOf(memcount));

  // output results
  Result.FreeRAM := MemoryStatusEx.ullAvailPhys;
  Result.TotalRAM := MemoryStatusEx.ullTotalPhys;
  Result.FreeRAMPerc := Result.FreeRAM / result.TotalRAM;
  Result.UsedRAM := MemoryStatusEx.ullTotalPhys - MemoryStatusEx.ullAvailPhys;
  Result.UsedRamPerc := Result.UsedRAM / Result.TotalRAM;
  Result.AppUsedRAM := memcount.WorkingSetSize;
  Result.AppUsedRAMPerc := Result.AppUsedRAM / Result.UsedRAM;
end;
{$ENDIF}
{$IFDEF LINUX}
function THWMonitor.GetCPULoad: string;
var
  OutputList: TStringList;
begin
  with TProcess.Create(nil) do
  try
    CommandLine := 'ps -p ' + GetProcessID.ToString + ' -o %cpu';
    Options := Options + [poWaitOnExit, poUsePipes];
    Execute;
    OutputList := TStringList.Create;
    OutputList.LoadFromStream(Output);
    Result := trim(OutputList[1]);
  finally
    Free;
    OutputList.Free;
  end;
end;

function THWMonitor.GetRAMData: TRAMData;
var
  statfile: TextFile;
  currline, info: string;
begin
  // get system total memory info
  AssignFile(statfile, '/proc/meminfo');
  Reset(statfile);
  while not EOF(statfile) do
  begin
    ReadLn(statfile, currline);
    if Pos('MemTotal:', currline) > 0 then
    begin
      info := trim(Copy(currline, pos(':', currline) + 1, Length(currline)));
      Result.TotalRAM := StrToInt64(Copy(info, 0, length(info) - 3));
    end
    else if Pos('MemAvailable:', currline) > 0 then
    begin
      info := trim(Copy(currline, pos(':', currline) + 1, Length(currline)));
      Result.FreeRAM := StrToInt64(Copy(info, 0, length(info) - 3));
    end;
  end;
  CloseFile(statfile);

  // get application memory info
  AssignFile(statfile, '/proc/self/status');
  Reset(statfile);
  while not EOF(statfile) do
  begin
    ReadLn(statfile, currline);
    if Pos('RssAnon:', currline) > 0 then
    begin
      info := trim(Copy(currline, pos(':', currline) + 1, Length(currline)));
      Result.AppUsedRAM := StrToInt64(Copy(info, 0, length(info) - 3));
      break;
    end;
  end;
  CloseFile(statfile);

  // calculating the remaining stats
  Result.UsedRAM := Result.TotalRAM - result.FreeRAM;
  Result.AppUsedRAMPerc := Result.AppUsedRAM / Result.TotalRAM;
  Result.UsedRamPerc := Result.UsedRAM / Result.TotalRAM;
end;
{$ENDIF}

end.
