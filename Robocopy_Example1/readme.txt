Backup Notes
------------

Place Backup.bat file in C:\Script folder.

Backups are created using robocopy then compressed using 7-Zip
command line tool (7z.exe).

To obtain a copy of this exe go to: https://www.7-zip.org/download.html

Backup is performed using Windows Task Scheduler.
The backup script file is called with either one of these parameters

DAY_DIFF - Daily differential backup - Backups are accumulated until the archive
           flag is set by the weekly backup.
                                
WEK_FULL - Full weekly backup - Archive bit is set.                                

MTH_FULL - Full monthly backup - Archive bit is not set.

-------------------------------------------------------------------------------

Variables
=========

backup_stamp  - Name of backup bolder - currently set as
                Backup_YYYYMMDD_DOW_HHMMSS
                Example: Backup_20200101_Mon_010000
                This means backup was performon on Mon, 1 Jan 2020 at 1.00am
          
backup_path   - Backup location - currently set as
                C:\BACKUP
                Depending on backup type the full path could be:
                C:\BACKUP\<USERNAME>\DAY_DIFF\Backup_20200101_Mon_010000
                C:\BACKUP\<USERNAME>\WEK_FULL\Backup_20200101_Mon_010000
                C:\BACKUP\<USERNAME>\MTH_FULL\Backup_20200101_Mon_010000                

source_path   - Subfolder of where to get backups - currently set to
                C:\DEV
                
source_users  - These are subfolders of the source path, and is assuming
                all users place folders under source path.
                This is list of user folders names which need to backup,
                Example: johnc richardw
                The full source path for backups would become
                C:\DEV\johnc
                C:\DEV\richardw
                
-------------------------------------------------------------------------------

Backups are performed using Windows Task Scheduler

Create backups in task scheduler.

Set Program Script to C:\Script\Backup.bat

Add optional argument:   DAILY    or
                         WEEKLY   or
                         MONTHLY
                         
Backup paths have format <BACKUP_TYPE>\<BACKUP_DATE>

Backup type can be either DAY_DIFF (Daily Differential)
                          WEK_FULL (Weekly Full)
                          MTH_FULL (Monthly Full)
                          
After the weekly backup is performed the archive (A) attribute is removed
so that the daily backup only picks up changes made since the last
weekly backup.

The monthly backup does NOT remove the archive (A) attribute.

Recommended backup schedules are...

DAILY

Every day at 1am


WEEKLY

Every Saturday at 4am


MONTHLY

Every 1st day of the month at 6am


