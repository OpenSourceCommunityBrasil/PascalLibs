// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.1
unit AndroidUtils;

interface

uses
  System.Permissions, System.IOUtils,
  FMX.Helpers.Android,
  Androidapi.Helpers, Androidapi.JNIBridge, Androidapi.JNI.Telephony, Androidapi.JNI.OS,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net,
  Androidapi.JNI.App, Androidapi.JNI.Support,
  Androidapi.JNI.Provider;

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
    class procedure OpenPDF(AFilename: string);
    class procedure ShareFile(AFileName, AFilePath, AMIMEType: string);
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
  // SharedActivity.startActivity(LIntent);
  TAndroidHelper.Activity.startActivity(LIntent);
end;

class procedure TAndroidIntent.OpenPDF(AFilename: string);
var
  Afile: JFile;
  AUri: Jnet_Uri;
  intent: JIntent;
  package: JStringBuilder;
begin
  // pega o nome do .apk com o .fileprovider
  package := TJStringBuilder.Create;
  package.append(TAndroidHelper.Context.getPackageName)
    .append(StringToJString('.fileprovider'));

  Afile := TJFile.JavaClass.init(StringToJString(AFilename));
  AUri := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context,
    package.toString, Afile);
  intent := TJIntent.Create;
  intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  intent.setDataAndType(AUri, StringToJString('application/pdf'));
  intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  try
    TAndroidHelper.Activity.startActivity(intent);
  except
    Raise;
  end;
end;

class procedure TAndroidIntent.ShareFile(AFilename, AFilePath, AMIMEType: string);
var
  Afile: JFile;
  AUri: Jnet_Uri;
  intent: JIntent;
  package: JStringBuilder;
begin
  // pega o nome do .apk com o .fileprovider
  package := TJStringBuilder.Create;
  package.append(TAndroidHelper.Context.getPackageName)
    .append(StringToJString('.fileprovider'));

  Afile := TJFile.JavaClass.init(StringToJString(AFilePath));
  AUri := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context,
    package.toString, Afile);

  intent := TJIntent.Create;
  intent.setAction(TJIntent.JavaClass.ACTION_SEND);
  intent.setDataAndType(AUri, StringToJString(AMIMEType));
  intent.setType(StringToJString('application/pdf'));
  intent.putExtra(TJIntent.JavaClass.EXTRA_STREAM,
    TJParcelable.Wrap((AUri as ILocalObject).GetObjectID));
  intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(TJIntent.JavaClass.createChooser(intent,
    StrToJCharSequence('Share ' + AFilename + ':')));
end;

{ TAndroidVersion }

class function TAndroidVersion.GetAPILevel: integer;
begin
  Result := TOSVersion.Major;
end;

class function TAndroidVersion.GetOSInfo: string;
begin
  Result := '';
  Result := Result + 'Major: ' + TOSVersion.Major.toString + sLineBreak;
  Result := Result + 'Minor: ' + TOSVersion.Minor.toString + sLineBreak;
  Result := Result + 'Build: ' + TOSVersion.Build.toString + sLineBreak;
  Result := Result + 'Name: ' + TOSVersion.Name + sLineBreak;
  Result := Result + 'ServicePackMajor: ' + TOSVersion.ServicePackMajor.toString +
    sLineBreak;
  Result := Result + 'ServicePackMinor: ' + TOSVersion.ServicePackMinor.toString +
    sLineBreak;
end;

class function TAndroidVersion.GetCurrentSDK: integer;
begin
  Result := TJBuild_VERSION.JavaClass.SDK_INT;
end;

end.
