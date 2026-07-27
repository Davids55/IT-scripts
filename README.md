IT-scripts
  -

Serra College IT 100 -summer semester 2026


PowerShell
  -
- System_health_Check
  - Disk space on all drives — warn if below 20%
  - CPU usage — warn if average above 80% for 30 seconds
  - Memory — warn if less than 500MB free
  -Top 5 processes by CPU
  - Output: formatted report to C:\Temp\healthcheck_[date].txt

- User_Account_Report
  - List all local users with: name, enabled status, last logon, whether in Administrators group
  - Flag any accounts never logged in that are enabled
  - Output: save to a .csv file

- Event_Log_Parser


Bash
  -
- User_Audit
    - List all users with login shells (not /sbin/nologin)
    - Check which have sudo rights
    - Flag any user with UID 0 other than root

- Ollama_Stats_Check
  - Is the Ollama service running? (systemctl is-active ollama)
  - Is Ollama bound to 127.0.0.1 not 0.0.0.0? (ss -tuln | grep 11434)
  - Is the Ollama API responding? 
  - How many models are installed? 
  - Is model disk usage below 80% of the partition?
  - Any ERROR entries in Ollama journal in the last hour?
  - Output a final summary: HEALTHY / WARNING / CRITICAL
 
