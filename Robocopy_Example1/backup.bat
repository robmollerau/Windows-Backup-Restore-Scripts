::BACKUP

:: Check Windows Management Intrumentation WMIC Available
wmic.exe alias /? >NUL 2>&1 || goto WMICMissing

:: Use WMIC to retrieve date and time
for /f "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
   IF "%%~L"=="" goto WMICComplete
      set _yyyy=%%L
      set _mm=00%%J
      set _dd=00%%G
      set _hh=00%%H
      set _nn=00%%I
      set _ss=00%%K
)
:WMICComplete

:: Get day of week using WMIC - this provides day offset, need to convert to day prefix, Ie. Mon, Tue, etc
for /f "skip=2 tokens=2 delims=," %%a in ('wmic path win32_localtime get dayofweek/format:csv') do set /a dow_number=%%a+1

:: Convert numeric day or week to character prefix
set _dow=Unk
if %dow_number%==1 set _dow=Sun
if %dow_number%==2 set _dow=Mon
if %dow_number%==3 set _dow=Tue
if %dow_number%==4 set _dow=Wed
if %dow_number%==5 set _dow=Thu
if %dow_number%==6 set _dow=Fri
if %dow_number%==7 set _dow=Sat

:: Pad digits with leading zeros
set _mm=%_mm:~-2%
set _dd=%_dd:~-2%
set _hh=%_hh:~-2%
set _nn=%_nn:~-2%
set _ss=%_ss:~-2%

:: Backup paths
set _timestamp_folder=%_yyyy%%_mm%%_dd%_%_dow%_%_hh%%_nn%%_ss%
set _backup_path=C:\BACKUP

:: Source paths
set _source_path=C:\DEV
set _source_users=johnc richardw

echo %date% %time% %~1 - Backup started >> c:\script\backup.log

::If No Parameter Supplied Warn User
if "%~1"=="" goto NoParamSupplied

echo %date% %time% %~1 - Attempt to access backup folder >> c:\script\backup.log

::Check if backup path exists
if not exist %_backup_path% goto NoBackupPath

if "%~1"=="MONTHLY" goto MonthlyBackup
if "%~1"=="WEEKLY" goto WeeklyBackup
if "%~1"=="DAILY" goto DailyBackup

::If No Parameter Supplied Warn User
goto NoParamSupplied

:: -----------------------------------------------------------------------------
:DailyBackup

::Log Backup Start
echo %date% %time% %~1 - Performing daily backup >> c:\script\backup.log

@ echo Performing Daily Backup

set _backup_type=DAY_DIFF

::Create Backup Folder Structure
echo %date% %time% %~1 - Backing up folder structure >> c:\script\backup.log
for %%A in ( %_source_users% ) do mkdir "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%"

::Backup Folders - Differential
echo %date% %time% %~1 - Copying data backup path using differential match >> c:\script\backup.log
for %%A in ( %_source_users% ) do robocopy "%_source_path%\%%A" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%" /s /zb /a /v /log:"%_backup_path%\%%A\%_backup_type%\Backup_%_timestamp_folder%.Log"

::ZIP Files to Save Space
echo %date% %time% %~1 - Zipping backup files >> c:\script\backup.log
for %%A in ( %_source_users% ) do "C:\Script\7z.exe" a -r "%_backup_path%\%%A\%_backup_type%\Zip_%_timestamp_folder%.7z" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%\*.*" 

::Delete Files Older than 15 Days
echo %date% %time% %~1 - Deleting files older than 31 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -15 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==FALSE del @path"

::Delete Folders Older than 15 Days
echo %date% %time% %~1 - Deleting directories older than 15 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -15 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==TRUE rmdir @path /s /q"

echo %date% %time% %~1 - Daily backup complete >> c:\script\backup.log

goto End

:: -----------------------------------------------------------------------------
:WeeklyBackup

@ echo Performing Weekly Backup

set _backup_type=WEK_FULL

::Create Backup Folder Structure
echo %date% %time% %~1 - Backing up folder structure >> c:\script\backup.log
for %%A in ( %_source_users% ) do mkdir "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%"

::Backup Folders - Full
echo %date% %time% %~1 - Copying data to NAS using differential match >> c:\script\backup.log
for %%A in ( %_source_users% ) do robocopy "%_source_path%\%%A" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%" /e /b /v /log:"%_backup_path%\%%A\%_backup_type%\Backup_%_timestamp_folder%.Log"

::ZIP Files to Save Space
echo %date% %time% %~1 - Zipping backup files >> c:\script\backup.log
for %%A in ( %_source_users% ) do "C:\Script\7z.exe" a -r "%_backup_path%\%%A\%_backup_type%\Zip_%_timestamp_folder%.7z" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%\*.*" 

::Remove Archive attribute (only do this for Weekly backups)
echo %date% %time% %~1 - Removing archive flag from files >> c:\script\backup.log
for %%A in ( %_source_users% ) do attrib %_source_path%\%%A\*.* -a /s

::Remove Files and Folders greater than 31 days
::forfiles /S /P "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%" /C "cmd /c if @isdir==TRUE rmdir @path /s"
::forfiles /S /D -31 /P "%_backup_path%\%_backup_type%" /C "cmd /c if @isdir==TRUE dir @path /s"

::Delete Files Older than 31 Days
echo %date% %time% %~1 - Deleting files older than 31 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -31 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==FALSE del @path"

::Delete Folders Older than 31 Days
echo %date% %time% %~1 - Deleting directories older than 31 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -31 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==TRUE rmdir @path /s /q"

echo %date% %time% %~1 - Weekly backup complete >> c:\script\backup.log

goto End

:: -----------------------------------------------------------------------------
:MonthlyBackup

@ echo Performing Monthly Backup

set _backup_type=MTH_FULL

::Create Backup Folder Structure
echo %date% %time% %~1 - Backing up folder structure >> c:\script\backup.log
for %%A in ( %_sourcce_users% ) do mkdir "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%"

::Backup Folders - Full
echo %date% %time% %~1 - Copying data to NAS using differential match >> c:\script\backup.log
for %%A in ( %_source_users% ) do robocopy "%_source_path%\%%A" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%" /e /b /v /log:"%_backup_path%\%%A\%_backup_type%\Backup_%_timestamp_folder%.Log"

::ZIP Files to Save Space
echo %date% %time% %~1 - Zipping backup files >> c:\script\backup.log
for %%A in ( %_source_users% ) do "C:\Script\7z.exe" a -r "%_backup_path%\%%A\%_backup_type%\Zip_%_timestamp_folder%.7z" "%_backup_path%\%%A\%_backup_type%\%_timestamp_folder%\*.*"

::Delete Files Older than 130 Days ~ 4 months
echo %date% %time% %~1 - Deleting files older than 140 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -140 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==FALSE del @path"

::Delete Folders Older than 130 Days ~ 4 months
echo %date% %time% %~1 - Deleting directories older than 140 days >> c:\script\backup.log
for %%A in ( %_source_users% ) do forfiles /D -140 /P "%_backup_path%\%%A\%_backup_type%" /C "cmd /c if @isdir==TRUE rmdir @path /s /q"

echo %date% %time% %~1 - Monthly backup complete >> c:\script\backup.log

goto End

:: -----------------------------------------------------------------------------
:NoBackupPath

echo %date% %time% %~1 - Backup path not available >> c:\script\backup.log

@ echo Backup path not currently available, backup cancelled.
@ echo .
::@ pause

goto End

:: -----------------------------------------------------------------------------
:NoParamSupplied

::Log Backup Start
echo %date% %time% %~1 - No backup type parameter supplied >> c:\script\backup.log

@ echo Usage: backup.bat ^<DAILY^|WEEKLY^|MONTHLY^> Example: Backup.bat DAILY
@ echo .
::@ pause

goto End

:: -----------------------------------------------------------------------------
:WMICMissing

::Log Backup Start
echo %date% %time% %~1 - Error WMIC.EXE missing >> c:\script\backup.log

@ echo WMIC.EXE missing, backup cancelled.
@ echo .
::@ pause

goto End


:End


