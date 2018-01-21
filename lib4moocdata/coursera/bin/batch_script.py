import os
import sys
import json
import sqlite3
import shlex, subprocess
reload(sys)
sys.setdefaultencoding('utf-8')

#set debug to 1 if you want debug messages throughout the code, else 0.
debug = 1

def __init__(self):

def populate_sqlite_db(self, dbname_in, dbname_out, course_id):
    # subprocess.call(["perl", "populate_sqlite_db.pl", "-indb <mysql dbname> -outdb <sqlite dbname> -course <course_id> -version <version # for your coursera sql export>", "test.hex"])
    command_line = "perl populate_sqlite_db.pl -indb <mysql dbname> -outdb <sqlite dbname> -course <course_id> -version 2"
    args = shlex.split(command_line)
    print(args)
    p = subprocess.Popen(args)
