import os
import sys
import json
import sqlite3
import shlex, subprocess

#set debug to 1 if you want debug messages throughout the code, else 0.
debug = 1

def populate_sqlite_db():
    """Transfer json files into sqlite database.
    And add new tables(forum, post2, post3, comment2, comment3).
    Modify the database into canonical format.
    """

    subprocess.run("cd WriteJsonDataToSQLite", shell=True)
    subprocess.run("python writeToSQLite.py", shell=True)
    subprocess.run("python fromOriginalToCanonical.py", shell=True)
    subprocess.run("python transferFromTables.py", shell=True)

def populate_intervened_posts():
    """Extract the posts and comments that have been intervened by the instructor for at least once.
    This should populate records in tables post2 and comment2 with posts from threads intervened at least once by an instructor or TA.
    """

    subprocess.run("perl make_noinstructor_corpus.pl -dbname coursera -course eQJvsjn9EeWJaxK5AT4frw -density", shell=True)

def update_docid():
    """creates document ids, one per each thread.
    This is useful when threads from all the courses are in the same database.
    This is a required field for feature extraction.
    """

    subprocess.run("perl updatedocid.pl -dbname coursera -course eQJvsjn9EeWJaxK5AT4frw", shell=True)

def compute_term_weights():
    """Compute the term weights and insert into the database.
    Run this method twice in the pipeline to collect TFs and populate it in termfreqc14inst and termfreqc14noinst.
    """

    subprocess.run("perl compute_term_weights.pl -dbname coursera -course eQJvsjn9EeWJaxK5AT4frw  -uni  -tf -thread inst", shell=True)
    subprocess.run("perl compute_term_weights.pl -dbname coursera -course eQJvsjn9EeWJaxK5AT4frw  -uni  -tf -thread noinst", shell=True)

def generate_feature():
    subprocess.run("perl gen_features.pl -course eQJvsjn9EeWJaxK5AT4frw  -dbname coursera  -uni -allf", shell=True)

def classifier_model():
    subprocess.run("perl predict_thread_intervention.pl -course eQJvsjn9EeWJaxK5AT4frw -w nve -in uni+forum+affir+tprop+nums+nont_course+course+_eQJvsjn9EeWJaxK5AT4frw.txt -model uni+forum+affir+tlen+nums+nont_course_.model_0", shell=True)

if __name__ == '__main__':
    courseids = []

    if debug:
        print("batch script starts running...")
    dir_path = os.path.dirname(os.path.realpath(__file__))
    os.chdir(dir_path + "/WriteJsonDataToSQLite")
    # input all course ids
    courseids.append("eQJvsjn9EeWJaxK5AT4frw")
    if debug:
        print(courseids)
    # populate_sqlite_db()
    # var = dir_path + "\\lib4moocdata\\coursera\\bin\\"

    # Copy transfered database to data file
    # subprocess.run("mv ", shell=True)
    os.chdir(dir_path + "/lib4moocdata/coursera/bin")
    # populate_intervened_posts()
    if debug:
        print("batch script completed")
