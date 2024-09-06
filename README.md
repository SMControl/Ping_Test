# Ping_Test
Runs ping to a host and keeps a log stored of it

Run and type in host name to ping
It will set job to ping that host every second and log it to a file in C:\winsm\pingtest
It will separate results out by days and delete log files oder than 30 days.

To stop, run script again and tell it to stop or reboot machine.

```
irm https://raw.githubusercontent.com/SMControl/Ping_Test/main/Ping_Test.ps1 | iex
````
