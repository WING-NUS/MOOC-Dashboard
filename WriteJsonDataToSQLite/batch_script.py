import os
import sys
import json
import sqlite3
import shlex, subprocess
import subprocess

#set debug to 1 if you want debug messages throughout the code, else 0.
debug = 1

cwd = os.getcwd()

def populate_sqlite_db():
    subprocess.run("python writeToSQLite.py", shell=True)
    subprocess.run("python fromOriginalToCanonical.py", shell=True)
    subprocess.run("python transferFromTables.py", shell=True)
    subprocess.run("py insert_term_weights.py", shell=True)

if __name__ == '__main__':
    if debug:
        print("batch script starts running...")
        # subprocess.run("ls", shell=True)
        populate_sqlite_db()
        if debug:
            print("batch script for transfering data is completed")
    # main()
