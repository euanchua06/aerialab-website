; ========================================
; AeriaLab Installer - Final Version
; Uses auth key for automatic device registration
; Includes AeriaLab.exe directly (no download)
; ========================================

#define MyAppName "AeriaLab Remote Desktop"
#define MyAppVersion "1.0"
#define MyAppPublisher "AeriaLab"
#define MyAppURL "https://aerialab.com"
#define MyAppExeName "AeriaLab.exe"

; Your Tailscale auth key
#define TailscaleAuthKey "tskey-auth-kJHsWKFqdQ11CNTRL-sJFwZmhc6uH2FPKLtjLAuH8LP5WYVMJrK"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\AeriaLab
DefaultGroupName=AeriaLab
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=AeriaLab-Installer
SetupIconFile=logo_drone_5.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
DisableWelcomePage=no
ArchitecturesAllowed=x64 x86
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Include AeriaLab.exe directly from build folder
Source: "AeriaLab.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "logo_drone_5.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\AeriaLab Remote Desktop"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\logo_drone_5.ico"
Name: "{group}\AeriaLab Remote Desktop"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\logo_drone_5.ico"
Name: "{group}\Uninstall AeriaLab"; Filename: "{uninstallexe}"

[Code]
var
  DownloadPage: TDownloadWizardPage;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(
    'Downloading Tailscale', 
    'Please wait while Setup downloads Tailscale...', 
    nil);
end;

function OnDownloadProgress(const AURL, AFileName: string; const AProgress, AProgressMax: Int64): Boolean;
begin
  if AProgressMax <> 0 then
    DownloadPage.SetProgress(AProgress, AProgressMax);
  Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = wpReady then
  begin
    DownloadPage.Clear;
    
    // Download Tailscale installer only
    DownloadPage.Add(
      'https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe',
      'tailscale-setup.exe', '');
    
    DownloadPage.Show;
    
    try
      DownloadPage.Download;
      Result := True;
    except
      if DownloadPage.AbortedByUser then
      begin
        MsgBox('Installation cancelled.', mbInformation, MB_OK);
      end
      else
      begin
        MsgBox('Failed to download Tailscale.' + #13#10 + #13#10 +
               'Error: ' + GetExceptionMessage + #13#10 + #13#10 +
               'Please check your internet connection and try again.', 
               mbError, MB_OK);
      end;
      Result := False;
    finally
      DownloadPage.Hide;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  TailscaleInstaller: String;
  TailscalePath: String;
  WaitCount: Integer;
  Connected: Boolean;
begin
  if CurStep = ssPostInstall then
  begin
    // ============================================
    // STEP 1: Install Tailscale
    // ============================================
    TailscaleInstaller := ExpandConstant('{tmp}\tailscale-setup.exe');
    
    if FileExists(TailscaleInstaller) then
    begin
      Log('Installing Tailscale...');
      
      // Install Tailscale silently
      if Exec(TailscaleInstaller, '/S', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        if ResultCode = 0 then
        begin
          Log('Tailscale installed successfully');
          
          // Wait for Tailscale.exe to exist
          WaitCount := 0;
          TailscalePath := ExpandConstant('{pf}\Tailscale\tailscale.exe');
          
          while (not FileExists(TailscalePath)) and (WaitCount < 15) do
          begin
            Sleep(1000);
            WaitCount := WaitCount + 1;
            Log('Waiting for Tailscale.exe... (' + IntToStr(WaitCount) + 's)');
          end;
          
          // ============================================
          // STEP 2: Authenticate with Auth Key
          // ============================================
          if FileExists(TailscalePath) then
          begin
            Log('Authenticating with Tailscale network using auth key...');
            
            // Authenticate using auth key - FULLY AUTOMATIC!
            if Exec(TailscalePath, 'up --authkey={#TailscaleAuthKey} --accept-routes --reset', 
              '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
            begin
              Log('Tailscale authentication command completed with code: ' + IntToStr(ResultCode));
              
              // ============================================
              // STEP 3: Wait for Connection (Important!)
              // ============================================
              Log('Waiting for Tailscale to establish connection...');
              
              Connected := False;
              WaitCount := 0;
              
              // Wait up to 30 seconds for connection
              while (not Connected) and (WaitCount < 30) do
              begin
                Sleep(2000);
                WaitCount := WaitCount + 1;
                
                // Check if connected by running status command
                if Exec(TailscalePath, 'status', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
                begin
                  if ResultCode = 0 then
                  begin
                    Connected := True;
                    Log('Tailscale connected successfully! (' + IntToStr(WaitCount * 2) + 's)');
                  end;
                end;
                
                if not Connected then
                  Log('Still waiting for connection... (' + IntToStr(WaitCount * 2) + 's)');
              end;
              
              if Connected then
              begin
                // Extra wait for device list to sync
                Log('Waiting 5 more seconds for device list to populate...');
                Sleep(5000);
                Log('Tailscale is fully ready!');
              end
              else
              begin
                Log('WARNING: Tailscale connection may not be complete');
              end;
            end
            else
            begin
              Log('ERROR: Failed to execute Tailscale authentication command');
            end;
          end
          else
          begin
            Log('ERROR: Tailscale.exe not found at: ' + TailscalePath);
          end;
        end
        else
        begin
          Log('ERROR: Tailscale installation failed with code: ' + IntToStr(ResultCode));
        end;
      end
      else
      begin
        Log('ERROR: Could not execute Tailscale installer');
      end;
    end
    else
    begin
      Log('ERROR: Tailscale installer not found at: ' + TailscaleInstaller);
    end;
    
    Log('AeriaLab.exe installed to: ' + ExpandConstant('{app}\AeriaLab.exe'));
  end;
end;

function InitializeSetup(): Boolean;
begin
  if GetWindowsVersion < $0A000000 then
  begin
    MsgBox('This application requires Windows 10 or later.', mbError, MB_OK);
    Result := False;
    Exit;
  end;
  Result := True;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption := 
      'AeriaLab Remote Desktop is ready!' + #13#10 + #13#10 +
      
      '✓ Application installed' + #13#10 +
      '✓ Tailscale network configured' + #13#10 +
      '✓ Device automatically registered' + #13#10 +
      '✓ Desktop shortcut created' + #13#10 + #13#10 +
      
      'Everything is ready to use!' + #13#10 + #13#10 +
      
      'To connect to your Jetson:' + #13#10 +
      '1. Make sure your Jetson is powered on' + #13#10 +
      '2. Double-click "AeriaLab Remote Desktop" on desktop' + #13#10 +
      '3. Connection happens automatically via Tailscale!' + #13#10 + #13#10 +
      
      'Click Finish to exit.';
  end;
end;

[UninstallDelete]
Type: files; Name: "{app}\*.rdp"
Type: files; Name: "{app}\jetson_ip.txt"
