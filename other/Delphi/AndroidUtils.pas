// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit AndroidUtils;

interface

uses
  System.Permissions,
  Androidapi.JNI.Telephony, Androidapi.Helpers, Androidapi.JNI.OS,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net, Androidapi.JNI.App, Androidapi.JNI.Support,
  FMX.Helpers.Android;

type
  TPermissions = (pCamera, pStorage, pPhoneState, pBiometry, pLocation, pCall);

  TAndroidPermission = class
  public
    class procedure Request(APermission: TPermissions);
    class function isGranted(APermission: TPermissions): boolean;
  end;

  TAndroidIntent = class
  public
    class procedure Open(AFilename, AMIMEType: string);
  end;

  TAndroidVersion = class
  public
    class function GetCurrentSDK: integer;
    class function GetAPILevel: integer;
    class function GetOSInfo: string;
  end;

implementation

uses
  System.SysUtils;

{ TAndroidPermission }

class function TAndroidPermission.isGranted(APermission: TPermissions): boolean;
begin
  Result := False;
  case APermission of
    pCamera:
      begin
        Result := PermissionsService.IsEveryPermissionGranted
          ([JStringtoString(TJmanifest_permission.JavaClass.CAMERA)]);
      end;
    pStorage:
      begin
        if not TOSVersion.Check(10) then
          Result := PermissionsService.IsEveryPermissionGranted
            ([JStringtoString(TJmanifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.READ_EXTERNAL_STORAGE)])
        else
          Result := PermissionsService.IsEveryPermissionGranted
            ([JStringtoString(TJmanifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.READ_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.MANAGE_DOCUMENTS),
            JStringtoString(TJmanifest_permission.JavaClass.MANAGE_MEDIA)]);
      end;
    pPhoneState:
      begin
        Result := PermissionsService.IsEveryPermissionGranted
          ([JStringtoString(TJmanifest_permission.JavaClass.READ_PHONE_STATE)]);
      end;
    pBiometry:
      begin
        if TAndroidVersion.GetCurrentSDK >= 28 then
          Result := PermissionsService.IsEveryPermissionGranted
            ([JStringtoString(TJmanifest_permission.JavaClass.USE_BIOMETRIC)])
        else if TAndroidVersion.GetCurrentSDK >= 23 then
          Result := PermissionsService.IsEveryPermissionGranted
            ([JStringtoString(TJmanifest_permission.JavaClass.USE_FINGERPRINT)]);
      end;
    pLocation:
      begin
        Result := PermissionsService.IsEveryPermissionGranted
          ([JStringtoString(TJmanifest_permission.JavaClass.ACCESS_COARSE_LOCATION)]);
      end;
    pCall:
      begin
        Result := PermissionsService.IsEveryPermissionGranted
          ([JStringtoString(TJmanifest_permission.JavaClass.CALL_PHONE)]);
      end;
  else
    Result := False;
  end;
end;

class procedure TAndroidPermission.Request(APermission: TPermissions);
begin
  case APermission of
    pCamera:
      begin
        PermissionsService.RequestPermissions
          ([JStringtoString(TJmanifest_permission.JavaClass.CAMERA),
          JStringtoString(TJmanifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE),
          JStringtoString(TJmanifest_permission.JavaClass.READ_EXTERNAL_STORAGE)],
          nil, nil);
      end;
    pStorage:
      begin
        if not TOSVersion.Check(10) then
          PermissionsService.RequestPermissions
            ([JStringtoString(TJmanifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.READ_EXTERNAL_STORAGE)
            ], nil, nil)
        else
          PermissionsService.RequestPermissions
            ([JStringtoString(TJmanifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.READ_EXTERNAL_STORAGE),
            JStringtoString(TJmanifest_permission.JavaClass.MANAGE_DOCUMENTS),
            JStringtoString(TJmanifest_permission.JavaClass.MANAGE_MEDIA)], nil, nil);
      end;
    pPhoneState:
      begin
        PermissionsService.RequestPermissions
          ([JStringtoString(TJmanifest_permission.JavaClass.READ_PHONE_STATE)], nil, nil);
      end;
    pBiometry:
      begin
        if TAndroidVersion.GetCurrentSDK >= 28 then
          PermissionsService.RequestPermissions
            ([JStringtoString(TJmanifest_permission.JavaClass.USE_BIOMETRIC)], nil, nil)
        else if TAndroidVersion.GetCurrentSDK >= 23 then
          PermissionsService.RequestPermissions
            ([JStringtoString(TJmanifest_permission.JavaClass.USE_FINGERPRINT)], nil, nil)
      end;
    pLocation:
      begin
        PermissionsService.RequestPermissions
          ([JStringtoString(TJmanifest_permission.JavaClass.ACCESS_COARSE_LOCATION)],
          nil, nil);
      end;
    pCall:
      begin
        PermissionsService.RequestPermissions
          ([JStringtoString(TJmanifest_permission.JavaClass.CALL_PHONE)], nil, nil);
      end;
  end;
end;

{ TAndroidIntent }

class procedure TAndroidIntent.Open(AFilename, AMIMEType: string);
var
  LIntent: JIntent;
  LFile: JFile;
begin
  LFile := TJFile.JavaClass.init(StringToJString(AFilename));
  LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
  LIntent.setDataAndType(TAndroidHelper.JFileToJURI(LFile), StringToJString(AMIMEType));
  LIntent.setFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(LIntent);
end;

{ TAndroidVersion }

class function TAndroidVersion.GetAPILevel: integer;
begin
  Result := TOSVersion.Major;
end;

class function TAndroidVersion.GetOSInfo: string;
begin
  Result := '';
  Result := Result + 'Major: ' + TOSVersion.Major.ToString + sLineBreak;
  Result := Result + 'Minor: ' + TOSVersion.Minor.ToString + sLineBreak;
  Result := Result + 'Build: ' + TOSVersion.Build.ToString + sLineBreak;
  Result := Result + 'Name: ' + TOSVersion.Name + sLineBreak;
  Result := Result + 'ServicePackMajor: ' + TOSVersion.ServicePackMajor.ToString +
    sLineBreak;
  Result := Result + 'ServicePackMinor: ' + TOSVersion.ServicePackMinor.ToString +
    sLineBreak;
end;

class function TAndroidVersion.GetCurrentSDK: integer;
begin
  Result := TJBuild_VERSION.JavaClass.SDK_INT;
end;

end.
