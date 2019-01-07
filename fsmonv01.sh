#!/usr/bin/env bash
#################################################################################
# script: FS_MONvl.O.sh 
# Author: David Newman
# created: 06/25/10
# 
# Purpose:      The program will execute in crontab facility every 20
#               minutes. It will search for filesystem over 95%, 98%
#               and generate alerts which will be sent to the
#               admin on call via cell Phone or Email. Alert will
#               be re-submitted to the Admin when a change in
#               filesystem status has occured. Finally, the program will send a 
#               "ClEAR ALL" message once thresholds have been lowered.
#
# Notes:        1.) Need to automate the update of Admin.conf from central server. 
#               2.) Need to create an interactive ADMIN interface which will give options  
#                   to to perform certain duties i .e, updating and pusing
#                   out ADMIN on call SMS/Email automatically after selection has
#                   been made.
#
#
# Platforms:    Solaris, AIX, HP-UX, Linux
#
#
# Revisions:
#
#               D.N. 6/29/10
#               Made changes to GET_PERC function. was delivering alerts before
#               all data was input into the body of the Mail message. This would
#               cause the admin to receive doulbe the messages. Moved email
#               out of function and into their own if statements. It now delivers
#               single alert in each category.
#
#               D.N. 7/09/10
#               Modified the _ADMIN variable. It will now grab multiple SMS numbers contained 
#               inside the ADMIN.conf file and place theminside this one _ADMIN variable. 
#               Mailx will now be able to diliver to multiple recipients.
#
#               D.N. 7/12/10
#               Made adjustments to _EXCLUDE_LIST variable to
#               include /lvdrdbi,' /drlgi,' /lmgrdb* and "GOOD WORK TEAM"
#               to echo statement>> it into FSMON_CLEAR.log
#
#               D. N. 7 /13/10
#               Made adjustments to _EXCLUDE_LIST variable to
#               include /media, /lmgrlg*
#
#               D.N. 7/14/10
#               Made adjustments to _EXCLUDE_LIST variable to
#               include /var/mqm/log/MQPSEPSll
#
#               D.N. 7/16/10
#               Made adjustments to _EXCLUDE_LIST variable to
#               include /oradata2
#
###############################################################################

# set Default Parameters values
#
_HOSTNAME=`hostname`
_LZ="/root/FSMON_HQ"
_THRESHOLD="$_LZ/THRESHOLD.$_HOSTNAME.MIRROR1"
_THRESHOLD2="$_LZ/THRESHOLD.$_HOSTNAME.MIRROR2"
_ALERT1="98"
_ALERT2="95"
#_ALERT3="85"
#_TIME_STAMP= `date +%b/%d/%y@%T`
> $_ THRESHOLD
> $_LZ/FSMON_ALERT1.log
> $_LZ/FSMON_ALERT2.log
#> $_LZ/FSMON_ALERT3.log
> $_LZ/FSMON_CLEAR.log _MAILX= `which mailx`

# Exclude unwanted Filsystems
_EXCLUDE_LIST="/cdrom|/proc|/opt/ldom*/tsm*|/lvdrdb*|/drlg*|/lmgrdb*\
|/media|/lmgrlg*|/var/mqm/log/MQPSEPSll|/oradata2"

# Get Data And Populate Alert Logs 
GET_PERC() {
cat $_THRESHOLD | while read FIL_SYS PERC
do
   if [ $PER( -ge $_ALERT1 ]; then
      echo "$FIL_SYS @ $PERC%" >> $_LZ/FSMON_ALERT1.log
   elif [ $PERC -lt $_ALERT1 J && [ $PERC -ge $_ALERT2 ]; then
      echo "$FIL_SYS @ $PERC%" >> $_LZ/FSMON_ALERT2.log
   #elif [ $PERC -lt $_ALERT2 ] && [ $PERC -ge $_ALERT3]; then
      #echo "$FIL_SYS @ $PERC%" >> $_LZ/FSMON_ALERT3.log
   fi
done
} 

# set Environment, Get Filsystem output
case `uname -s` in 
sunos)
set -- `df -k | sed -e 's/%//g' | egrep -v "$_EXCLUDE_LIST" | awk '/^\// {
printf("%s %s\n", $5, $6)}'`
;;
AIX)
set -- `df -k I sed -e 's/%//g' | egrep -v "$_EXCLUDE_LIST" | awk '/^\// { 
printf("%s s\n", $4, $7)}'`
;;
HP-UX)
set -- `bdf I sed -e 's/%//g' | egrep -v "LEXCLUDE_LIST" | awk '/^\// { 
printf("%s s\n", $5, $6) }'`
;;
Linux)
set -- `df -hp I sed -e 's/%//g' | egrep -v "$_EXCLUDE_LIST" | awk '/^\// { 
printf("%s %s\n", $5, $6) }'`
;;
esac

# Assign STDOUT PARMS To
while [$# -ge 2] ; do
  CAPACITY=$!
  FS=$2
  shift 2 

  if [ $CAPACITY -ge $_ALERT2] ; then
        echo "$FS $CAPACITY">> "$_THRESHOLD"
  fi
done 

# Additional Parameter setting
GET_LINE_COUNT= `wc -l $_THRESHOLD | awk '{ print $1 }'`

# Alert Subject Line
_ALTMSGl="CRITICAL - FILESYS! SERVER: $_HOSTNAME" 
_ALTMSG2="WARNING - FILESYS! SERVER: $_HOSTNAME"
_ALTMSG3="FILESYS CLEARED! SERVER: $_HOSTNAME"

# Get Admin Cell/Pager# From Admin.conf file
_ADMIN= `cat $_LZ/ADMIN.conf`

if [ $GET_LINE_COUNT -eq O] && [ -f "$_THRESHOLD2" ]; then          # Send Clear All Message
   echo "GOOD WORK TEAM!"> $_LZ/FSMON_CLEAR.log
   cat $_LZ/FSMON_CLEAR.log | $_MAILX -s "$_ALTMSG3" $_ADMIN
   rm -rf "$_THRESHOLD2"
   #echo "lA IF STATEMENT"
   exit 0
elif [ $GET_LINE_COUNT -eq O] && [ ! -f "$_THRESHOLD2" ]; then      # No Qaulifiers - exit 0
   #echo "1B IF STATEMENT"
   exit 0
fi

if [ $GET _LINE_COUNT -gt O ] && [ ! -f "$_ THRESHOLD2" ] ; then    # Send first time alert
   cp -rp "$_THRESHOLD" "$_THRESHOLD2"
   #echo "ALERT MESSAGE - (2nd IF STATEMENT)" GET_PERC 
fi

if [ $GET_LINE_COUNT -gt O J && [ -f "$_THRESHOLD2" ]; then         # Send ALERT On sudden change
   `diff -b -w $_THRESHOLD $_THRESHOLD2` 2>/dev/null
    if [ $? -ne O ]; then
       #echo "ALERT MESSAGE - (3rd IF STATEMENT) SOMETHING HAS CHANGED"
       cp -rp "$_THRESHOLD" "$_THRESHOLD2" GET_PERC 
    fi
fi 


# Additional Parameter settings
GET_ALERTl_COUNT= `wc -l $_LZ/FSMON_ALERT1.log | awk '{ print $1 }'`
GET_ALERT2_COUNT= `wc -l $_LZ/FSMON_ALERT2.log | awk '{ print $1 }'` 

if [ $GET_ALERTl_COUNT -gt O ]; then
   cat $_LZ/FSMON_ALERT1.log | $_MAILX -s "$_ALTMSGl" $_ADMIN      # Send out Alertl Messages 
fi 

if [ $GET_ALERT2_COUNT -gt O ]; then
   cat $_LZ/FSMON_ALERT2.log | $_MAILX -s "$_ALTMSG2" $_ADMIN Alert2    # Send out Alert2 Messages 
fi


#END 

































