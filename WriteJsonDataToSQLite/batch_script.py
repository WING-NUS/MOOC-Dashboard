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
    # subprocess.call(["writeToSQLite.py"])

# def populate_truncated():
#     subprocess.run("perl make_noinstructor_corpus.pl -dbname coursera -course bVgqTevEEeWvGQrWsIkLlw~DKxwULr1EeaN_w7XVB3P7A -density", shell=True)
#
# def updatedocid():
#     subprocess.run("perl updatedocid.pl -dbname coursera -course bVgqTevEEeWvGQrWsIkLlw~DKxwULr1EeaN_w7XVB3P7A", shell=True)
#
# def generate_feature():
#     subprocess.run("perl generatestratCVSamplesfromsingleCourses.pl -course bVgqTevEEeWvGQrWsIkLlw~DKxwULr1EeaN_w7XVB3P7A -dbname coursera -folds 5 -uni -allf", shell=True)
#     subprocess.run("perl generatestratCVSamplesfromsingleCourses.pl -course bVgqTevEEeWvGQrWsIkLlw~DKxwULr1EeaN_w7XVB3P7A -dbname coursera -folds 5 -allf", shell=True)
#
# def classifier_model():
#     subprocess.run("perl 	classify_thread.pl -course bVgqTevEEeWvGQrWsIkLlw~DKxwULr1EeaN_w7XVB3P7A \
#                    -folds <num of cross validation folds> -w <method to calculate class imbalance counter-weight> \
#                    -in1 <training_file_for_fold_0> -in2 <test_file_for_fold_0>", shell=True)

if __name__ == '__main__':
    if debug:
        print("batch script starts running...")
        # subprocess.run("ls", shell=True)
        populate_sqlite_db()
        if debug:
            print("batch script completed")
    # main()
